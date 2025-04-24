import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'add_expense_screen.dart';
import 'profile.dart';
import '../model/transaction_service.dart';
import '../services/auth_service.dart';
import 'statistic.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TransactionService _transactionService = TransactionService();
  final AuthService _authService = AuthService();
  late List<Transaction> _transactions;
  late String _greeting;
  String _username = "User"; // Default username
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _transactions = _transactionService.transactions;
    _updateGreeting();
    _loadUsername();
    // Listen for changes in transactions
    _transactionService.transactionsStream.listen((updatedTransactions) {
      setState(() {
        _transactions = updatedTransactions;
      });
    });
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good morning,';
    } else if (hour < 17) {
      _greeting = 'Good afternoon,';
    } else {
      _greeting = 'Good evening,';
    }
  }

  Future<void> _loadUsername() async {
    setState(() {
      _isLoadingUser = true;
    });
    
    try {
      // Load user data from the authentication service
      final userData = await _authService.getCurrentUser();
      
      setState(() {
        // Access the name from the user data
        _username = userData['data']['user']['name'] ?? "User";
        _isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        _username = "User"; // Fallback to default name
        _isLoadingUser = false;
      });
      
      // Optionally show an error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: $e')),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Open add expense screen when the plus button is tapped
    if (index == 2) {
      _openAddExpenseScreen();
    }
    // Navigate to statistics screen when chart icon is tapped
    else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StatisticScreen()),
      );
    }
    // Navigate to profile screen when profile icon is tapped
    else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  void _openAddExpenseScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(
          onAddExpense: _addNewTransaction,
        ),
      ),
    );
  }

  void _addNewTransaction(String name, double amount, DateTime date, File? invoice, bool isExpense) {
    // Format the date
    String formattedDate = _formatDate(date);
    
    // Format the amount with correct sign based on transaction type
    String formattedAmount = !isExpense 
        ? '+ \$${amount.toStringAsFixed(2)}'
        : '- \$${amount.toStringAsFixed(2)}';
    
    // Get the first letter of the name as the logo
    String logo = name.substring(0, 1);
    
    // Determine the color based on the name
    Color logoColor = _getColorForName(name);
    
    // Create the new transaction
    Transaction newTransaction = Transaction(
      logo: logo,
      name: name,
      date: formattedDate,
      amount: formattedAmount,
      isPositive: !isExpense,
      logoBackgroundColor: logoColor,
      rawAmount: !isExpense ? amount : -amount, // Store the raw amount with correct sign
    );
    
    // Add to the transaction service
    _transactionService.addTransaction(newTransaction);
  }

  String _formatDate(DateTime date) {
    // Check if the date is today
    final today = DateTime.now();
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    }
    
    // Check if the date is yesterday
    final yesterday = today.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    }
    
    // Otherwise return formatted date
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getColorForName(String name) {
    // Map common services to colors
    Map<String, Color> colorMap = {
      'Netflix': Colors.red,
      'Spotify': Colors.green,
      'Amazon': Colors.orange,
      'Youtube': Colors.red,
      'Groceries': Colors.blue,
      'Transport': Colors.purple,
    };
    
    // Return the color if it exists in the map, otherwise return a default color
    return colorMap[name] ?? Colors.blueGrey;
  }

  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Clear All Transactions',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'This will remove all transaction history. This action cannot be undone.',
            style: GoogleFonts.inter(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(),
              ),
            ),
            TextButton(
              onPressed: () {
                _transactionService.clearTransactions();
                Navigator.of(context).pop();
                
                // Show a snackbar to confirm the action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'All transactions have been cleared',
                      style: GoogleFonts.inter(),
                    ),
                    backgroundColor: const Color(0xFF544388),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Clear',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Update greeting in case time has changed
    _updateGreeting();
    
    // Calculate the current balance values
    final totalBalance = _transactionService.calculateTotalBalance();
    final totalIncome = _transactionService.calculateTotalIncome();
    final totalExpenses = _transactionService.calculateTotalExpenses();
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Top bar with greeting and notification
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      _isLoadingUser
                        ? SizedBox(
                            height: 20,
                            width: 100,
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.grey[200],
                              color: const Color(0xFF544388),
                            ),
                          )
                        : Text(
                            _username,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Balance card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF544388),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Balance',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, color: Colors.white),
                          onSelected: (String choice) {
                            if (choice == 'clear') {
                              // Show confirmation dialog
                              _showClearConfirmationDialog();
                            }
                          },
                          color: Colors.white,
                          itemBuilder: (BuildContext context) {
                            return [
                              const PopupMenuItem<String>(
                                value: 'clear',
                                child: Text('Clear Transactions'),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${totalBalance.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Income
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.arrow_downward,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Income',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  '\$${totalIncome.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Expenses
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.arrow_upward,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expenses',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  '\$${totalExpenses.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Transaction history
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions History',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'See all',
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Transactions list
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    return _buildTransactionItem(
                      logo: transaction.logo,
                      name: transaction.name,
                      date: transaction.date,
                      amount: transaction.amount,
                      isPositive: transaction.isPositive,
                      logoBackgroundColor: transaction.logoBackgroundColor,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF544388),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF544388),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required String logo,
    required String name,
    required String date,
    required String amount,
    required bool isPositive,
    required Color logoBackgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: logoBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                logo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
} 
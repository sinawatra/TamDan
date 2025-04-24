import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../model/transaction_service.dart';
import '../services/transaction_api_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final Function(String, double, DateTime, File?, bool isExpense)? onAddExpense;

  const AddExpenseScreen({
    Key? key,
    this.onAddExpense,
  }) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  String _selectedName = 'Netflix';
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  File? _invoiceImage;
  final ImagePicker _picker = ImagePicker();
  bool _isExpense = true; // Default to expense
  final TransactionService _transactionService = TransactionService();
  final TransactionApiService _apiService = TransactionApiService();

  // Sample expense options
  final List<Map<String, dynamic>> _expenseOptions = [
    {'name': 'Netflix', 'icon': Icons.movie_outlined, 'color': Colors.red},
    {'name': 'Spotify', 'icon': Icons.music_note, 'color': Colors.green},
    {'name': 'Amazon', 'icon': Icons.shopping_cart, 'color': Colors.orange},
    {'name': 'Groceries', 'icon': Icons.shopping_basket, 'color': Colors.blue},
    {'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.purple},
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _invoiceImage = File(image.path);
      });
    }
  }

  void _addExpense() async {
    if (_amountController.text.isNotEmpty) {
      double amount = double.parse(_amountController.text);
      
      // Format the date
      String formattedDate = _formatDate(_selectedDate);
      
      // Format the amount with correct sign based on transaction type
      String formattedAmount = !_isExpense 
          ? '+ \$${amount.toStringAsFixed(2)}'
          : '- \$${amount.toStringAsFixed(2)}';
      
      // Get the first letter of the name as the logo
      String logo = _selectedName.substring(0, 1);
      
      // Determine the color based on the name
      Color logoColor = _getColorForName(_selectedName);
      
      // Create the new transaction
      Transaction newTransaction = Transaction(
        logo: logo,
        name: _selectedName,
        date: formattedDate,
        amount: formattedAmount,
        isPositive: !_isExpense,
        logoBackgroundColor: logoColor,
        rawAmount: !_isExpense ? amount : -amount, // Store the raw amount with correct sign
      );
      
      // Add transaction to local service
      _transactionService.addTransaction(newTransaction);
      
      // Save to database via API
      try {
        Map<String, dynamic> result;
        
        print('DEBUG: Trying to add ${_isExpense ? "expense" : "income"} with:');
        print('DEBUG: Category: $_selectedName');
        print('DEBUG: Amount: $amount');
        print('DEBUG: Date: $_selectedDate');
        
        // Check if user ID is set
        // The _getUserId method is private, we can't access it directly
        // Just print debug information about user authentication
        print('DEBUG: Checking if user is authenticated...');
        
        if (_isExpense) {
          result = await _apiService.addExpense(_selectedName, amount, _selectedDate);
        } else {
          result = await _apiService.addIncome(_selectedName, amount, _selectedDate);
        }
        
        print('DEBUG: API response: $result');
        
        if (result['status'] != 'success') {
          // Handle error - could show a snackbar but still allow local storage
          print('DEBUG: API Error: ${result['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('API Error: ${result['message']}'))
          );
        } else {
          print('DEBUG: Successfully added to backend database');
        }
      } catch (e) {
        // Handle network errors
        print('DEBUG: Network Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network Error: $e'))
        );
      }
      
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
    }
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
    // Check if the name is in our expense options
    for (var option in _expenseOptions) {
      if (option['name'] == name) {
        return option['color'] as Color;
      }
    }
    
    // Map common services to colors if not in options
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2250),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isExpense ? 'Add Expense' : 'Add Income',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transaction Type Selector
                    const Text(
                      'TYPE',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isExpense = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _isExpense ? const Color(0xFF544388) : Colors.transparent,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Expense',
                                    style: TextStyle(
                                      color: _isExpense ? Colors.white : Colors.black,
                                      fontWeight: _isExpense ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isExpense = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_isExpense ? const Color(0xFF544388) : Colors.transparent,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Income',
                                    style: TextStyle(
                                      color: !_isExpense ? Colors.white : Colors.black,
                                      fontWeight: !_isExpense ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Name Field
                    const Text(
                      'NAME',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedName,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          elevation: 16,
                          style: const TextStyle(color: Colors.black),
                          onChanged: (String? value) {
                            setState(() {
                              _selectedName = value!;
                            });
                          },
                          items: _expenseOptions.map<DropdownMenuItem<String>>((Map<String, dynamic> option) {
                            return DropdownMenuItem<String>(
                              value: option['name'],
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: option['color'],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      option['icon'],
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(option['name']),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Amount Field
                    const Text(
                      'AMOUNT',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              showCursor: true,
                              readOnly: true, // Prevent system keyboard from showing
                              decoration: InputDecoration(
                                hintText: '0.00',
                                prefixText: '\$ ',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _amountController.clear();
                            },
                            child: Text(
                              'Clear',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Date Field
                    const Text(
                      'DATE',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Invoice Field
                    const Text(
                      'INVOICE',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _invoiceImage != null ? 'Invoice Added' : 'Add Invoice',
                              style: TextStyle(
                                color: _invoiceImage != null ? Colors.green : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Numeric Keypad
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    _buildKeypadButton('1'),
                    _buildKeypadButton('2'),
                    _buildKeypadButton('3'),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('4'),
                    _buildKeypadButton('5'),
                    _buildKeypadButton('6'),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('7'),
                    _buildKeypadButton('8'),
                    _buildKeypadButton('9'),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('.'),
                    _buildKeypadButton('0'),
                    _buildKeypadButton('⌫'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _addExpense,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF544388),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isExpense ? 'Add Expense' : 'Add Income',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String text) {
    return Expanded(
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextButton(
          onPressed: () {
            if (text == '⌫') {
              if (_amountController.text.isNotEmpty) {
                _amountController.text = _amountController.text.substring(0, _amountController.text.length - 1);
                _amountController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _amountController.text.length),
                );
              }
            } else {
              _amountController.text += text;
              _amountController.selection = TextSelection.fromPosition(
                TextPosition(offset: _amountController.text.length),
              );
            }
          },
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
} 
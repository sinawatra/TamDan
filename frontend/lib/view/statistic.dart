import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/transaction_service.dart';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  String _selectedPeriod = 'Day';
  String _selectedTransactionType = 'Expense';
  final TransactionService _transactionService = TransactionService();
  late List<Transaction> _filteredTransactions;
  late List<Transaction> _topSpending;
  
  final List<String> _periods = ['Day', 'Week', 'Month', 'Year'];
  final List<String> _transactionTypes = ['Expense', 'Income', 'All'];
  
  // Monthly data for chart
  late Map<String, double> _monthlyData;
  late List<String> _months;
  late List<double> _values;
  late double _maxValue = 0;
  late double _selectedPeriodTotal = 0;

  @override
  void initState() {
    super.initState();
    _updateData();
    
    // Listen for changes in transactions
    _transactionService.transactionsStream.listen((_) {
      if (mounted) {
        _updateData();
      }
    });
  }

  void _updateData() {
    // Get filtered transactions based on period
    _filteredTransactions = _transactionService.getTransactionsByPeriod(_selectedPeriod);
    
    // Filter by transaction type
    if (_selectedTransactionType == 'Expense') {
      _filteredTransactions = _filteredTransactions.where((tx) => !tx.isPositive).toList();
    } else if (_selectedTransactionType == 'Income') {
      _filteredTransactions = _filteredTransactions.where((tx) => tx.isPositive).toList();
    }
    
    // Update top spending/income
    if (_selectedTransactionType == 'Income') {
      _topSpending = _transactionService.getTopIncome().take(5).toList();
    } else {
      _topSpending = _transactionService.getTopSpending().take(5).toList();
    }
    
    // Update chart data - get monthly data from service
    _monthlyData = _transactionService.getMonthlyData();
    
    // Filter the monthly data based on transaction type for display
    if (_selectedTransactionType != 'All') {
      // Create a new filtered monthly data map
      Map<String, double> filteredMonthly = {};
      
      // For each month, recalculate the value based on transaction type
      for (String month in _monthlyData.keys) {
        double value = 0;
        
        // Get the month index
        int monthIndex = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'].indexOf(month);
        if (monthIndex == -1) continue;
        
        // Calculate year (for months in previous year)
        int year = DateTime.now().year;
        int currentMonthIndex = DateTime.now().month - 1;
        if (monthIndex > currentMonthIndex) year--;
        
        // Get start and end of the month
        final monthStart = DateTime(year, monthIndex + 1, 1);
        final monthEnd = (monthIndex + 1 == 12)
            ? DateTime(year + 1, 1, 0)
            : DateTime(year, monthIndex + 2, 0);
        
        // Calculate total for the month based on transaction type
        for (Transaction tx in _transactionService.transactions) {
          if (tx.fullDate == null) continue;
          
          if (!tx.fullDate!.isBefore(monthStart) && !tx.fullDate!.isAfter(monthEnd)) {
            if (_selectedTransactionType == 'Income' && tx.isPositive) {
              value += tx.rawAmount.abs();
            } else if (_selectedTransactionType == 'Expense' && !tx.isPositive) {
              value += tx.rawAmount.abs();
            }
          }
        }
        
        filteredMonthly[month] = value;
      }
      
      _monthlyData = filteredMonthly;
    }
    
    _months = _monthlyData.keys.toList();
    _values = _monthlyData.values.toList();
    _maxValue = _values.isNotEmpty ? _values.reduce((a, b) => a > b ? a : b) : 0;
    
    // Calculate total for selected period and type
    if (_selectedTransactionType == 'Expense') {
      _selectedPeriodTotal = _filteredTransactions.fold(0.0, (sum, tx) => sum + tx.rawAmount.abs());
    } else if (_selectedTransactionType == 'Income') {
      _selectedPeriodTotal = _filteredTransactions.fold(0.0, (sum, tx) => sum + tx.rawAmount);
    } else {
      _selectedPeriodTotal = _filteredTransactions
          .where((tx) => tx.isPositive)
          .fold(0.0, (sum, tx) => sum + tx.rawAmount) - 
          _filteredTransactions
          .where((tx) => !tx.isPositive)
          .fold(0.0, (sum, tx) => sum + tx.rawAmount.abs());
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Statistics',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _periods.map((period) {
                bool isSelected = period == _selectedPeriod;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPeriod = period;
                    });
                    _updateData();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF544388) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      period,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Transaction type dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            child: PopupMenuButton<String>(
              offset: const Offset(0, 40),
              onSelected: (value) {
                setState(() {
                  _selectedTransactionType = value;
                });
                _updateData();
              },
              itemBuilder: (context) {
                return _transactionTypes.map((type) {
                  return PopupMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedTransactionType),
                    const SizedBox(width: 5),
                    const Icon(Icons.keyboard_arrow_down, size: 16),
                  ],
                ),
              ),
            ),
          ),

          // Simple Bar Chart section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            height: 250,
            child: Column(
              children: [
                // Value indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    '\$${_selectedPeriodTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _selectedTransactionType == 'Income' 
                          ? Colors.green 
                          : (_selectedTransactionType == 'Expense' 
                              ? Colors.red 
                              : const Color(0xFF4CAF97)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Simple bar chart
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      _months.length,
                      (index) => _buildBar(index)
                    ),
                  ),
                ),
                
                // Month labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _months.map((month) => Text(
                    month,
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),

          // Top Spending section
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Header with "See all" link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTransactionType == 'Income' ? 'Top Income' : 'Top Spending',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'See all',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // List of top spending/income items
                  Expanded(
                    child: _topSpending.isEmpty
                      ? Center(
                          child: Text(
                            'No transactions found',
                            style: GoogleFonts.inter(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _topSpending.length,
                          itemBuilder: (context, index) {
                            final item = _topSpending[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                              decoration: BoxDecoration(
                                color: index == 0 ? const Color(0xFF544388) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  // Logo
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: item.logoBackgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.logo,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            color: index == 0 ? Colors.white : Colors.black,
                                          ),
                                        ),
                                        Text(
                                          item.date,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: index == 0 ? Colors.white70 : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Amount
                                  Text(
                                    item.amount,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: index == 0 
                                          ? Colors.white 
                                          : (item.isPositive ? Colors.green : Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Custom bar widget
  Widget _buildBar(int index) {
    // Set minimum bar height and maximum allowed height
    const double minBarHeight = 5.0;
    const double maxBarHeight = 140.0;
    
    // Calculate normalized value with constraints
    double normalizedValue = 0;
    if (_maxValue > 0) {
      normalizedValue = (_values[index] / _maxValue * maxBarHeight);
      // Ensure bar has minimum height if value exists
      if (_values[index] > 0 && normalizedValue < minBarHeight) {
        normalizedValue = minBarHeight;
      }
    }
    
    final bool isHighlighted = index == _months.length - 1; // Highlight the current month
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: normalizedValue.isNaN ? 0 : normalizedValue,
          decoration: BoxDecoration(
            color: isHighlighted 
                ? (_selectedTransactionType == 'Income' 
                    ? Colors.green 
                    : (_selectedTransactionType == 'Expense' 
                        ? Colors.red 
                        : const Color(0xFF4CAF97)))
                : (_selectedTransactionType == 'Income' 
                    ? Colors.green.withOpacity(0.3) 
                    : (_selectedTransactionType == 'Expense' 
                        ? Colors.red.withOpacity(0.3) 
                        : const Color(0xFF4CAF97).withOpacity(0.3))),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
        if (isHighlighted)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _selectedTransactionType == 'Income' 
                  ? Colors.green 
                  : (_selectedTransactionType == 'Expense' 
                      ? Colors.red 
                      : const Color(0xFF4CAF97)),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

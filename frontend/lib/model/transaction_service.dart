import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class Transaction {
  final String logo;
  final String name;
  final String date;
  final String amount;
  final bool isPositive;
  final Color logoBackgroundColor;
  final double rawAmount;
  final DateTime? fullDate; // Store the actual date for better filtering

  Transaction({
    required this.logo,
    required this.name,
    required this.date,
    required this.amount,
    required this.isPositive,
    required this.logoBackgroundColor,
    required this.rawAmount,
    this.fullDate,
  });
}

class TransactionService {
  // Singleton pattern
  static final TransactionService _instance = TransactionService._internal();

  factory TransactionService() {
    return _instance;
  }

  TransactionService._internal() {
    // Initialize with some transactions spread across different months
    _generateHistoricalTransactions();
  }

  // Stream controller for transactions
  final _transactionsController = StreamController<List<Transaction>>.broadcast();
  Stream<List<Transaction>> get transactionsStream => _transactionsController.stream;

  // Local storage of transactions
  List<Transaction> _transactions = [];

  void _generateHistoricalTransactions() {
    final Random rand = Random();
    final List<String> expenseNames = ['Netflix', 'Spotify', 'Amazon', 'Groceries', 'Transport', 'Rent', 'Utilities', 'Dining'];
    final List<String> incomeNames = ['Salary', 'Freelance', 'Dividends', 'Interest', 'Bonus'];
    final List<Color> colors = [Colors.red, Colors.green, Colors.blue, Colors.purple, Colors.orange, Colors.teal];
    
    // Current date for reference
    final now = DateTime.now();
    
    // Generate transactions for the past 7 months
    for (int i = 0; i < 7; i++) {
      // Each month has 5-15 transactions
      int numTransactions = rand.nextInt(10) + 5;
      
      // Calculate the month (current month - i)
      DateTime monthDate = DateTime(now.year, now.month - i, 15);
      
      for (int j = 0; j < numTransactions; j++) {
        // Random day in that month
        int day = rand.nextInt(28) + 1;
        DateTime date = DateTime(monthDate.year, monthDate.month, day);
        
        // 70% chance of expense, 30% chance of income
        bool isExpense = rand.nextDouble() < 0.7;
        
        // Transaction amount
        double amount = isExpense 
            ? (rand.nextDouble() * 100 + 10) // Expense: $10-$110
            : (rand.nextDouble() * 1000 + 500); // Income: $500-$1500
        
        // Round to 2 decimal places
        amount = (amount * 100).round() / 100;
        
        // Create transaction
        String name = isExpense 
            ? expenseNames[rand.nextInt(expenseNames.length)]
            : incomeNames[rand.nextInt(incomeNames.length)];
        
        Color color = colors[rand.nextInt(colors.length)];
        
        _transactions.add(Transaction(
          logo: name.substring(0, 1),
          name: name,
          date: _formatDateForDisplay(date),
          amount: isExpense ? '- \$${amount.toStringAsFixed(2)}' : '+ \$${amount.toStringAsFixed(2)}',
          isPositive: !isExpense,
          logoBackgroundColor: color,
          rawAmount: isExpense ? -amount : amount,
          fullDate: date,
        ));
      }
    }
    
    // Add the initial standard transactions
    _transactions.addAll([
      Transaction(
        logo: 'U',
        name: 'Upwork',
        date: 'Today',
        amount: '+ \$850.00',
        isPositive: true,
        logoBackgroundColor: Colors.green,
        rawAmount: 850.00,
        fullDate: DateTime.now(),
      ),
      Transaction(
        logo: 'T',
        name: 'Transfer',
        date: 'Yesterday',
        amount: '- \$85.00',
        isPositive: false,
        logoBackgroundColor: Colors.grey,
        rawAmount: -85.00,
        fullDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Transaction(
        logo: 'P',
        name: 'Paypal',
        date: 'Jan 30, 2022',
        amount: '+ \$1,406.00',
        isPositive: true,
        logoBackgroundColor: Colors.blue,
        rawAmount: 1406.00,
        fullDate: DateTime(2022, 1, 30),
      ),
      Transaction(
        logo: 'Y',
        name: 'Youtube',
        date: 'Jan 16, 2022',
        amount: '- \$11.99',
        isPositive: false,
        logoBackgroundColor: Colors.red,
        rawAmount: -11.99,
        fullDate: DateTime(2022, 1, 16),
      ),
    ]);
    
    // Sort by date (most recent first)
    _transactions.sort((a, b) {
      if (a.fullDate == null || b.fullDate == null) return 0;
      return b.fullDate!.compareTo(a.fullDate!);
    });
  }

  String _formatDateForDisplay(DateTime date) {
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

  // Methods to interact with transactions
  List<Transaction> get transactions => _transactions;

  void addTransaction(Transaction transaction) {
    _transactions.insert(0, transaction);
    _transactionsController.add(_transactions);
  }

  // Calculate total balance from transactions
  double calculateTotalBalance() {
    return _transactions.fold(0, (sum, transaction) => sum + transaction.rawAmount);
  }

  // Calculate total income from transactions
  double calculateTotalIncome() {
    return _transactions
        .where((transaction) => transaction.isPositive)
        .fold(0, (sum, transaction) => sum + transaction.rawAmount);
  }

  // Calculate total expenses from transactions
  double calculateTotalExpenses() {
    return _transactions
        .where((transaction) => !transaction.isPositive)
        .fold(0, (sum, transaction) => sum + transaction.rawAmount.abs());
  }

  // Get transactions for a specific period (day, week, month, year)
  List<Transaction> getTransactionsByPeriod(String period) {
    final now = DateTime.now();
    
    switch (period) {
      case 'Day':
        return _getTransactionsForToday();
      case 'Week':
        return _getTransactionsForPeriod(now.subtract(const Duration(days: 7)), now);
      case 'Month':
        return _getTransactionsForPeriod(DateTime(now.year, now.month - 1, now.day), now);
      case 'Year':
        return _getTransactionsForPeriod(DateTime(now.year - 1, now.month, now.day), now);
      default:
        return _transactions;
    }
  }

  // Helper methods for filtering transactions by period
  List<Transaction> _getTransactionsForToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _transactions.where((tx) => 
      tx.date == 'Today' || 
      (tx.fullDate != null && 
       tx.fullDate!.year == today.year && 
       tx.fullDate!.month == today.month && 
       tx.fullDate!.day == today.day)
    ).toList();
  }

  List<Transaction> _getTransactionsForPeriod(DateTime start, DateTime end) {
    return _transactions.where((tx) {
      if (tx.fullDate == null) {
        // Handle transactions without a fullDate (use string date)
        if (tx.date == 'Today') return true;
        if (tx.date == 'Yesterday') return end.difference(DateTime.now().subtract(const Duration(days: 1))).inDays <= 7;
        return false; // Can't determine for other string formats without parsing
      }
      
      // Check if the transaction falls within the date range
      return !tx.fullDate!.isBefore(start) && !tx.fullDate!.isAfter(end);
    }).toList();
  }

  // Get monthly data for chart (last 7 months including current)
  Map<String, double> getMonthlyData() {
    Map<String, double> monthlyData = {};
    DateTime now = DateTime.now();
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    // Get last 7 months (including current)
    for (int i = 6; i >= 0; i--) {
      int monthIndex = (now.month - 1 - i) % 12;
      if (monthIndex < 0) monthIndex += 12;
      
      String monthName = months[monthIndex];
      
      // Calculate the year (for months that might be in the previous year)
      int year = now.year;
      if (now.month - i <= 0) year--;
      
      // Get transactions for this month
      final monthStart = DateTime(year, monthIndex + 1, 1);
      final monthEnd = (monthIndex + 1 == 12) 
          ? DateTime(year + 1, 1, 0) 
          : DateTime(year, monthIndex + 2, 0);
      
      // Calculate total for the month depending on transaction type filter
      double monthTotal = 0;
      
      _transactions.forEach((tx) {
        if (tx.fullDate == null) return;
        
        if (!tx.fullDate!.isBefore(monthStart) && !tx.fullDate!.isAfter(monthEnd)) {
          // For all transactions in this month, add their value (income positive, expense negative)
          monthTotal += tx.rawAmount;
        }
      });
      
      // Take absolute value for display purposes
      monthlyData[monthName] = monthTotal.abs();
    }
    
    return monthlyData;
  }

  // Get top spending categories
  List<Transaction> getTopSpending() {
    return _transactions
        .where((tx) => !tx.isPositive)
        .toList()
        ..sort((a, b) => b.rawAmount.abs().compareTo(a.rawAmount.abs()));
  }

  // Get top income sources
  List<Transaction> getTopIncome() {
    return _transactions
        .where((tx) => tx.isPositive)
        .toList()
        ..sort((a, b) => b.rawAmount.abs().compareTo(a.rawAmount.abs()));
  }

  // Clear all transactions
  void clearTransactions() {
    _transactions.clear();
    _transactionsController.add(_transactions);
  }

  void dispose() {
    _transactionsController.close();
  }
} 
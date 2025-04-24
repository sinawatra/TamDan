import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TransactionApiService {
  // For Android emulator
  final String baseUrl = 'http://10.0.2.2:3000/api/transactions';
  // Use 'http://localhost:3000/api/transactions' for iOS simulator

  // Get user ID from SharedPreferences
  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    print('DEBUG TransactionApiService: Retrieved userId from SharedPreferences: $userId');
    return userId;
  }

  // Add expense to the database
  Future<Map<String, dynamic>> addExpense(String category, double amount, DateTime date) async {
    final userId = await _getUserId();
    
    if (userId == null) {
      return {
        'status': 'error',
        'message': 'User not authenticated'
      };
    }

    final response = await http.post(
      Uri.parse('$baseUrl/expense'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
      }),
    );

    return jsonDecode(response.body);
  }

  // Add income to the database
  Future<Map<String, dynamic>> addIncome(String category, double amount, DateTime date) async {
    final userId = await _getUserId();
    
    if (userId == null) {
      return {
        'status': 'error',
        'message': 'User not authenticated'
      };
    }

    final response = await http.post(
      Uri.parse('$baseUrl/income'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
      }),
    );

    return jsonDecode(response.body);
  }

  // Get all transactions for the authenticated user
  Future<List<dynamic>> getTransactions() async {
    final userId = await _getUserId();
    
    if (userId == null) {
      return [];
    }

    final response = await http.get(
      Uri.parse('$baseUrl/transactions?userId=$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      return [];
    }
  }
} 
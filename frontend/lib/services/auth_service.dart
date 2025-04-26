import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Update this URL with your backend URL (use IP address if testing on physical device)
  final String baseUrl = 'http://10.0.2.2:3000/api/auth'; // For Android emulator
  // Use 'http://localhost:3000/api/auth' for iOS simulator
  // Use your actual machine IP if testing on physical device
  
  final storage =  FlutterSecureStorage();

  // Register a new user
  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        // Store token securely
        await storage.write(key: 'token', value: responseData['token']);
        
        // Store user ID in SharedPreferences for easy access
        if (responseData['data'] != null && responseData['data']['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', responseData['data']['user']['id'].toString());
          print('DEBUG AuthService: Stored userId in SharedPreferences: ${responseData['data']['user']['id']}');
        }
        
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);
      print('DEBUG AuthService: Login response: $responseData');
      
      if (response.statusCode == 200) {
        // Store token securely
        await storage.write(key: 'token', value: responseData['token']);
        
        // Store user ID in SharedPreferences for easy access
        if (responseData['data'] != null && responseData['data']['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', responseData['data']['user']['id'].toString());
          print('DEBUG AuthService: Stored userId in SharedPreferences: ${responseData['data']['user']['id']}');
        } else {
          print('DEBUG AuthService: Could not find user data in response to store userId');
        }
        
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  // Get authenticated user
  Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await storage.read(key: 'token');
    
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Update user ID in SharedPreferences (in case it wasn't set before)
        if (responseData['data'] != null && responseData['data']['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', responseData['data']['user']['id'].toString());
        }
        
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to get user data');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  // Logout user
  Future<void> logout() async {
    await storage.delete(key: 'token');
    // Also clear SharedPreferences data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await storage.read(key: 'token');
    return token != null;
  }
} 
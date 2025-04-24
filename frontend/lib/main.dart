import 'package:flutter/material.dart';
import 'package:tamdan/view/splash_screen.dart';
import 'package:tamdan/view/statistic.dart';
import 'package:tamdan/view/profile.dart';
import 'package:tamdan/view/login_screen.dart';
import 'package:tamdan/view/home_screen.dart';
import 'package:tamdan/services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xff544388)),
          useMaterial3: true,
        ),
        routes: {
          '/statistics': (context) => const StatisticScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
        home: AuthWrapper());
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isChecking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const SplashScreen();
    }

    if (_isLoggedIn) {
      return const HomeScreen();
    } else {
      return const SplashScreen();
    }
  }
}

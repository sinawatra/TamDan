import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:tamdan/view/onboarding.dart';
import 'package:tamdan/services/auth_service.dart';
import 'package:tamdan/view/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }
  
  Future<void> _navigateToNextScreen() async {
    // Wait for the splash screen to show for 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    // Check if the user is already logged in
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (!mounted) return;
      
      if (isLoggedIn) {
        // Navigate to the home screen if already logged in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Navigate to the onboarding screen if not logged in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    } catch (e) {
      // If there's an error, default to onboarding
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.53, 1.0],
            colors: [
              Color(0xFF1A1C1C),
              Color(0xFF393155),
              Color(0xFF544388),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Tamdan",
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),
      ),
    );
  }
}

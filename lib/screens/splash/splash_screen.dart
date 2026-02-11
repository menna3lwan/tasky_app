import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/helpers/responsive_helper.dart';
import '../../utilities/services/auth_service.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// Following Single Responsibility Principle - only handles splash display and navigation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Check if user is already logged in
      if (_authService.isLoggedIn) {
        // Auto login - redirect to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Not logged in - show onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final fontSize = responsive.fontSize(mobile: 48, tablet: 56, desktop: 64);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Taskat" in white
            Text(
              'Taskat',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // "k" in yellow
            Text(
              'k',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.splashYellow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

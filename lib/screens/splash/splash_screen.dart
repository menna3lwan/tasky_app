import 'package:flutter/material.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/constants/app_dimensions.dart';
import '../onboarding/onboarding_screen.dart';

/// Splash screen that displays the app logo
/// Following Single Responsibility Principle - only handles splash display and navigation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToOnboarding();
  }

  Future<void> _navigateToOnboarding() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // App logo text: "Task" in white + "y" in yellow
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: AppDimensions.fontHeading,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: 'Task',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'y',
                    style: TextStyle(color: AppColors.splashYellow),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Bottom indicator line
            Container(
              width: 60,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppDimensions.paddingXXL),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

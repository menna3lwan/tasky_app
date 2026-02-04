import 'package:flutter/material.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/constants/app_dimensions.dart';
import '../../utilities/services/auth_service.dart';
import '../auth/login_screen.dart';

/// Home screen displayed after successful login
/// Following Single Responsibility Principle - handles home UI
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: AppDimensions.fontXL,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(
                text: 'Task',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              TextSpan(
                text: 'y',
                style: TextStyle(color: AppColors.splashYellow),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 100,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppDimensions.paddingL),
              Text(
                'Welcome, ${user?.displayName ?? 'User'}!',
                style: const TextStyle(
                  fontSize: AppDimensions.fontXXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                user?.email ?? '',
                style: const TextStyle(
                  fontSize: AppDimensions.fontM,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXXL),
              const Text(
                'You are successfully logged in!',
                style: TextStyle(
                  fontSize: AppDimensions.fontL,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

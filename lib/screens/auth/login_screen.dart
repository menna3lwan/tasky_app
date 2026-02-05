import 'package:flutter/material.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/constants/app_dimensions.dart';
import '../../utilities/constants/app_strings.dart';
import '../../utilities/services/auth_service.dart';
import '../../utilities/validators/validator.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/custom_text_field.dart' hide Validator;
import '../../widgets/loading/loading_overlay.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

/// Login screen for user authentication
/// Following Single Responsibility Principle - handles only login UI and validation
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // Show loading overlay
      LoadingOverlay.show(context);

      final result = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Hide loading overlay
      LoadingOverlay.hide();

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Login failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.paddingXXL),
                // Title
                const Text(
                  AppStrings.login,
                  style: TextStyle(
                    fontSize: AppDimensions.fontHeading,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXXL),
                // Email field
                CustomTextField(
                  title: AppStrings.email,
                  hintText: AppStrings.enterUsername,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validator.validateEmail,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                // Password field
                CustomTextField(
                  title: AppStrings.password,
                  hintText: AppStrings.enterPassword,
                  controller: _passwordController,
                  isPassword: true,
                  validator: Validator.validatePassword,
                ),
                const SizedBox(height: AppDimensions.paddingXL),
                // Login button
                PrimaryButton(
                  text: AppStrings.login,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: AppDimensions.paddingXXL * 2),
                // Register link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        AppStrings.noAccount,
                        style: TextStyle(
                          fontSize: AppDimensions.fontM,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToRegister,
                        child: const Text(
                          AppStrings.register,
                          style: TextStyle(
                            fontSize: AppDimensions.fontM,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

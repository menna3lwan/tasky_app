import 'package:flutter/material.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/constants/app_dimensions.dart';
import '../../utilities/constants/app_strings.dart';
import '../../utilities/services/auth_service.dart';
import '../../utilities/validators/input_validators.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/custom_text_field.dart';
import '../../widgets/loading/loading_overlay.dart';
import '../home/home_screen.dart';

/// Register screen for new user registration
/// Following Single Responsibility Principle - handles only registration UI and validation
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      // Show loading overlay
      LoadingOverlay.show(context);

      final result = await _authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );

      // Hide loading overlay
      LoadingOverlay.hide();

      if (mounted) {
        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful!'),
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
              content: Text(result.errorMessage ?? 'Registration failed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pop(context);
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
                  AppStrings.register,
                  style: TextStyle(
                    fontSize: AppDimensions.fontHeading,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXL),
                // Username field
                CustomTextField(
                  title: AppStrings.username,
                  hintText: AppStrings.enterUsername,
                  controller: _usernameController,
                  validator: InputValidators.validateUsername,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                // Email field
                CustomTextField(
                  title: AppStrings.email,
                  hintText: AppStrings.enterUsername,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: InputValidators.validateEmail,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                // Password field
                CustomTextField(
                  title: AppStrings.password,
                  hintText: AppStrings.enterPassword,
                  controller: _passwordController,
                  isPassword: true,
                  validator: InputValidators.validatePassword,
                ),
                const SizedBox(height: AppDimensions.paddingM),
                // Confirm Password field
                CustomTextField(
                  title: AppStrings.confirmPassword,
                  hintText: AppStrings.enterPassword,
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (value) => InputValidators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXL),
                // Register button
                PrimaryButton(
                  text: AppStrings.register,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: AppDimensions.paddingXL),
                // Login link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        AppStrings.haveAccount,
                        style: TextStyle(
                          fontSize: AppDimensions.fontM,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _navigateToLogin,
                        child: const Text(
                          AppStrings.login,
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

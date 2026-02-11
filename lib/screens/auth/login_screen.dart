import 'package:flutter/material.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/constants/app_dimensions.dart';
import '../../utilities/constants/app_strings.dart';
import '../../utilities/helpers/responsive_helper.dart';
import '../../utilities/services/auth_service.dart';
import '../../utilities/validators/validator.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/custom_text_field.dart';
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
    final responsive = context.responsive;
    final padding = responsive.spacing(mobile: AppDimensions.paddingL, tablet: 32, desktop: 40);
    final titleSize = responsive.fontSize(mobile: AppDimensions.fontHeading, tablet: 34, desktop: 38);
    final labelSize = responsive.fontSize(mobile: AppDimensions.fontM, tablet: 15, desktop: 16);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: responsive.contentMaxWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: responsive.spacing(mobile: AppDimensions.paddingXXL, tablet: 48)),
                    // Title
                    Text(
                      AppStrings.login,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(mobile: AppDimensions.paddingXXL, tablet: 40)),
                    // Email field
                    CustomTextField(
                      title: AppStrings.email,
                      hintText: AppStrings.enterUsername,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validator.validateEmail,
                    ),
                    SizedBox(height: responsive.spacing(mobile: AppDimensions.paddingM, tablet: 20)),
                    // Password field
                    CustomTextField(
                      title: AppStrings.password,
                      hintText: AppStrings.enterPassword,
                      controller: _passwordController,
                      isPassword: true,
                      validator: Validator.validatePassword,
                    ),
                    SizedBox(height: responsive.spacing(mobile: AppDimensions.paddingXL, tablet: 28)),
                    // Login button
                    PrimaryButton(
                      text: AppStrings.login,
                      onPressed: _handleLogin,
                    ),
                    SizedBox(height: responsive.spacing(mobile: AppDimensions.paddingXXL * 2, tablet: 64)),
                    // Register link
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            AppStrings.noAccount,
                            style: TextStyle(
                              fontSize: labelSize,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: _navigateToRegister,
                            child: Text(
                              AppStrings.register,
                              style: TextStyle(
                                fontSize: labelSize,
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
        ),
      ),
    );
  }
}

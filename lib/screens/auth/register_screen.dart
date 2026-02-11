import 'package:flutter/material.dart';
import '../../utilities/constants/app_colors.dart';
import '../../utilities/constants/app_dimensions.dart';
import '../../utilities/constants/app_strings.dart';
import '../../utilities/helpers/responsive_helper.dart';
import '../../utilities/services/auth_service.dart';
import '../../utilities/validators/validator.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/inputs/custom_text_field.dart';
import '../../widgets/inputs/password_confirm_indicator.dart';
import '../../widgets/inputs/password_strength_indicator.dart';
import '../../widgets/loading/loading_overlay.dart';
import 'login_screen.dart';

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
  String _password = '';
  String _confirmPassword = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {
      _password = _passwordController.text;
    });
  }

  void _onConfirmPasswordChanged() {
    setState(() {
      _confirmPassword = _confirmPasswordController.text;
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_onConfirmPasswordChanged);
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      LoadingOverlay.show(context);

      final result = await _authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );

      LoadingOverlay.hide();

      if (mounted) {
        if (result.isSuccess) {
          // Sign out after registration to redirect to login
          await _authService.signOut();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful! Please login.'),
                backgroundColor: AppColors.success,
              ),
            );
            // Redirect to login screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
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
                    SizedBox(height: responsive.spacing(mobile: AppDimensions.paddingXXL, tablet: 40)),
                    // Title
                    Text(
                      AppStrings.register,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(mobile: AppDimensions.paddingXL, tablet: 32)),
                    // Username field
                    CustomTextField(
                      title: AppStrings.username,
                      hintText: AppStrings.enterUsername,
                      controller: _usernameController,
                      validator: Validator.validateName,
                    ),
                    SizedBox(height: responsive.spacing(mobile: AppDimensions.paddingM, tablet: 18)),
                    // Email field
                    CustomTextField(
                      title: AppStrings.email,
                      hintText: 'Enter your email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validator.validateEmail,
                    ),
                    SizedBox(height: responsive.spacing(mobile: AppDimensions.paddingM, tablet: 18)),
                    // Password field
                    CustomTextField(
                      title: AppStrings.password,
                      hintText: AppStrings.enterPassword,
                      controller: _passwordController,
                      isPassword: true,
                      validator: Validator.validatePassword,
                    ),
                    // Password strength indicator
                    PasswordStrengthIndicator(password: _password),
                    SizedBox(height: responsive.spacing(mobile: AppDimensions.paddingM, tablet: 18)),
                    // Confirm Password field
                    CustomTextField(
                      title: AppStrings.confirmPassword,
                      hintText: 'Confirm your password',
                      controller: _confirmPasswordController,
                      isPassword: true,
                      validator: (value) => Validator.validateConfirmPassword(
                        value,
                        _passwordController.text,
                      ),
                    ),
                    // Password confirmation indicator
                    PasswordConfirmIndicator(
                      password: _password,
                      confirmPassword: _confirmPassword,
                    ),
                    SizedBox(height: responsive.spacing(mobile: AppDimensions.paddingXL, tablet: 28)),
                    // Register button
                    PrimaryButton(
                      text: AppStrings.register,
                      onPressed: _handleRegister,
                    ),
                    SizedBox(height: responsive.spacing(mobile: AppDimensions.paddingXL, tablet: 32)),
                    // Login link
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            AppStrings.haveAccount,
                            style: TextStyle(
                              fontSize: labelSize,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: _navigateToLogin,
                            child: Text(
                              AppStrings.login,
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

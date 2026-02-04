import '../constants/app_strings.dart';

/// Input validation class following Single Responsibility Principle
/// This class is responsible only for validating user inputs
/// Also follows Open/Closed Principle - easily extendable for new validation rules
abstract class InputValidators {
  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emailRequired;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return AppStrings.emailInvalid;
    }

    return null;
  }

  /// Validates password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }

    if (value.length < 6) {
      return AppStrings.passwordTooShort;
    }

    return null;
  }

  /// Validates username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.usernameRequired;
    }

    if (value.length < 3) {
      return AppStrings.usernameTooShort;
    }

    return null;
  }

  /// Validates confirm password matches original password
  static String? validateConfirmPassword(String? value, String password) {
    final passwordError = validatePassword(value);
    if (passwordError != null) {
      return passwordError;
    }

    if (value != password) {
      return AppStrings.passwordsNotMatch;
    }

    return null;
  }
}

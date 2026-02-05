const String emailRegexString =
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
const String usernameRegexString = r'^[a-zA-Z0-9,.-]+$';

// Password validation constants
const int minPasswordLength = 8;
const String allowedSpecialChars = r'!@#$%^';

abstract class Validator {
  static String? validateEmail(String? val) {
    final RegExp emailRegex = RegExp(emailRegexString);
    if (val == null || val.trim().isEmpty) {
      return 'Email cannot be empty';
    } else if (!emailRegex.hasMatch(val)) {
      return 'Enter a valid email address';
    } else {
      return null;
    }
  }

  static String? validatePassword(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Password cannot be empty';
    }

    List<String> errors = [];

    // Check minimum length
    if (val.length < minPasswordLength) {
      errors.add('at least $minPasswordLength characters');
    }

    // Check for lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(val)) {
      errors.add('1 lowercase letter');
    }

    // Check for uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(val)) {
      errors.add('1 uppercase letter');
    }

    // Check for number
    if (!RegExp(r'\d').hasMatch(val)) {
      errors.add('1 number');
    }

    // Check for invalid special characters (only !@#$%^ allowed)
    final invalidChars = RegExp(r'[^a-zA-Z0-9!@#$%^]');
    if (invalidChars.hasMatch(val)) {
      errors.add('only !@#\$%^ special characters allowed');
    }

    if (errors.isNotEmpty) {
      return 'Password requires: ${errors.join(', ')}';
    }

    return null;
  }

  /// Returns password strength from 0 to 4
  static int getPasswordStrength(String? val) {
    if (val == null || val.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (val.length >= minPasswordLength) strength++;

    // Lowercase check
    if (RegExp(r'[a-z]').hasMatch(val)) strength++;

    // Uppercase check
    if (RegExp(r'[A-Z]').hasMatch(val)) strength++;

    // Number check
    if (RegExp(r'\d').hasMatch(val)) strength++;

    return strength;
  }

  /// Check if password has valid characters only
  static bool hasValidCharsOnly(String? val) {
    if (val == null || val.isEmpty) return true;
    return !RegExp(r'[^a-zA-Z0-9!@#$%^]').hasMatch(val);
  }

  static String? validateConfirmPassword(String? val, String? password) {
    if (val == null || val.trim().isEmpty) {
      return 'Password cannot be empty';
    } else if (val != password) {
      return 'Confirm password must match the password';
    } else {
      return null;
    }
  }

  static String? validateName(String? val) {
    if (val == null || val.isEmpty) {
      return 'Name cannot be empty';
    } else {
      return null;
    }
  }

  static String? validatePhoneNumber(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Phone number cannot be empty';
    }

    final phone = val.trim();
    final isValid = RegExp(r'^\+?\d+$').hasMatch(phone);
    if (!isValid || phone.length != 13) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  static String? validateCode(String? val) {
    if (val == null || val.isEmpty) {
      return 'Code cannot be empty';
    } else if (val.length < 6) {
      return 'Code should be at least 6 digits';
    } else {
      return null;
    }
  }
}

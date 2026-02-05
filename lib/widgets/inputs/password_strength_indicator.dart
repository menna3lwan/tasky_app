import 'package:flutter/material.dart';
import '../../utilities/validators/validator.dart';

/// Password strength indicator widget
/// Shows visual bars indicating password strength based on validation rules
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final strength = Validator.getPasswordStrength(password);
    final hasValidChars = Validator.hasValidCharsOnly(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Strength bars
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: index < strength && hasValidChars
                      ? _getStrengthColor(strength)
                      : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        // Requirements text
        Text(
          'Min. 8 characters, 1 lowercase, 1 uppercase and 1 number. ONLY the following special characters are allowed: !@#\$%^',
          style: TextStyle(
            fontSize: 12,
            color: _getTextColor(strength, hasValidChars),
          ),
        ),
      ],
    );
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.green;
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  Color _getTextColor(int strength, bool hasValidChars) {
    if (!hasValidChars) {
      return Colors.red;
    }
    if (strength == 4) {
      return Colors.green;
    }
    return Colors.red;
  }
}

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
    final isValid = strength == 4 && hasValidChars;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Strength bars
        Row(
          children: List.generate(4, (index) {
            final isActive = index < strength && hasValidChars;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        // Requirements text
        Text(
          'Min. 8 characters, 1 lowercase, 1 uppercase and 1 number. ONLY the following special characters are allowed: !@#\$%^',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isValid ? Colors.green : const Color(0xFFFF4949),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

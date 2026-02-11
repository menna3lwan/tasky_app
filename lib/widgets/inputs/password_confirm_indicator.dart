import 'package:flutter/material.dart';

/// Password confirmation indicator widget
/// Shows whether the confirm password matches the original password
class PasswordConfirmIndicator extends StatelessWidget {
  final String password;
  final String confirmPassword;

  const PasswordConfirmIndicator({
    super.key,
    required this.password,
    required this.confirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    if (confirmPassword.isEmpty) {
      return const SizedBox.shrink();
    }

    final isMatch = password == confirmPassword;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            isMatch ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isMatch ? Colors.green : const Color(0xFFFF4949),
          ),
          const SizedBox(width: 6),
          Text(
            isMatch ? 'Passwords match' : 'Passwords do not match',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: isMatch ? Colors.green : const Color(0xFFFF4949),
            ),
          ),
        ],
      ),
    );
  }
}

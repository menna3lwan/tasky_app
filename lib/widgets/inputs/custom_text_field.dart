import 'package:flutter/material.dart';

/// Validator type definition
typedef Validator = String? Function(String?);

/// A reusable custom text field widget following Single Responsibility Principle
/// This widget is responsible only for rendering a styled text input field
class CustomTextField extends StatefulWidget {
  final String hintText;
  final String title;
  final TextInputType keyboardType;
  final bool isPassword;
  final TextEditingController controller;
  final Validator? validator;

  const CustomTextField({
    required this.title,
    required this.hintText,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    super.key,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xff716C7E),
          ),
        ),
        const SizedBox(height: 2),
        TextFormField(
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.black,
            overflow: TextOverflow.ellipsis,
          ),
          obscureText: widget.isPassword ? _obscureText : false,
          decoration: InputDecoration(
            hintText: widget.hintText,
            fillColor: Colors.grey.shade100,
            filled: true,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xff454A4F),
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.all(15),
            enabledBorder: _outlineInputBorder(
              color: const Color(0xff716C7E),
              radius: 10,
              width: 1,
            ),
            focusedBorder: _outlineInputBorder(
              color: const Color(0xff5F33E1),
              radius: 10,
              width: 1,
            ),
            errorBorder: _outlineInputBorder(
              color: const Color(0xffFF4949),
              radius: 10,
              width: 1,
            ),
            focusedErrorBorder: _outlineInputBorder(
              color: const Color(0xffFF4949),
              radius: 10,
              width: 1,
            ),
          ),
          keyboardType: widget.keyboardType,
          controller: widget.controller,
          validator: widget.validator,
        ),
      ],
    );
  }

  OutlineInputBorder _outlineInputBorder({
    required double radius,
    required Color color,
    required double width,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

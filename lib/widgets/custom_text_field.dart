import 'package:flutter/material.dart';

enum CustomTextFieldType { name, email, password, passwordRepeat, search }

class CustomTextField extends StatefulWidget {
  final CustomTextFieldType type;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;

  const CustomTextField({
    super.key,
    required this.type,
    this.controller,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final String label;
    final String hintText;
    final IconData prefixIcon;
    final bool isPasswordField =
        widget.type == CustomTextFieldType.password ||
        widget.type == CustomTextFieldType.passwordRepeat;

    // Configure properties based on the widget type
    switch (widget.type) {
      case CustomTextFieldType.name:
        label = 'İsim Soyisim';
        hintText = 'Adınızı Girin';
        prefixIcon = Icons.person_outline_rounded;
        break;
      case CustomTextFieldType.email:
        label = 'E-posta';
        hintText = 'email@email.com';
        prefixIcon = Icons.mail_outline_rounded;
        break;
      case CustomTextFieldType.password:
        label = 'Şifre';
        hintText = '••••••••••••';
        prefixIcon = Icons.lock_outline_rounded;
        break;
      case CustomTextFieldType.passwordRepeat:
        label = 'Şifre Tekrar';
        hintText = '••••••••••••';
        prefixIcon = Icons.lock_outline_rounded;
        break;
      case CustomTextFieldType.search:
        label = ' ';
        hintText = 'Ders, konu veya belge ara';
        prefixIcon = Icons.search_rounded;
        break;
    }

    final primaryPurple = const Color(0xFF5A4EE3);
    final inputBgColor = const Color(0xFFF8F9FD);
    final borderColor = const Color(0xFFE2E8F0);

    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen =
        mediaQuery.size.height < 700 || mediaQuery.size.width < 360;

    final double labelFontSize = isSmallScreen ? 12 : 14;
    final double inputFontSize = isSmallScreen ? 14 : 15;
    final double verticalPadding = isSmallScreen ? 12 : 16;
    final double spacing = isSmallScreen ? 6 : 8;

    final textStyle = TextStyle(
      fontSize: inputFontSize,
      color: const Color(0xFF1E293B),
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label Text
        label == ' '
            ? const SizedBox(height: 0)
            : Text(
                label,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
        label == ' ' ? const SizedBox(height: 0) : SizedBox(height: spacing),
        // Text Field Container
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          onChanged: widget.onChanged,
          textInputAction: widget.textInputAction,
          focusNode: widget.focusNode,
          onFieldSubmitted: widget.onFieldSubmitted,
          obscureText: isPasswordField ? _obscureText : false,
          keyboardType: widget.type == CustomTextFieldType.email
              ? TextInputType.emailAddress
              : TextInputType.text,
          style: textStyle,
          cursorColor: primaryPurple,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: inputFontSize,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: inputBgColor,
            prefixIcon: Icon(
              prefixIcon,
              color: const Color(0xFF94A3B8),
              size: 22,
            ),
            suffixIcon: isPasswordField
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: verticalPadding,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryPurple, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

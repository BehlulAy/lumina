import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double circleSize;
  final double iconSize;
  final double fontSize;

  const AppLogo({
    super.key,
    this.circleSize = 100,
    this.iconSize = 50,
    this.fontSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final logoBgColor = const Color(0xFFDDE0FF);
    final logoColor = const Color(0xFF5A4EE3);
    final textColor = const Color(0xFF0F172A);

    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen =
        mediaQuery.size.height < 700 || mediaQuery.size.width < 360;

    // Dynamically adjust sizes based on screen constraints if default sizes are used
    final effectiveCircleSize = circleSize == 100 && isSmallScreen
        ? 80.0
        : circleSize;
    final effectiveIconSize = iconSize == 50 && isSmallScreen ? 40.0 : iconSize;
    final effectiveFontSize = fontSize == 28 && isSmallScreen ? 24.0 : fontSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Star Icon in a lavender circle
        Container(
          width: effectiveCircleSize,
          height: effectiveCircleSize,
          decoration: BoxDecoration(shape: BoxShape.circle, color: logoBgColor),
          alignment: Alignment.center,
          child: Icon(
            Icons.auto_awesome,
            size: effectiveIconSize,
            color: logoColor,
          ),
        ),
        const SizedBox(height: 12),
        // Logo Text
        Text(
          'Lumina',
          style: TextStyle(
            fontSize: effectiveFontSize,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

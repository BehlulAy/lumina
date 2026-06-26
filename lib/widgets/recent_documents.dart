import 'package:flutter/material.dart';

class RecentDocuments extends StatelessWidget {
  final String text;
  final String date;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String docType;

  const RecentDocuments({
    super.key,
    required this.text,
    required this.date,
    required this.onPressed,
    required this.docType,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Color buttonColor = const Color(0xFFF0F0F0);
    final disabledColor = const Color(0xFFA5A6F6);

    Color iconColor = Colors.white70;
    IconData iconData;

    switch (docType) {
      case "pdf":
        iconColor = const Color(0xFFe05d4b);
        iconData = Icons.picture_as_pdf_rounded;
        break;
      case "text":
        iconColor = const Color(0xFF92b29c);
        iconData = Icons.text_fields_rounded;
        break;
      case "image":
        iconColor = const Color(0xFF5d88b1);
        iconData = Icons.image_rounded;
        break;
      case "docx":
        iconColor = const Color(0xFF2B579A);
        iconData = Icons.description_rounded;
        break;
      default:
        iconColor = const Color(0xFFede8df);
        iconData = Icons.file_copy_rounded;
        break;
    }

    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen =
        mediaQuery.size.height < 700 || mediaQuery.size.width < 360;

    final double buttonHeight = isSmallScreen ? 48.0 : 56.0;
    final double buttonFontSize = isSmallScreen ? 14.0 : 16.0;
    final double paddingVertical = isSmallScreen ? 12.0 : 16.0;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          disabledBackgroundColor: disabledColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: paddingVertical),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(iconData, color: buttonColor),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              text,
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF44413C),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: buttonFontSize - 4,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF44413C),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: const Color(0xFF44413C),
                  ),
                ],
              ),
      ),
    );
  }
}

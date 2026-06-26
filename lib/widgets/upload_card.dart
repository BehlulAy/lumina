import 'package:flutter/material.dart';

/// A premium, interactive card widget used for actions in the Lumina application.
/// It features custom background, border, and icon colors, with a subtle
/// scale animation on tap/press for a modern, tactile feel.
class UploadCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final VoidCallback onTap;

  const UploadCard({
    super.key,
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<UploadCard> createState() => _UploadCardState();
}

class _UploadCardState extends State<UploadCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Micro-interaction: Subtle scale down on tap
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnimation = _animationController;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.reverse(),
      onTapUp: (_) {
        _animationController.forward();
        widget.onTap();
      },
      onTapCancel: () => _animationController.forward(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: widget.borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: widget.iconColor.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Styled Icon Wrapper
              Icon(widget.icon, size: 34, color: widget.iconColor),
              const SizedBox(width: 14),
              // Card Title
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Color(0xFF2D3748), // Deep slate grey for readability
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pre-configured 2x2 grid containing the upload, scan, summarize,
/// and chat cards as requested in the design layout.
class UploadCardsGrid extends StatelessWidget {
  final VoidCallback? onUploadDocument;
  final VoidCallback? onScanNotes;
  final VoidCallback? onSummarize;
  final VoidCallback? onChatWithDocs;

  const UploadCardsGrid({
    super.key,
    this.onUploadDocument,
    this.onScanNotes,
    this.onSummarize,
    this.onChatWithDocs,
  });

  @override
  Widget build(BuildContext context) {
    // Exact colors from the mockup for high fidelity
    final cards = [
      _CardData(
        title: 'Belge\nYükle',
        icon: Icons.upload_file_rounded,
        backgroundColor: const Color(0xFFEDEBF7), // Light lavender
        borderColor: const Color(0xFFDDD9F0),
        iconColor: const Color(0xFF6C5FA7),
        onTap: onUploadDocument ?? () {},
      ),
      _CardData(
        title: 'Belge\nTara',
        icon: Icons.document_scanner_rounded,
        backgroundColor: const Color(0xFFEAF0E9), // Light pastel green
        borderColor: const Color(0xFFD6E6D8),
        iconColor: const Color(0xFF539165),
        onTap: onScanNotes ?? () {},
      ),
      _CardData(
        title: 'Özetle',
        icon: Icons.auto_awesome_rounded, // AI stars / sparkles
        backgroundColor: const Color(0xFFF7ECE6), // Light peach
        borderColor: const Color(0xFFF3E2DA),
        iconColor: const Color(0xFFB78370),
        onTap: onSummarize ?? () {},
      ),
      _CardData(
        title: 'Yapay\nZekaya Sor',
        icon: Icons.chat_bubble_rounded, // Chat speech bubble
        backgroundColor: const Color(0xFFECE7F2), // Light lavender/grey
        borderColor: const Color(0xFFDDD2E8),
        iconColor: const Color(0xFF806CA4),
        onTap: onChatWithDocs ?? () {},
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.45, // Aspect ratio to fit layout in mockup
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return UploadCard(
          title: card.title,
          icon: card.icon,
          backgroundColor: card.backgroundColor,
          borderColor: card.borderColor,
          iconColor: card.iconColor,
          onTap: card.onTap,
        );
      },
    );
  }
}

class _CardData {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final VoidCallback onTap;

  _CardData({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.onTap,
  });
}

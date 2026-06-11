import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

/// Maps a symbol's part of speech to its Colourful Semantics colour. Single
/// source of truth shared by [SymbolTile] and [MiniSymbolTile] so the
/// sentence rail and the grid never drift apart.
Color colourfulSemanticsColor(SymbolCategory category) {
  switch (category) {
    case SymbolCategory.pronoun:
      return AppTheme.categoryPronoun; // Orange — Who?
    case SymbolCategory.verb:
      return AppTheme.categoryVerb; // Yellow — Doing?
    case SymbolCategory.activity:
      return AppTheme.categoryActivity; // Yellow — Doing?
    case SymbolCategory.noun:
      return AppTheme.categoryNoun; // Green — What?
    case SymbolCategory.food:
      return AppTheme.categoryFood; // Green — What?
    case SymbolCategory.place:
      return AppTheme.categoryPlace; // Blue — Where?
    case SymbolCategory.preposition:
      return AppTheme.categoryPreposition; // Blue — Where?
    case SymbolCategory.adjective:
      return AppTheme.categoryAdjective; // White — What kind?
    case SymbolCategory.feeling:
      return AppTheme.categoryFeeling; // White — What kind?
    case SymbolCategory.question:
      return AppTheme.categoryQuestion; // Purple — not a core CS role
    case SymbolCategory.folder:
      return AppTheme.categoryFolder; // Teal — organisational, not CS
  }
}

class SymbolTile extends StatelessWidget {
  final Symbol symbol;
  final VoidCallback onTap;
  final bool isSelected;
  final double size;
  final String? pictogramKeyword;
  final int labelMaxLines;
  final double labelFontSizeDelta;

  final Color? overrideBackgroundColor;

  const SymbolTile({
    super.key,
    required this.symbol,
    required this.onTap,
    this.isSelected = false,
    this.size = 100, // Kept for backwards compatibility but ignored by GridView
    this.pictogramKeyword,
    this.labelMaxLines = 1,
    this.labelFontSizeDelta = 0,
    this.overrideBackgroundColor,
  });

  Color get categoryColor => overrideBackgroundColor ?? colourfulSemanticsColor(symbol.category);

  @override
  Widget build(BuildContext context) {
    final searchWord = (pictogramKeyword ?? symbol.label)
        .split('/')[0]
        .replaceAll('?', '')
        .replaceAll("'", '')
        .replaceAll(' ', '_')
        .toLowerCase()
        .trim();
    final path = searchWord == "dont_like"
        ? 'assets/arasaac/dislike.png'
        : 'assets/arasaac/$searchWord.png';

    // High Contrast mode keeps the Colourful Semantics fill EXACTLY as-is and
    // instead strengthens the outline/label ink: black or white (whichever
    // contrasts the fill most), with a bright cyan ring for selection so the
    // selected state never depends on a subtle glow.
    final bool hc = AppTheme.isHighContrast;
    final Color ink = AppTheme.onColor(categoryColor);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: categoryColor,
          borderRadius: BorderRadius.circular(6), // iPad style slightly rounded
          border: Border.all(
            color: isSelected
                ? (hc ? AppTheme.focusHighlight : Colors.white)
                : (hc ? ink : Colors.black87),
            width: isSelected ? (hc ? 4 : 3) : (hc ? 3 : 1),
          ),
          // The translucent glow is a low-contrast cue — disabled in High
          // Contrast, where the thick cyan ring carries the selected state.
          boxShadow: isSelected && !hc
              ? [
                  BoxShadow(
                    color: categoryColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  final labelFontSize = ((w * 0.16) + labelFontSizeDelta)
                      .clamp(10.0, 18.0)
                      .toDouble();
                  final iconSize = (h * 0.42).clamp(18.0, 56.0).toDouble();
                  final labelBoxHeight = (h * 0.28)
                      .clamp(16.0, 30.0)
                      .toDouble();

                  final imageWidget = symbol.imageUrl != null
                      ? Image.network(
                          symbol.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            symbol.icon ?? Icons.help_outline,
                            size: iconSize,
                            color: hc ? ink : Colors.black54,
                          ),
                        )
                      : Image.asset(
                          path,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            symbol.icon ?? Icons.help_outline,
                            size: iconSize,
                            color: hc ? ink : Colors.black54,
                          ),
                        );

                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(
                        (h * 0.05).clamp(4.0, 8.0).toDouble(),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: labelBoxHeight,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Text(
                                    symbol.label,
                                    style: TextStyle(
                                      // Full-strength contrast-matched ink in
                                      // High Contrast; original look otherwise.
                                      color: hc ? ink : Colors.black87,
                                      fontSize: labelFontSize,
                                      fontWeight:
                                          hc ? FontWeight.w700 : FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: labelMaxLines,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: (h * 0.03).clamp(2.0, 4.0).toDouble(),
                          ),
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: iconSize,
                                    height: iconSize,
                                    child: imageWidget,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // If it's a folder, show a black folded corner on top right
              if (symbol.isFolder)
                Positioned(
                  top: 0,
                  right: 0,
                  child: CustomPaint(
                    size: const Size(20, 20),
                    painter: FoldedCornerPainter(),
                  ),
                ),

              // If it's 'not', show a red slash
              if (symbol.id == 'not')
                Positioned.fill(child: CustomPaint(painter: RedSlashPainter())),
            ],
          ),
        ),
      ),
    );
  }
}

class FoldedCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RedSlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Draw from top-left to bottom-right
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniSymbolTile extends StatelessWidget {
  final Symbol symbol;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool isExpanded; // Added flag to scale dynamically
  final double? iconSize; // Override icon size directly

  const MiniSymbolTile({
    super.key,
    required this.symbol,
    this.onTap,
    this.onRemove,
    this.isExpanded = false, // Defaults to false so your existing code doesn't break
    this.iconSize,
  });

  Color get categoryColor => colourfulSemanticsColor(symbol.category);

  @override
  Widget build(BuildContext context) {
    final searchWord = symbol.label
        .split('/')[0]
        .replaceAll('?', '')
        .replaceAll("'", "")
        .replaceAll(" ", "_")
        .toLowerCase()
        .trim();
    final path = searchWord == "dont_like"
        ? 'assets/arasaac/dislike.png'
        : 'assets/arasaac/$searchWord.png';

    final imageWidget = symbol.imageUrl != null
        ? Image.network(
            symbol.imageUrl!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              symbol.icon ?? Icons.help_outline,
              size: isExpanded ? 32 : 16, // Scale fallback icon size
              color: AppTheme.isHighContrast ? Colors.black : Colors.black87,
            ),
          )
        : Image.asset(
            path,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              symbol.icon ?? Icons.help_outline,
              size: isExpanded ? 32 : 16, // Scale fallback icon size
              color: AppTheme.isHighContrast ? Colors.black : Colors.black87,
            ),
          );

    final double finalIconSize = iconSize ?? (isExpanded ? 40 : 24);

    // Same High Contrast treatment as SymbolTile: keep the semantic fill,
    // strengthen the outline and label ink only.
    final bool hc = AppTheme.isHighContrast;
    final Color ink = AppTheme.onColor(categoryColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Dynamic padding matches layout requirements
        padding: EdgeInsets.symmetric(
          horizontal: isExpanded ? 14 : 12,
          vertical: isExpanded ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: categoryColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hc ? ink : Colors.black87,
            width: hc ? 2.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container scales completely up when expanded is toggled
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: finalIconSize,
              height: finalIconSize,
              decoration: BoxDecoration(
                // Translucent plate reads as washed-out in High Contrast —
                // use a solid plate there so the pictogram stays crisp.
                color: hc ? Colors.white : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: isExpanded || iconSize != null
                    ? imageWidget
                    : Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: imageWidget,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              symbol.label,
              style: TextStyle(
                color: hc ? ink : Colors.black87,
                fontSize: iconSize != null
                    ? (iconSize! * 0.45).clamp(12.0, 18.0) // Scale text with custom icon size
                    : (isExpanded ? 16 : 14), // Slightly boosted text visibility
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close, size: 16, color: hc ? ink : Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

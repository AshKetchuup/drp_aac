import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class SymbolTile extends StatelessWidget {
  final Symbol symbol;
  final VoidCallback onTap;
  final bool isSelected;
  final double size;

  const SymbolTile({
    super.key,
    required this.symbol,
    required this.onTap,
    this.isSelected = false,
    this.size = 100, // Kept for backwards compatibility but ignored by GridView
  });

  Color get categoryColor {
    switch (symbol.category) {
      case SymbolCategory.pronoun:
        return AppTheme.categoryPronoun;
      case SymbolCategory.verb:
        return AppTheme.categoryVerb;
      case SymbolCategory.noun:
        return AppTheme.categoryNoun;
      case SymbolCategory.adjective:
        return AppTheme.categoryAdjective;
      case SymbolCategory.activity:
        return AppTheme.categoryActivity;
      case SymbolCategory.food:
        return AppTheme.categoryFood;
      case SymbolCategory.feeling:
        return AppTheme.categoryFolder; // Use folder color for feelings as requested
      case SymbolCategory.place:
        return AppTheme.categoryFolder;
      case SymbolCategory.question:
        return AppTheme.categoryQuestion;
      case SymbolCategory.preposition:
        return AppTheme.categoryPreposition;
      case SymbolCategory.folder:
        return AppTheme.categoryFolder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchWord = symbol.label.split('/')[0].replaceAll('?', '').replaceAll("'", "").replaceAll(" ", "_").toLowerCase().trim();
    final path = searchWord == "dont_like" ? 'assets/arasaac/dislike.png' : 'assets/arasaac/$searchWord.png';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: categoryColor,
          borderRadius: BorderRadius.circular(6), // iPad style slightly rounded
          border: Border.all(
            color: isSelected ? Colors.white : Colors.black87,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.5),
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
                  
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start, // Top aligned
                    children: [
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          symbol.label,
                          style: TextStyle(
                            color: Colors.black87, // Black text on colored background
                            fontSize: w * 0.16, // Proportional font size
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: symbol.imageUrl != null 
                              ? Image.network(
                                  symbol.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    symbol.icon ?? Icons.help_outline,
                                    size: w * 0.4,
                                    color: Colors.black54,
                                  ),
                                )
                              : Image.asset(
                                  path,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    symbol.icon ?? Icons.help_outline,
                                    size: w * 0.4,
                                    color: Colors.black54,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
                Positioned.fill(
                  child: CustomPaint(
                    painter: RedSlashPainter(),
                  ),
                ),
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

  const MiniSymbolTile({
    super.key,
    required this.symbol,
    this.onTap,
    this.onRemove,
  });

  Color get categoryColor {
    switch (symbol.category) {
      case SymbolCategory.pronoun:
        return AppTheme.categoryPronoun;
      case SymbolCategory.verb:
        return AppTheme.categoryVerb;
      case SymbolCategory.noun:
        return AppTheme.categoryNoun;
      case SymbolCategory.adjective:
        return AppTheme.categoryAdjective;
      case SymbolCategory.activity:
        return AppTheme.categoryActivity;
      case SymbolCategory.food:
        return AppTheme.categoryFood;
      case SymbolCategory.feeling:
        return AppTheme.categoryFolder;
      case SymbolCategory.place:
        return AppTheme.categoryFolder;
      case SymbolCategory.question:
        return AppTheme.categoryQuestion;
      case SymbolCategory.preposition:
        return AppTheme.categoryPreposition;
      case SymbolCategory.folder:
        return AppTheme.categoryFolder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchWord = symbol.label.split('/')[0].replaceAll('?', '').replaceAll("'", "").replaceAll(" ", "_").toLowerCase().trim();
    final path = searchWord == "dont_like" ? 'assets/arasaac/dislike.png' : 'assets/arasaac/$searchWord.png';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: categoryColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black87),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: symbol.imageUrl != null 
                    ? Image.network(
                        symbol.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          symbol.icon ?? Icons.help_outline,
                          size: 16,
                          color: Colors.black87,
                        ),
                      )
                    : Image.asset(
                        path,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          symbol.icon ?? Icons.help_outline,
                          size: 16,
                          color: Colors.black87,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              symbol.label,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


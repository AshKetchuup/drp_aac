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
    this.size = 100,
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
        return AppTheme.secondary;
      case SymbolCategory.place:
        return AppTheme.primary;
      case SymbolCategory.question:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected 
              ? categoryColor.withOpacity(0.3) 
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? categoryColor : AppTheme.border,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                symbol.icon,
                size: size * 0.3,
                color: categoryColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                symbol.label,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
        return AppTheme.secondary;
      case SymbolCategory.place:
        return AppTheme.primary;
      case SymbolCategory.question:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: categoryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: categoryColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(symbol.icon, size: 20, color: categoryColor),
            const SizedBox(width: 6),
            Text(
              symbol.label,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

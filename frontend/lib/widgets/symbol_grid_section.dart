import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'symbol_tile.dart';

class SymbolGridSection extends StatelessWidget {
  final String title;
  final List<Symbol> items;
  final void Function(String) onTap;
  final Map<String, Color>? overrideItemColors;

  const SymbolGridSection({
    super.key,
    required this.title,
    required this.items,
    required this.onTap,
    this.overrideItemColors,
  });

  int _crossAxisCount(int count) {
    if (count <= 2) return 1;
    if (count <= 4) return 2;
    if (count <= 6) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final columns = _crossAxisCount(items.length);
    final rows = (items.length / columns).ceil();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;

                final cellByWidth =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                    columns;
                final cellByHeight =
                    (constraints.maxHeight - (spacing * (rows - 1))) / rows;
                final cellSize = cellByWidth < cellByHeight
                    ? cellByWidth
                    : cellByHeight;

                final gridWidth =
                    (cellSize * columns) + (spacing * (columns - 1));
                final gridHeight = (cellSize * rows) + (spacing * (rows - 1));

                return Center(
                  child: SizedBox(
                    width: gridWidth,
                    height: gridHeight,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        childAspectRatio: 1,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final symbol = items[index];
                        return SymbolTile(
                          symbol: symbol,
                          onTap: () => onTap(symbol.label),
                          overrideBackgroundColor: overrideItemColors?[symbol.id],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

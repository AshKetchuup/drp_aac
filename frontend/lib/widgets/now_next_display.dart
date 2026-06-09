// lib/widgets/now_next_display.dart
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'symbol_tile.dart';

class NowNextDisplay extends StatelessWidget {
  final Symbol? now;
  final Symbol? next;

  const NowNextDisplay({
    super.key,
    required this.now,
    required this.next,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: _StaticDisplayZone(
                label: 'NOW',
                labelColor: const Color(0xFF2196F3),
                symbol: now,
              ),
            ),
            const SizedBox(width: 16),

            // Middle Arrow Indicator
            Icon(
              Icons.arrow_forward_rounded,
              size: 44,
              color: AppTheme.textSecondary.withValues(alpha: 0.6),
            ),

            const SizedBox(width: 16),
            Expanded(
              child: _StaticDisplayZone(
                label: 'NEXT',
                labelColor: const Color(0xFF4CAF50),
                symbol: next,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StaticDisplayZone extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Symbol? symbol;

  const _StaticDisplayZone({
    required this.label,
    required this.labelColor,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.border,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: labelColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: labelColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: symbol == null
                ? Center(
                    child: Text(
                      'No Activity Scheduled',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: SymbolTile(
                      symbol: symbol!,
                      onTap: () {}, // Display only, tap interaction deactivated
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/aac_provider.dart';
import '../models/models.dart';
import 'symbol_tile.dart';

class SentenceRail extends StatelessWidget {
  final VoidCallback onSpeak;
  final VoidCallback onClear;

  const SentenceRail({
    super.key,
    required this.onSpeak,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AACProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              bottom: BorderSide(color: AppTheme.border),
            ),
          ),
          child: Row(
            children: [
              // Sentence display area
              Expanded(
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: provider.sentenceBuilder.isEmpty
                      ? Center(
                          child: Text(
                            'Tap symbols to build a sentence...',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: provider.sentenceBuilder.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final symbol = provider.sentenceBuilder[index];
                            return MiniSymbolTile(
                              symbol: symbol,
                              onRemove: () => provider.removeFromSentence(index),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Clear button
              _ActionButton(
                icon: Icons.backspace_outlined,
                label: 'Clear',
                onTap: onClear,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              // Speak button
              _ActionButton(
                icon: Icons.volume_up_rounded,
                label: 'Speak',
                onTap: onSpeak,
                color: AppTheme.primary,
                isPrimary: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isPrimary ? AppTheme.background : color,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? AppTheme.background : color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

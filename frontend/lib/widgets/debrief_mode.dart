import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'sentence_rail.dart';
import 'symbol_tile.dart';

class DebriefMode extends StatelessWidget {
  final VoidCallback onExit;
  final Function(Symbol) onSymbolTap;
  final Function(String) onEmotionTap;
  final VoidCallback onSpeak;
  final VoidCallback onClear;

  const DebriefMode({
    super.key,
    required this.onExit,
    required this.onSymbolTap,
    required this.onEmotionTap,
    required this.onSpeak,
    required this.onClear,
  });

  static final List<_CalmingSymbol> _firstColumn = [
    _CalmingSymbol(
      'I felt',
      'feel',
      SymbolCategory.feeling,
      Icons.sentiment_satisfied,
    ),
    _CalmingSymbol(
      'It was',
      'was',
      SymbolCategory.feeling,
      Icons.sentiment_satisfied,
    ),
    _CalmingSymbol('Too loud', 'loud', SymbolCategory.feeling, Icons.volume_up),
    _CalmingSymbol('Too busy', 'busy', SymbolCategory.feeling, Icons.groups),
    _CalmingSymbol('Too hot', 'hot', SymbolCategory.feeling, Icons.thermostat),
    _CalmingSymbol(
      'Overwhelmed',
      'overwhelmed',
      SymbolCategory.feeling,
      Icons.psychology,
    ),
  ];

  static final List<_CalmingSymbol> _secondColumn = [
    _CalmingSymbol(
      'Confused',
      'confused',
      SymbolCategory.feeling,
      Icons.help_outline,
    ),
    _CalmingSymbol(
      'Frustrated',
      'angry',
      SymbolCategory.feeling,
      Icons.mood_bad,
    ),
    _CalmingSymbol(
      'Surprised',
      'surprised',
      SymbolCategory.feeling,
      Icons.priority_high,
    ),
    _CalmingSymbol('In pain', 'pain', SymbolCategory.feeling, Icons.healing),
    _CalmingSymbol(
      'Hungry',
      'hungry',
      SymbolCategory.feeling,
      Icons.restaurant,
    ),
    _CalmingSymbol('Tired', 'tired', SymbolCategory.feeling, Icons.bedtime),
  ];

  static final List<_CalmingSymbol> _thirdColumn = [
    _CalmingSymbol('At school', 'school', SymbolCategory.noun, Icons.school),
    _CalmingSymbol('At home', 'home', SymbolCategory.noun, Icons.home),
    _CalmingSymbol('At the park', 'park', SymbolCategory.activity, Icons.park),
    _CalmingSymbol('At the shop', 'shop', SymbolCategory.activity, Icons.shop),
    _CalmingSymbol(
      'Outside',
      'outdoors',
      SymbolCategory.activity,
      Icons.forest,
    ),
    _CalmingSymbol('Inside', 'inside', SymbolCategory.activity, Icons.pool),
  ];

  static final List<_EmotionChip> _emotions = [
    _EmotionChip('😊', 'Happy'),
    _EmotionChip('😢', 'Sad'),
    _EmotionChip('😡', 'Angry'),
    _EmotionChip('😰', 'Scared'),
    _EmotionChip('😵', 'Overwhelmed'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final railHeight = (constraints.maxHeight * 0.16)
            .clamp(144.0, 176.0)
            .toDouble();
        final emotionHeight = (constraints.maxHeight * 0.11)
            .clamp(76.0, 92.0)
            .toDouble();

        return Material(
          color: AppTheme.background,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Header(onExit: onExit),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: railHeight,
                    child: SentenceRail(
                      onSpeak: onSpeak,
                      onClear: onClear,
                      height: railHeight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: emotionHeight,
                    child: _EmotionStrip(
                      emotions: _emotions,
                      onEmotionTap: onEmotionTap,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _VerticalTileColumn(
                            tiles: _firstColumn,
                            onTap: onSymbolTap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _VerticalTileColumn(
                            tiles: _secondColumn,
                            onTap: onSymbolTap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _VerticalTileColumn(
                            tiles: _thirdColumn,
                            onTap: onSymbolTap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── private widgets & data classes — identical to CalmingMode ─────────────────

class _Header extends StatelessWidget {
  final VoidCallback onExit;
  const _Header({required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: AppTheme.textSecondary, size: 18),
                SizedBox(width: 6),
                Text(
                  'Back',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.secondary, // blue dot instead of yellow
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Debriefing Mode',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onExit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                SizedBox(width: 6),
                Text(
                  'Exit',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmotionStrip extends StatelessWidget {
  final List<_EmotionChip> emotions;
  final Function(String) onEmotionTap;
  const _EmotionStrip({required this.emotions, required this.onEmotionTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 132,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.isHighContrast
                  ? AppTheme.surfaceLight
                  : AppTheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.isHighContrast
                    ? AppTheme.secondary
                    : AppTheme.secondary.withValues(alpha: 0.6),
              ),
            ),
            child: const Text(
              'I was feeling',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.secondary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: emotions
                  .map(
                    (emotion) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => onEmotionTap(emotion.label),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Center(
                            child: Text(
                              emotion.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalTileColumn extends StatelessWidget {
  final List<_CalmingSymbol> tiles;
  final Function(Symbol) onTap;
  const _VerticalTileColumn({required this.tiles, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < tiles.length; index++) ...[
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: index == tiles.length - 1 ? 0 : 8,
                ),
                child: SymbolTile(
                  symbol: tiles[index].symbol,
                  onTap: () => onTap(tiles[index].symbol),
                  pictogramKeyword: tiles[index].pictogramKeyword,
                  labelMaxLines: 2,
                  labelFontSizeDelta: -4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalmingSymbol {
  final String label;
  final String pictogramKeyword;
  final Symbol symbol;

  _CalmingSymbol(
    this.label,
    this.pictogramKeyword,
    SymbolCategory category,
    IconData fallbackIcon,
  ) : symbol = Symbol(
        id: label.toLowerCase().replaceAll(' ', '_'),
        label: label,
        category: category,
        icon: fallbackIcon,
      );
}

class _EmotionChip {
  final String emoji;
  final String label;
  const _EmotionChip(this.emoji, this.label);
}

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'sentence_rail.dart';
import 'symbol_tile.dart';

class CalmingMode extends StatelessWidget {
  final VoidCallback onExit;
  final Function(Symbol) onSymbolTap;
  final Function(String) onEmotionTap;
  final VoidCallback onSpeak;
  final VoidCallback onClear;

  const CalmingMode({
    super.key,
    required this.onExit,
    required this.onSymbolTap,
    required this.onEmotionTap,
    required this.onSpeak,
    required this.onClear,
  });

  static final List<_CalmingSymbol> _firstColumn = [
    _CalmingSymbol('I want', 'want', SymbolCategory.verb, Icons.favorite),
    _CalmingSymbol('I need', 'need', SymbolCategory.verb, Icons.priority_high),
    _CalmingSymbol('I have', 'feel', SymbolCategory.verb, Icons.sentiment_satisfied),
    _CalmingSymbol('I miss', 'miss', SymbolCategory.feeling, Icons.person),
    _CalmingSymbol('Will you', 'ask', SymbolCategory.question, Icons.question_answer),
  ];

  static final List<_CalmingSymbol> _secondColumn = [
    _CalmingSymbol('to eat', 'eat', SymbolCategory.verb, Icons.restaurant),
    _CalmingSymbol('to drink', 'drink', SymbolCategory.verb, Icons.local_drink),
    _CalmingSymbol('to go', 'go', SymbolCategory.verb, Icons.directions_walk),
    _CalmingSymbol('to leave', 'leave', SymbolCategory.verb, Icons.exit_to_app),
    _CalmingSymbol('to help', 'help', SymbolCategory.verb, Icons.help),
    _CalmingSymbol('to give', 'give', SymbolCategory.verb, Icons.card_giftcard),

  ];

  static final List<_CalmingSymbol> _thirdColumn = [
    _CalmingSymbol('School', 'school', SymbolCategory.noun, Icons.school),
    _CalmingSymbol('Home', 'home', SymbolCategory.noun, Icons.home),
    _CalmingSymbol('Park', 'park', SymbolCategory.activity, Icons.park),
    _CalmingSymbol('Shop', 'shop', SymbolCategory.activity, Icons.shop),
    _CalmingSymbol('Swimming', 'swimming', SymbolCategory.activity, Icons.pool),
    _CalmingSymbol('Outside', 'garden', SymbolCategory.activity, Icons.forest),
  ];

  static final List<_CalmingSymbol> _specificPhrases = [
    _CalmingSymbol('Help me', 'help', SymbolCategory.verb, Icons.help),
    _CalmingSymbol('I need a break', 'rest', SymbolCategory.verb, Icons.spa),
    _CalmingSymbol('Too loud', 'quiet', SymbolCategory.feeling, Icons.volume_off),
    _CalmingSymbol('Want quiet', 'quiet', SymbolCategory.feeling, Icons.volume_off),
  ];

  static final List<_CalmingSymbol> _simpleTiles = [
    _CalmingSymbol('Yes', 'yes', SymbolCategory.question, Icons.check_circle),
    _CalmingSymbol('No', 'no', SymbolCategory.question, Icons.cancel),
    _CalmingSymbol('More', 'more', SymbolCategory.adjective, Icons.add_circle),
    _CalmingSymbol('Stop', 'stop', SymbolCategory.verb, Icons.stop_circle),
  ];

  static final List<_EmotionChip> _emotions = [
    _EmotionChip('😊', 'Happy'),
    _EmotionChip('😢', 'Sad'),
    _EmotionChip('😡', 'Angry'),
    _EmotionChip('😴', 'Tired'),
    _EmotionChip('😌', 'Calm'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final railHeight = (constraints.maxHeight * 0.16).clamp(144.0, 176.0).toDouble();
        final emotionHeight = (constraints.maxHeight * 0.11).clamp(76.0, 92.0).toDouble();

        return Container(
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Expanded(child: _VerticalTileColumn(tiles: _firstColumn, onTap: onSymbolTap)),
                              const SizedBox(width: 8),
                              Expanded(child: _VerticalTileColumn(tiles: _secondColumn, onTap: onSymbolTap)),
                              const SizedBox(width: 8),
                              Expanded(child: _VerticalTileColumn(tiles: _thirdColumn, onTap: onSymbolTap)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              Expanded(
                                child: _TilePanel(
                                  title: 'My phrases',
                                  tiles: _specificPhrases,
                                  onTap: onSymbolTap,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _TilePanel(
                                  title: 'Responses',
                                  tiles: _simpleTiles,
                                  onTap: onSymbolTap,
                                ),
                              ),
                            ],
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

class _Header extends StatelessWidget {
  final VoidCallback onExit;

  const _Header({required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
                  color: AppTheme.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Calming Mode',
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
                const SizedBox(width: 6),
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

  const _EmotionStrip({
    required this.emotions,
    required this.onEmotionTap,
  });

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
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6)),
            ),
            child: Text(
              'I am feeling',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
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

  const _VerticalTileColumn({
    required this.tiles,
    required this.onTap,
  });

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
                padding: EdgeInsets.only(bottom: index == tiles.length - 1 ? 0 : 8),
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

class _TilePanel extends StatelessWidget {
  final String title;
  final List<_CalmingSymbol> tiles;
  final Function(Symbol) onTap;

  const _TilePanel({
    required this.title,
    required this.tiles,
    required this.onTap,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.88,
              ),
              itemCount: tiles.length,
              itemBuilder: (context, index) {
                final tile = tiles[index];
                return SymbolTile(
                  symbol: tile.symbol,
                  onTap: () => onTap(tile.symbol),
                  pictogramKeyword: tile.pictogramKeyword,
                  labelMaxLines: 2,
                  labelFontSizeDelta: -4,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalmingSymbol {
  final String label;
  final String pictogramKeyword;
  final Symbol symbol;

  _CalmingSymbol(this.label, this.pictogramKeyword, SymbolCategory category, IconData fallbackIcon)
      : symbol = Symbol(
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
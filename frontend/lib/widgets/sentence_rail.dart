import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/aac_provider.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          color: Colors.black, // Dark background
          height: 100, // Fixed height for rail
          child: Row(
            children: [
              // Magic wand button
              _IconButton(
                icon: Icons.auto_fix_high,
                color: Colors.blueGrey,
                onTap: () {},
              ),
              const SizedBox(width: 4),
              // Undo/Backspace (Word level)
              _IconButton(
                icon: Icons.keyboard_backspace,
                color: Colors.blueGrey,
                onTap: () {
                  if (provider.sentenceBuilder.isNotEmpty) {
                    provider.removeFromSentence(provider.sentenceBuilder.length - 1);
                  }
                },
              ),
              const SizedBox(width: 4),
              
              // Sentence display area
              Expanded(
                child: GestureDetector(
                  onTap: onSpeak, // Keep tap text area to speak as fallback
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: provider.sentenceBuilder.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 4),
                      itemBuilder: (context, index) {
                        final symbol = provider.sentenceBuilder[index];
                        return MiniSymbolTile(
                          symbol: symbol,
                          onRemove: null,
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 4),
              // Dedicated SPEAK Button (User requested)
              GestureDetector(
                onTap: onSpeak,
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue, // Make it stand out
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.volume_up, color: Colors.white, size: 32),
                      Text('Speak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              
              // Delete word button
              _IconButton(
                icon: Icons.backspace,
                color: Colors.blueGrey,
                onTap: () {
                  if (provider.sentenceBuilder.isNotEmpty) {
                    provider.removeFromSentence(provider.sentenceBuilder.length - 1);
                  }
                },
              ),
              const SizedBox(width: 4),
              // Clear All button
              _IconButton(
                icon: Icons.delete,
                color: Colors.blueGrey,
                onTap: onClear,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _IconButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black87, width: 1),
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}

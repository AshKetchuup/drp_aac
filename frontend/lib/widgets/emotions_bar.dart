import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmotionsBar extends StatelessWidget {
  final Function(String) onTap;

  const EmotionsBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hc = AppTheme.isHighContrast;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: hc ? Colors.black : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: hc ? Colors.white : Colors.black87,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Emotion',
                style: TextStyle(
                  color: hc ? Colors.white : Colors.teal,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              _EmojiBtn(emoji: '😲', onTap: () => onTap('Surprised!')),
              const SizedBox(width: 8),
              _EmojiBtn(emoji: '😢', onTap: () => onTap('Sad')),
              const SizedBox(width: 8),
              _EmojiBtn(emoji: '😡', onTap: () => onTap('Angry')),
              const SizedBox(width: 8),
              _EmojiBtn(emoji: '😂', onTap: () => onTap('Funny')),
              const SizedBox(width: 8),
              _EmojiBtn(emoji: '😊', onTap: () => onTap('Happy')),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmojiBtn extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _EmojiBtn({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black87, width: 2),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SmartSuggestions extends StatelessWidget {
  final Function(String) onSuggestionTap;
  final List<String>? customSuggestions;

  const SmartSuggestions({
    super.key,
    required this.onSuggestionTap,
    this.customSuggestions,
  });

  static const List<Map<String, dynamic>> defaultSuggestions = [
    {'text': 'I want to play Minecraft', 'icon': Icons.grid_view},
    {'text': 'Can I have a snack?', 'icon': Icons.fastfood},
    {'text': 'I need a break', 'icon': Icons.pause_circle},
    {'text': 'Let me play Roblox', 'icon': Icons.videogame_asset},
    {'text': 'I feel tired', 'icon': Icons.bedtime},
    {'text': 'Can I watch YouTube?', 'icon': Icons.play_circle},
  ];

  @override
  Widget build(BuildContext context) {
    final suggestions = customSuggestions ?? 
        defaultSuggestions.map((s) => s['text'] as String).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 18,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Phrases',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: defaultSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final suggestion = defaultSuggestions[index];
                return GestureDetector(
                  onTap: () => onSuggestionTap(suggestion['text'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          suggestion['icon'] as IconData,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          suggestion['text'] as String,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

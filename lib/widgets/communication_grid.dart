import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'symbol_tile.dart';

class CommunicationGrid extends StatelessWidget {
  final Function(Symbol) onSymbolTap;
  final String? activeCategory;
  final Function(String?) onCategoryChange;

  const CommunicationGrid({
    super.key,
    required this.onSymbolTap,
    this.activeCategory,
    required this.onCategoryChange,
  });

  static final List<Symbol> symbols = [
    // Pronouns
    Symbol(id: 'i', label: 'I', icon: Icons.person, category: SymbolCategory.pronoun),
    Symbol(id: 'you', label: 'You', icon: Icons.person_outline, category: SymbolCategory.pronoun),
    Symbol(id: 'we', label: 'We', icon: Icons.people, category: SymbolCategory.pronoun),
    Symbol(id: 'they', label: 'They', icon: Icons.people_outline, category: SymbolCategory.pronoun),
    
    // Verbs
    Symbol(id: 'want', label: 'Want', icon: Icons.favorite, category: SymbolCategory.verb),
    Symbol(id: 'need', label: 'Need', icon: Icons.priority_high, category: SymbolCategory.verb),
    Symbol(id: 'like', label: 'Like', icon: Icons.thumb_up, category: SymbolCategory.verb),
    Symbol(id: 'dont_like', label: "Don't Like", icon: Icons.thumb_down, category: SymbolCategory.verb),
    Symbol(id: 'go', label: 'Go', icon: Icons.directions_walk, category: SymbolCategory.verb),
    Symbol(id: 'play', label: 'Play', icon: Icons.sports_esports, category: SymbolCategory.verb),
    Symbol(id: 'eat', label: 'Eat', icon: Icons.restaurant, category: SymbolCategory.verb),
    Symbol(id: 'drink', label: 'Drink', icon: Icons.local_drink, category: SymbolCategory.verb),
    Symbol(id: 'see', label: 'See', icon: Icons.visibility, category: SymbolCategory.verb),
    Symbol(id: 'help', label: 'Help', icon: Icons.help, category: SymbolCategory.verb),
    
    // Nouns
    Symbol(id: 'food', label: 'Food', icon: Icons.fastfood, category: SymbolCategory.noun),
    Symbol(id: 'water', label: 'Water', icon: Icons.water_drop, category: SymbolCategory.noun),
    Symbol(id: 'home', label: 'Home', icon: Icons.home, category: SymbolCategory.noun),
    Symbol(id: 'school', label: 'School', icon: Icons.school, category: SymbolCategory.noun),
    Symbol(id: 'bathroom', label: 'Bathroom', icon: Icons.wc, category: SymbolCategory.noun),
    Symbol(id: 'outside', label: 'Outside', icon: Icons.park, category: SymbolCategory.noun),
    
    // Activities
    Symbol(id: 'minecraft', label: 'Minecraft', icon: Icons.grid_view, category: SymbolCategory.activity),
    Symbol(id: 'roblox', label: 'Roblox', icon: Icons.videogame_asset, category: SymbolCategory.activity),
    Symbol(id: 'youtube', label: 'YouTube', icon: Icons.play_circle, category: SymbolCategory.activity),
    Symbol(id: 'tablet', label: 'Tablet', icon: Icons.tablet, category: SymbolCategory.activity),
    Symbol(id: 'music', label: 'Music', icon: Icons.music_note, category: SymbolCategory.activity),
    Symbol(id: 'drawing', label: 'Drawing', icon: Icons.brush, category: SymbolCategory.activity),
    
    // Feelings
    Symbol(id: 'happy', label: 'Happy', icon: Icons.sentiment_very_satisfied, category: SymbolCategory.feeling),
    Symbol(id: 'sad', label: 'Sad', icon: Icons.sentiment_dissatisfied, category: SymbolCategory.feeling),
    Symbol(id: 'angry', label: 'Angry', icon: Icons.sentiment_very_dissatisfied, category: SymbolCategory.feeling),
    Symbol(id: 'tired', label: 'Tired', icon: Icons.bedtime, category: SymbolCategory.feeling),
    Symbol(id: 'scared', label: 'Scared', icon: Icons.warning, category: SymbolCategory.feeling),
    Symbol(id: 'calm', label: 'Calm', icon: Icons.self_improvement, category: SymbolCategory.feeling),
    
    // Questions
    Symbol(id: 'what', label: 'What?', icon: Icons.help_outline, category: SymbolCategory.question),
    Symbol(id: 'where', label: 'Where?', icon: Icons.place, category: SymbolCategory.question),
    Symbol(id: 'when', label: 'When?', icon: Icons.access_time, category: SymbolCategory.question),
    Symbol(id: 'why', label: 'Why?', icon: Icons.psychology, category: SymbolCategory.question),
  ];

  static const List<Map<String, dynamic>> categories = [
    {'id': null, 'label': 'All', 'icon': Icons.apps, 'color': AppTheme.textSecondary},
    {'id': 'pronoun', 'label': 'Pronouns', 'icon': Icons.person, 'color': AppTheme.categoryPronoun},
    {'id': 'verb', 'label': 'Verbs', 'icon': Icons.directions_run, 'color': AppTheme.categoryVerb},
    {'id': 'noun', 'label': 'Nouns', 'icon': Icons.category, 'color': AppTheme.categoryNoun},
    {'id': 'activity', 'label': 'Activities', 'icon': Icons.sports_esports, 'color': AppTheme.categoryActivity},
    {'id': 'feeling', 'label': 'Feelings', 'icon': Icons.mood, 'color': AppTheme.secondary},
    {'id': 'question', 'label': 'Questions', 'icon': Icons.help, 'color': AppTheme.warning},
  ];

  List<Symbol> get filteredSymbols {
    if (activeCategory == null) return symbols;
    return symbols.where((s) {
      switch (activeCategory) {
        case 'pronoun':
          return s.category == SymbolCategory.pronoun;
        case 'verb':
          return s.category == SymbolCategory.verb;
        case 'noun':
          return s.category == SymbolCategory.noun;
        case 'activity':
          return s.category == SymbolCategory.activity;
        case 'feeling':
          return s.category == SymbolCategory.feeling;
        case 'question':
          return s.category == SymbolCategory.question;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category tabs
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isActive = activeCategory == category['id'];
              return GestureDetector(
                onTap: () => onCategoryChange(category['id']),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? (category['color'] as Color).withOpacity(0.2)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive 
                          ? category['color'] as Color
                          : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        category['icon'] as IconData,
                        size: 20,
                        color: isActive 
                            ? category['color'] as Color
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category['label'] as String,
                        style: TextStyle(
                          color: isActive 
                              ? category['color'] as Color
                              : AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Symbol grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: filteredSymbols.length,
              itemBuilder: (context, index) {
                final symbol = filteredSymbols[index];
                return SymbolTile(
                  symbol: symbol,
                  onTap: () => onSymbolTap(symbol),
                  size: double.infinity,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

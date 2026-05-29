import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'package:provider/provider.dart';
import '../providers/aac_provider.dart';
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

  static final Map<String, IconData> interestIcons = {
    'minecraft': Icons.grid_view,
    'roblox': Icons.videogame_asset,
    'youtube': Icons.play_circle,
    'music': Icons.music_note,
    'drawing': Icons.brush,
    'animals': Icons.pets,
    'legos': Icons.extension,
    'cars': Icons.directions_car,
    'dinosaurs': Icons.cruelty_free,
    'trains': Icons.train,
    'space': Icons.rocket,
    'cooking': Icons.restaurant,
  };

  static final List<Symbol> symbols = [
    // ROW 1
    Symbol(id: 'who', label: 'Who', icon: Icons.person_search, category: SymbolCategory.question),
    Symbol(id: 'what', label: 'What', icon: Icons.help_outline, category: SymbolCategory.question),
    Symbol(id: 'why', label: 'Why', icon: Icons.psychology, category: SymbolCategory.question),
    Symbol(id: 'where', label: 'Where', icon: Icons.place, category: SymbolCategory.question),
    Symbol(id: 'when', label: 'When', icon: Icons.access_time, category: SymbolCategory.question),
    Symbol(id: 'now', label: 'Now', icon: Icons.timer, category: SymbolCategory.preposition),
    Symbol(id: 'then', label: 'Then', icon: Icons.update, category: SymbolCategory.preposition),
    Symbol(id: 'daily', label: 'Daily', icon: Icons.calendar_today, category: SymbolCategory.folder, isFolder: true),
    Symbol(id: 'play', label: 'Play', icon: Icons.sports_esports, category: SymbolCategory.folder, isFolder: true),

    // ROW 2
    Symbol(id: 'i', label: 'I', icon: Icons.person, category: SymbolCategory.pronoun),
    Symbol(id: 'to', label: 'To', icon: Icons.arrow_forward, category: SymbolCategory.verb),
    Symbol(id: 'want', label: 'Want', icon: Icons.favorite, category: SymbolCategory.verb),
    Symbol(id: 'come', label: 'Come', icon: Icons.waving_hand, category: SymbolCategory.verb),
    Symbol(id: 'see', label: 'See', icon: Icons.visibility, category: SymbolCategory.verb),
    Symbol(id: 'this', label: 'This', icon: Icons.touch_app, category: SymbolCategory.preposition),
    Symbol(id: 'that', label: 'That', icon: Icons.pan_tool, category: SymbolCategory.preposition),
    Symbol(id: 'chat', label: 'Chat', icon: Icons.chat_bubble, category: SymbolCategory.folder, isFolder: true),
    Symbol(id: 'news', label: 'News', icon: Icons.newspaper, category: SymbolCategory.folder, isFolder: true),

    // ROW 3
    Symbol(id: 'my', label: 'My', icon: Icons.back_hand, category: SymbolCategory.pronoun),
    Symbol(id: 'be', label: 'Be', icon: Icons.self_improvement, category: SymbolCategory.verb),
    Symbol(id: 'stop', label: 'Stop', icon: Icons.do_not_disturb, category: SymbolCategory.verb),
    Symbol(id: 'go', label: 'Go', icon: Icons.directions_walk, category: SymbolCategory.verb),
    Symbol(id: 'put', label: 'Put', icon: Icons.system_update_alt, category: SymbolCategory.verb),
    Symbol(id: 'in', label: 'In', icon: Icons.input, category: SymbolCategory.preposition),
    Symbol(id: 'on', label: 'On', icon: Icons.vertical_align_top, category: SymbolCategory.preposition),
    Symbol(id: 'position', label: 'Position', icon: Icons.control_camera, category: SymbolCategory.folder, isFolder: true),
    Symbol(id: 'places', label: 'Places', icon: Icons.holiday_village, category: SymbolCategory.folder, isFolder: true),

    // ROW 4
    Symbol(id: 'it', label: 'It', icon: Icons.interests, category: SymbolCategory.pronoun),
    Symbol(id: 'can', label: 'Can', icon: Icons.thumb_up, category: SymbolCategory.verb),
    Symbol(id: 'like', label: 'Like', icon: Icons.thumb_up_alt, category: SymbolCategory.verb),
    Symbol(id: 'get', label: 'Get', icon: Icons.front_hand, category: SymbolCategory.verb),
    Symbol(id: 'good', label: 'Good', icon: Icons.thumb_up, category: SymbolCategory.adjective),
    Symbol(id: 'a', label: 'A', icon: Icons.font_download, category: SymbolCategory.preposition),
    Symbol(id: 'the', label: 'The', icon: Icons.font_download_outlined, category: SymbolCategory.preposition),
    Symbol(id: 'time', label: 'Time', icon: Icons.schedule, category: SymbolCategory.folder, isFolder: true),
    Symbol(id: 'feelings', label: 'Feelings', icon: Icons.mood, category: SymbolCategory.folder, isFolder: true),

    // ROW 5
    Symbol(id: 'you', label: 'You', icon: Icons.person_outline, category: SymbolCategory.pronoun),
    Symbol(id: 'do', label: 'Do', icon: Icons.build, category: SymbolCategory.verb),
    Symbol(id: 'need', label: 'Need', icon: Icons.priority_high, category: SymbolCategory.verb),
    Symbol(id: 'help', label: 'Help', icon: Icons.live_help, category: SymbolCategory.verb),
    Symbol(id: 'more', label: 'More', icon: Icons.add_circle, category: SymbolCategory.adjective),
    Symbol(id: 'and', label: 'And', icon: Icons.add, category: SymbolCategory.preposition),
    Symbol(id: 'with', label: 'With', icon: Icons.handshake, category: SymbolCategory.preposition),
    Symbol(id: 'topics', label: 'Topics', icon: Icons.topic, category: SymbolCategory.folder, isFolder: true),
    Symbol(id: 'school', label: 'School', icon: Icons.school, category: SymbolCategory.folder, isFolder: true),

    // ROW 6
    Symbol(id: 'people_plus', label: 'People +', icon: Icons.people, category: SymbolCategory.pronoun, isFolder: true),
    Symbol(id: 'have', label: 'Have', icon: Icons.shopping_bag, category: SymbolCategory.verb),
    Symbol(id: 'questions_plus', label: 'Questions +', icon: Icons.help_outline, category: SymbolCategory.verb, isFolder: true),
    Symbol(id: 'actions_plus', label: 'Actions +', icon: Icons.directions_run, category: SymbolCategory.verb, isFolder: true),
    Symbol(id: 'describe_plus', label: 'Describe +', icon: Icons.brush, category: SymbolCategory.adjective, isFolder: true),
    Symbol(id: 'little_words_plus', label: 'Little words +', icon: Icons.short_text, category: SymbolCategory.preposition, isFolder: true),
    Symbol(id: 'not', label: 'Not', icon: Icons.not_interested, category: SymbolCategory.preposition),
    Symbol(id: 'messages', label: 'Messages', icon: Icons.message, category: SymbolCategory.folder, isFolder: true),
    Symbol(id: 'spelling_abc', label: 'Spelling abc', icon: Icons.abc, category: SymbolCategory.folder, isFolder: true),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AACProvider>(context);
    final profile = provider.currentProfile;

    List<Symbol> displaySymbols = List.from(symbols);

    if (profile != null) {
      if (profile.likes.isNotEmpty) {
        for (final like in profile.likes) {
          displaySymbols.add(Symbol(
            id: 'like_$like',
            label: like[0].toUpperCase() + like.substring(1), // Capitalize
            icon: interestIcons[like] ?? Icons.favorite,
            category: SymbolCategory.activity, // Map to an existing category
          ));
        }
      }
      
      if (profile.dislikes.isNotEmpty) {
        for (final dislike in profile.dislikes) {
          displaySymbols.add(Symbol(
            id: 'dislike_$dislike',
            label: 'No ${dislike[0].toUpperCase() + dislike.substring(1)}',
            icon: interestIcons[dislike] ?? Icons.thumb_down,
            category: SymbolCategory.feeling, // Using feeling for red/border mapping
          ));
        }
      }
    }

    return Container(
      color: Colors.black, // Dark background to make borders pop
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(), // Made scrollable to accommodate dynamic symbols
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9, // iPad layout
            mainAxisSpacing: 4, // Tight spacing like Grid for iPad
            crossAxisSpacing: 4,
            childAspectRatio: 0.9, // Make them slightly taller than square
          ),
          itemCount: displaySymbols.length,
          itemBuilder: (context, index) {
            final symbol = displaySymbols[index];
            return SymbolTile(
              symbol: symbol,
              onTap: () => onSymbolTap(symbol),
            );
          },
        ),
      ),
    );
  }
}


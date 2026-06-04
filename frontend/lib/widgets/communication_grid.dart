import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/aac_provider.dart';
import '../theme/app_theme.dart';
import 'symbol_tile.dart';

class CommunicationGrid extends StatefulWidget {
  final Function(Symbol) onSymbolTap;
  final String? activeCategory;
  final Function(String?) onCategoryChange;

  const CommunicationGrid({
    super.key,
    required this.onSymbolTap,
    this.activeCategory,
    required this.onCategoryChange,
  });

  @override
  State<CommunicationGrid> createState() => _CommunicationGridState();
}

class _CommunicationGridState extends State<CommunicationGrid> {
  late final PageController _pageController;
  late int _currentPage;

  static const List<_CategoryPage> _pages = [
    _CategoryPage(null, 'All', Icons.apps, AppTheme.textSecondary),
    _CategoryPage('pronoun', 'Pronouns', Icons.person, AppTheme.categoryPronoun),
    _CategoryPage('verb', 'Verbs', Icons.directions_run, AppTheme.categoryVerb),
    _CategoryPage('noun', 'Nouns', Icons.category, AppTheme.categoryNoun),
    _CategoryPage('preposition', 'Little Words', Icons.short_text, AppTheme.primary),
    _CategoryPage('activity', 'Activities', Icons.sports_esports, AppTheme.categoryActivity),
    _CategoryPage('feeling', 'Feelings', Icons.mood, AppTheme.secondary),
    _CategoryPage('question', 'Questions', Icons.help, AppTheme.warning),
  ];

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

    // Little words
    Symbol(id: 'the', label: 'The', icon: Icons.text_fields, category: SymbolCategory.preposition),
    Symbol(id: 'a', label: 'A', icon: Icons.text_fields, category: SymbolCategory.preposition),
    Symbol(id: 'at', label: 'At', icon: Icons.my_location, category: SymbolCategory.preposition),
    Symbol(id: 'that', label: 'That', icon: Icons.touch_app, category: SymbolCategory.preposition),
    Symbol(id: 'this', label: 'This', icon: Icons.back_hand, category: SymbolCategory.preposition),
    Symbol(id: 'to', label: 'To', icon: Icons.arrow_forward, category: SymbolCategory.preposition),
    Symbol(id: 'in', label: 'In', icon: Icons.input, category: SymbolCategory.preposition),
    Symbol(id: 'on', label: 'On', icon: Icons.vertical_align_top, category: SymbolCategory.preposition),
    Symbol(id: 'and', label: 'And', icon: Icons.add, category: SymbolCategory.preposition),
    Symbol(id: 'with', label: 'With', icon: Icons.group, category: SymbolCategory.preposition),
    Symbol(id: 'not', label: 'Not', icon: Icons.not_interested, category: SymbolCategory.preposition),

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

  @override
  void initState() {
    super.initState();
    _currentPage = _pageIndexFor(widget.activeCategory);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void didUpdateWidget(covariant CommunicationGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.activeCategory == widget.activeCategory) {
      return;
    }

    final targetPage = _pageIndexFor(widget.activeCategory);
    if (targetPage != _currentPage) {
      _currentPage = targetPage;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(targetPage);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AACProvider>(context);
    final profile = provider.currentProfile;
    final showContextPage = provider.isListeningContext || provider.teacherPrompt != null || provider.contextSuggestions.isNotEmpty;
    final pages = [..._pages, if (showContextPage) _CategoryPage('context', 'Context', Icons.psychology, AppTheme.primary)];

    final displaySymbols = List<Symbol>.from(symbols);
    if (profile != null) {
      // Inject the child's own name as a primary pronoun
      displaySymbols.insert(0, Symbol(
        id: 'profile_name',
        label: profile.name,
        icon: Icons.face_rounded,
        category: SymbolCategory.pronoun,
      ));

      if (profile.likes.isNotEmpty) {
        for (final like in profile.likes) {
          displaySymbols.add(
            Symbol(
              id: 'like_$like',
              label: like[0].toUpperCase() + like.substring(1),
              icon: _interestIconFor(like),
              category: SymbolCategory.activity,
            ),
          );
        }
      }

      if (profile.dislikes.isNotEmpty) {
        for (final dislike in profile.dislikes) {
          displaySymbols.add(
            Symbol(
              id: 'dislike_$dislike',
              label: 'No ${dislike[0].toUpperCase() + dislike.substring(1)}',
              icon: _interestIconFor(dislike),
              category: SymbolCategory.feeling,
            ),
          );
        }
      }
    }

    return Column(
      children: [
        SizedBox(
          height: 64,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            scrollDirection: Axis.horizontal,
            itemCount: pages.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final page = pages[index];
              final isActive = index == _currentPage;

              return GestureDetector(
                onTap: () => _goToPage(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isActive ? page.color.withValues(alpha: 0.18) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive ? page.color : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        page.icon,
                        size: 18,
                        color: isActive ? page.color : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        page.label,
                        style: TextStyle(
                          color: isActive ? page.color : AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (page.categoryId == 'context') ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _closeContextPage(context),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: isActive ? page.color : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _handlePageChanged,
            itemCount: pages.length,
            itemBuilder: (context, pageIndex) {
              final page = pages[pageIndex];

              if (page.categoryId == 'context') {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _ContextSuggestionsPage(
                    teacherPrompt: provider.teacherPrompt,
                    isLoading: provider.isLoadingSuggestions,
                    suggestions: provider.contextSuggestions,
                    onSuggestionTap: widget.onSymbolTap,
                    onClose: () => _closeContextPage(context),
                  ),
                );
              }

              final pageSymbols = _symbolsForCategory(displaySymbols, page.categoryId);

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (pageSymbols.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final metrics = _fitGridMetrics(constraints.biggest, pageSymbols.length);

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: metrics.crossAxisCount,
                        mainAxisSpacing: metrics.spacing,
                        crossAxisSpacing: metrics.spacing,
                        childAspectRatio: metrics.childAspectRatio,
                      ),
                      itemCount: pageSymbols.length,
                      itemBuilder: (context, index) {
                        final symbol = pageSymbols[index];
                        return SymbolTile(
                          symbol: symbol,
                          onTap: () => widget.onSymbolTap(symbol),
                          size: double.infinity,
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _interestIconFor(String interest) {
    switch (interest.toLowerCase()) {
      case 'minecraft':
        return Icons.grid_view;
      case 'roblox':
        return Icons.videogame_asset;
      case 'youtube':
        return Icons.play_circle;
      case 'music':
        return Icons.music_note;
      case 'drawing':
        return Icons.brush;
      case 'animals':
        return Icons.pets;
      case 'legos':
        return Icons.extension;
      case 'cars':
        return Icons.directions_car;
      case 'dinosaurs':
        return Icons.cruelty_free;
      case 'trains':
        return Icons.train;
      case 'space':
        return Icons.rocket;
      case 'cooking':
        return Icons.restaurant;
      default:
        return Icons.favorite;
    }
  }

  List<Symbol> _symbolsForCategory(List<Symbol> items, String? categoryId) {
    if (categoryId == null) {
      return items;
    }

    return items.where((symbol) => symbol.category.name == categoryId).toList();
  }

  int _pageIndexFor(String? categoryId) {
    final index = _pages.indexWhere((page) => page.categoryId == categoryId);
    return index == -1 ? 0 : index;
  }

  void _goToPage(int index) {
    if (index == _currentPage) {
      return;
    }

    setState(() {
      _currentPage = index;
    });

    if (index < _pages.length) {
      widget.onCategoryChange(_pages[index].categoryId);
    }

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _closeContextPage(BuildContext context) {
    final provider = context.read<AACProvider>();
    provider.resetContextSuggestions();
    widget.onCategoryChange(null);

    final targetPage = _pageIndexFor(null);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }

    if (mounted) {
      setState(() {
        _currentPage = targetPage;
      });
    }
  }

  void _handlePageChanged(int index) {
    if (!mounted || index == _currentPage) {
      return;
    }

    setState(() {
      _currentPage = index;
    });

    if (index < _pages.length) {
      widget.onCategoryChange(_pages[index].categoryId);
    }
  }

  _GridMetrics _fitGridMetrics(Size size, int itemCount) {
    const spacing = 10.0;

    var bestColumns = 1;
    var bestAspectRatio = 1.0;
    var bestScore = -1.0;

    for (var columns = 1; columns <= itemCount; columns++) {
      final rows = (itemCount / columns).ceil();
      final cellWidth = (size.width - (spacing * (columns - 1))) / columns;
      final cellHeight = (size.height - (spacing * (rows - 1))) / rows;

      if (cellWidth <= 0 || cellHeight <= 0) {
        continue;
      }

      final score = math.min(cellWidth, cellHeight);
      if (score > bestScore) {
        bestScore = score;
        bestColumns = columns;
        bestAspectRatio = cellWidth / cellHeight;
      }
    }

    return _GridMetrics(
      crossAxisCount: bestColumns,
      childAspectRatio: bestAspectRatio,
      spacing: spacing,
    );
  }
}

class _CategoryPage {
  final String? categoryId;
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryPage(this.categoryId, this.label, this.icon, this.color);
}

class _ContextSuggestionsPage extends StatelessWidget {
  final String? teacherPrompt;
  final bool isLoading;
  final List<String> suggestions;
  final Function(Symbol) onSuggestionTap;
  final VoidCallback onClose;

  const _ContextSuggestionsPage({
    required this.teacherPrompt,
    required this.isLoading,
    required this.suggestions,
    required this.onSuggestionTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSuggestions = isLoading ? const <String>[] : suggestions;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.psychology_alt, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    teacherPrompt != null ? '"$teacherPrompt"' : 'Context suggestions',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Close'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : visibleSuggestions.isEmpty
                      ? const Center(
                          child: Text(
                            'No suggestions available.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 900
                                ? 4
                                : constraints.maxWidth > 600
                                    ? 3
                                    : 2;
                            return GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1,
                              ),
                              itemCount: visibleSuggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion = visibleSuggestions[index];
                                return SymbolTile(
                                  symbol: Symbol(
                                    id: 'context_$index',
                                    label: suggestion,
                                    category: SymbolCategory.noun,
                                  ),
                                  onTap: () {
                                    onSuggestionTap(
                                      Symbol(
                                        id: 'context_$index',
                                        label: suggestion,
                                        category: SymbolCategory.noun,
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridMetrics {
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;

  const _GridMetrics({
    required this.crossAxisCount,
    required this.childAspectRatio,
    required this.spacing,
  });
}

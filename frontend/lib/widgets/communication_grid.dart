import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/services/obf/imported_image_resolver.dart';
import 'package:frontend/services/obf/obf_color.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/aac_provider.dart';
import '../services/arasaac_service.dart';
import '../services/kpi_logger.dart';
import '../theme/app_theme.dart';
import 'symbol_tile.dart';

class CommunicationGrid extends StatefulWidget {
  final Function(Symbol) onSymbolTap;
  final String? activeCategory;
  final Function(String?) onCategoryChange;

  final ImportedBoardSet? importedBoardSet;
  final String? activeImportedBoardPath;
  final void Function(String)? onImportedBoardChange;
  final ({Symbol? now, Symbol? next}) nowNextData;
  final VoidCallback? onNowNextTap;

  const CommunicationGrid({
    super.key,
    required this.onSymbolTap,
    this.activeCategory,
    required this.onCategoryChange,
    this.importedBoardSet,
    this.activeImportedBoardPath,
    this.onImportedBoardChange,
    required this.nowNextData,
    this.onNowNextTap,
  });

  @override
  State<CommunicationGrid> createState() => _CommunicationGridState();
}

class _CommunicationGridState extends State<CommunicationGrid> {
  late final PageController _pageController;
  late int _currentPage;
  bool get _isImportedMode => widget.importedBoardSet != null;

  List<_ImportedBoardPage> _importedPagesFor(ImportedBoardSet boardSet) {
    final entries = boardSet.boardsByPath.entries.toList();

    entries.sort((a, b) {
      if (a.key == boardSet.rootPath) return -1;
      if (b.key == boardSet.rootPath) return 1;
      return a.value.name.compareTo(b.value.name);
    });

    return entries.map((entry) {
      return _ImportedBoardPage(path: entry.key, label: entry.value.name);
    }).toList();
  }

  static final List<_CategoryPage> _pages = [
    _CategoryPage(null, 'All', Icons.apps, AppTheme.textSecondary),
    _CategoryPage(
      'pronoun',
      'Pronouns',
      Icons.person,
      AppTheme.categoryPronoun,
    ),
    _CategoryPage('verb', 'Verbs', Icons.directions_run, AppTheme.categoryVerb),
    _CategoryPage('noun', 'Nouns', Icons.category, AppTheme.categoryNoun),
    _CategoryPage(
      'preposition',
      'Little Words',
      Icons.short_text,
      AppTheme.categoryPreposition,
    ),
    _CategoryPage(
      'activity',
      'Activities',
      Icons.sports_esports,
      AppTheme.categoryActivity,
    ),
    _CategoryPage('feeling', 'Feelings', Icons.mood, AppTheme.categoryFeeling),
    _CategoryPage('question', 'Questions', Icons.help, AppTheme.categoryQuestion),
  ];

  static final List<Symbol> symbols = [
    // Pronouns
    Symbol(
      id: 'i',
      label: 'I',
      icon: Icons.person,
      category: SymbolCategory.pronoun,
    ),
    Symbol(
      id: 'you',
      label: 'You',
      icon: Icons.person_outline,
      category: SymbolCategory.pronoun,
    ),
    Symbol(
      id: 'we',
      label: 'We',
      icon: Icons.people,
      category: SymbolCategory.pronoun,
    ),
    Symbol(
      id: 'they',
      label: 'They',
      icon: Icons.people_outline,
      category: SymbolCategory.pronoun,
    ),

    // Verbs
    Symbol(
      id: 'want',
      label: 'Want',
      icon: Icons.favorite,
      category: SymbolCategory.verb,
    ),
    Symbol(
      id: 'need',
      label: 'Need',
      icon: Icons.priority_high,
      category: SymbolCategory.verb,
    ),
    Symbol(
      id: 'like',
      label: 'Like',
      icon: Icons.thumb_up,
      category: SymbolCategory.verb,
    ),
    Symbol(
      id: 'dont_like',
      label: "Don't Like",
      icon: Icons.thumb_down,
      category: SymbolCategory.verb,
    ),
    Symbol(
      id: 'go',
      label: 'Go',
      icon: Icons.directions_walk,
      category: SymbolCategory.verb,
    ),
    Symbol(
      id: 'play',
      label: 'Play',
      icon: Icons.sports_esports,
      category: SymbolCategory.verb,
    ),
    Symbol(
      id: 'eat',
      label: 'Eat',
      icon: Icons.restaurant,
      category: SymbolCategory.verb,
    ),
    Symbol(
      id: 'drink',
      label: 'Drink',
      icon: Icons.local_drink,
      category: SymbolCategory.verb,
    ),
    Symbol(
      id: 'see',
      label: 'See',
      icon: Icons.visibility,
      category: SymbolCategory.verb,
    ),
    Symbol(
      id: 'help',
      label: 'Help',
      icon: Icons.help,
      category: SymbolCategory.verb,
    ),

    // Nouns
    Symbol(
      id: 'food',
      label: 'Food',
      icon: Icons.fastfood,
      category: SymbolCategory.noun,
    ),
    Symbol(
      id: 'water',
      label: 'Water',
      icon: Icons.water_drop,
      category: SymbolCategory.noun,
    ),
    Symbol(
      id: 'home',
      label: 'Home',
      icon: Icons.home,
      category: SymbolCategory.noun,
    ),
    Symbol(
      id: 'school',
      label: 'School',
      icon: Icons.school,
      category: SymbolCategory.noun,
    ),
    Symbol(
      id: 'bathroom',
      label: 'Bathroom',
      icon: Icons.wc,
      category: SymbolCategory.noun,
    ),
    Symbol(
      id: 'outside',
      label: 'Outside',
      icon: Icons.park,
      category: SymbolCategory.noun,
    ),

    // Little words
    Symbol(
      id: 'the',
      label: 'The',
      icon: Icons.text_fields,
      category: SymbolCategory.preposition,
    ),
    Symbol(
      id: 'a',
      label: 'A',
      icon: Icons.text_fields,
      category: SymbolCategory.preposition,
    ),
    Symbol(
      id: 'at',
      label: 'At',
      icon: Icons.my_location,
      category: SymbolCategory.preposition,
    ),
    Symbol(
      id: 'that',
      label: 'That',
      icon: Icons.touch_app,
      category: SymbolCategory.preposition,
    ),
    Symbol(
      id: 'this',
      label: 'This',
      icon: Icons.back_hand,
      category: SymbolCategory.preposition,
    ),
    Symbol(
      id: 'to',
      label: 'To',
      icon: Icons.arrow_forward,
      category: SymbolCategory.preposition,
    ),
    Symbol(
      id: 'in',
      label: 'In',
      icon: Icons.input,
      category: SymbolCategory.preposition,
    ),
    Symbol(
      id: 'on',
      label: 'On',
      icon: Icons.vertical_align_top,
      category: SymbolCategory.preposition,
    ),
    Symbol(
      id: 'and',
      label: 'And',
      icon: Icons.add,
      category: SymbolCategory.preposition,
    ),
    Symbol(
      id: 'with',
      label: 'With',
      icon: Icons.group,
      category: SymbolCategory.preposition,
    ),
    Symbol(
      id: 'not',
      label: 'Not',
      icon: Icons.not_interested,
      category: SymbolCategory.preposition,
    ),

    // Activities
    Symbol(
      id: 'minecraft',
      label: 'Minecraft',
      icon: Icons.grid_view,
      category: SymbolCategory.activity,
    ),
    Symbol(
      id: 'roblox',
      label: 'Roblox',
      icon: Icons.videogame_asset,
      category: SymbolCategory.activity,
    ),
    Symbol(
      id: 'youtube',
      label: 'YouTube',
      icon: Icons.play_circle,
      category: SymbolCategory.activity,
    ),
    Symbol(
      id: 'tablet',
      label: 'Tablet',
      icon: Icons.tablet,
      category: SymbolCategory.activity,
    ),
    Symbol(
      id: 'music',
      label: 'Music',
      icon: Icons.music_note,
      category: SymbolCategory.activity,
    ),
    Symbol(
      id: 'drawing',
      label: 'Drawing',
      icon: Icons.brush,
      category: SymbolCategory.activity,
    ),

    // Feelings
    Symbol(
      id: 'happy',
      label: 'Happy',
      icon: Icons.sentiment_very_satisfied,
      category: SymbolCategory.feeling,
    ),
    Symbol(
      id: 'sad',
      label: 'Sad',
      icon: Icons.sentiment_dissatisfied,
      category: SymbolCategory.feeling,
    ),
    Symbol(
      id: 'angry',
      label: 'Angry',
      icon: Icons.sentiment_very_dissatisfied,
      category: SymbolCategory.feeling,
    ),
    Symbol(
      id: 'tired',
      label: 'Tired',
      icon: Icons.bedtime,
      category: SymbolCategory.feeling,
    ),
    Symbol(
      id: 'scared',
      label: 'Scared',
      icon: Icons.warning,
      category: SymbolCategory.feeling,
    ),
    Symbol(
      id: 'calm',
      label: 'Calm',
      icon: Icons.self_improvement,
      category: SymbolCategory.feeling,
    ),

    // Questions
    Symbol(
      id: 'what',
      label: 'What?',
      icon: Icons.help_outline,
      category: SymbolCategory.question,
    ),
    Symbol(
      id: 'where',
      label: 'Where?',
      icon: Icons.place,
      category: SymbolCategory.question,
    ),
    Symbol(
      id: 'when',
      label: 'When?',
      icon: Icons.access_time,
      category: SymbolCategory.question,
    ),
    Symbol(
      id: 'why',
      label: 'Why?',
      icon: Icons.psychology,
      category: SymbolCategory.question,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentPage = _initialPageIndex();
    _pageController = PageController(initialPage: _currentPage);
    // Register the static board vocabulary (the single source of truth) so the
    // KPI logger can tell on-board taps from off-board (vocab-expansion) ones.
    KpiLogger.instance.setBoardVocabulary(symbols.map((s) => s.label));
  }

  int _initialPageIndex() {
    if (_isImportedMode) {
      return _importedPageIndexFor(widget.activeImportedBoardPath);
    }
    return _pageIndexFor(widget.activeCategory);
  }

  int _importedPageIndexFor(String? boardPath) {
    final boardSet = widget.importedBoardSet;
    if (boardSet == null) {
      return 0;
    }

    final pages = _importedPagesFor(boardSet);
    final effectivePath = boardPath ?? boardSet.rootPath;

    final index = pages.indexWhere((page) => page.path == effectivePath);
    return index == -1 ? 0 : index;
  }

  @override
  void didUpdateWidget(covariant CommunicationGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isImportedMode) {
      if (oldWidget.activeImportedBoardPath == widget.activeImportedBoardPath &&
          oldWidget.importedBoardSet == widget.importedBoardSet) {
        return;
      }

      final targetPage = _importedPageIndexFor(widget.activeImportedBoardPath);
      if (targetPage != _currentPage) {
        _currentPage = targetPage;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(targetPage);
        }
      }
      return;
    }

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

  // ─── REFACTORED INLINE NOW/NEXT USING EXISTING MINI_SYMBOL_TILE ───────────
  Widget _buildInlineNowNext() {
    // Respect the user's setting to hide the Now/Next badge entirely.
    if (!context.read<AACProvider>().showNowNext) {
      return const SizedBox.shrink();
    }

    final hasNow = widget.nowNextData.now != null;
    final hasNext = widget.nowNextData.next != null;

    if (!hasNow && !hasNext) return const SizedBox.shrink();

    return GestureDetector(
      onTap: widget.onNowNextTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 10, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A), // Solid dark blue for strong contrast against slate background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.secondary, width: 3), // Bright, prominent border
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
          children: [
            if (hasNow)
              _buildPrefixedScheduleTile(
                prefix: "NOW: ",
                prefixColor: const Color(0xFF2196F3),
                symbol: widget.nowNextData.now!,
              ),
            if (hasNow && hasNext)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            if (hasNext)
              _buildPrefixedScheduleTile(
                prefix: "NEXT: ",
                prefixColor: const Color(0xFF4CAF50),
                symbol: widget.nowNextData.next!,
              ),
          ],
        ),
      ),
    );
  }

  // Helper method that injects the prefix text directly in front of your MiniSymbolTile
  Widget _buildPrefixedScheduleTile({
    required String prefix,
    required Color prefixColor,
    required Symbol symbol,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          prefix,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: prefixColor,
          ),
        ),
        const SizedBox(width: 8),
        IntrinsicHeight(
          child: MiniSymbolTile(
            symbol: symbol,
            isExpanded: true,
            iconSize: 26, // Smaller actual icons as requested
            onTap: () => widget.onSymbolTap(symbol),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isImportedMode) {
      return _buildImportedBoardView(context);
    }

    final provider = Provider.of<AACProvider>(context);
    final profile = provider.currentProfile;
    final showContextPage =
        provider.isListeningContext ||
        provider.teacherPrompt != null ||
        provider.contextSuggestions.isNotEmpty;
    final pages = [
      ..._pages,
      if (showContextPage)
        _CategoryPage('context', 'Suggestions', Icons.psychology, AppTheme.primary),
    ];

    final displaySymbols = List<Symbol>.from(symbols);
    if (profile != null) {
      displaySymbols.insert(
        0,
        Symbol(
          id: 'profile_name',
          label: profile.name,
          icon: Icons.face_rounded,
          category: SymbolCategory.pronoun,
        ),
      );

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

    // Add custom symbols created from context suggestions
    displaySymbols.addAll(provider.customSymbols);

    final hasNowNext = provider.showNowNext &&
        (widget.nowNextData.now != null || widget.nowNextData.next != null);

    return Column(
      children: [
        // ─── TOP BAR ROW: CHIPS (LEFT) + NOW/NEXT (RIGHT) ────────────────────
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ColoredBox(
                  color: const Color(0xFF0F172A),
                  child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: pages.length,
                  // Keep tabs close together, but leave enough room that the
                  // active tab's scale-up still shows a gap to its neighbours.
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    final isActive = index == _currentPage;

                    // Tabs always show their full, bright category colour.
                    // Selection is conveyed by a contrasting ring, a colour
                    // glow, a slight scale-up and bolder text — not by dimming.
                    final ink = AppTheme.onColor(page.color);
                    // The ring/border is a darker shade of the tab's own colour
                    // so it reads as a cohesive outline rather than a washed-out
                    // grey/white that clashed with the bright fill.
                    final hsl = HSLColor.fromColor(page.color);
                    final ringColor = AppTheme.isHighContrast
                        ? AppTheme.focusHighlight
                        : hsl
                            .withLightness((hsl.lightness * 0.5).clamp(0.0, 1.0))
                            .toColor();

                    return GestureDetector(
                      onTap: () => _goToPage(index),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        scale: isActive ? 1.08 : 0.92,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                            horizontal: hasNowNext ? 12 : 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: page.color,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? ringColor
                                  : ringColor.withValues(alpha: 0.85),
                              width: isActive ? 4 : 3,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                page.icon,
                                size: hasNowNext ? 18 : 22,
                                color: ink,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                page.label,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: hasNowNext ? 13 : 16,
                                  fontWeight: isActive
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                              if (page.categoryId == 'context') ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => _closeContextPage(context),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: ink,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                ),
              ),
              _buildInlineNowNext(), // Inline element displays here stretched vertically
            ],
          ),
        ),

        // ─── NATIVE CORE COHESIVE LAYOUT BUILDER SCREEN WINDOW ───────────────
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
                    authRequired: provider.authRequired,
                    onSuggestionTap: widget.onSymbolTap,
                    onClose: () => _closeContextPage(context),
                  ),
                );
              }

              final pageSymbols = _symbolsForCategory(
                displaySymbols,
                page.categoryId,
              );

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (pageSymbols.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final metrics = _fitGridMetrics(
                      constraints.biggest,
                      pageSymbols.length,
                    );

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

  Widget _buildImportedBoardView(BuildContext context) {
    final boardSet = widget.importedBoardSet!;
    final pages = _importedPagesFor(boardSet);

    return Column(
      children: [
        // ─── IMPORTED MODE HEADER ROW WITH INLINE RETENTION ──────────────────
        SizedBox(
          height: 96, // Expanded height so the Now/Next box is larger and readable
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Prevent chips from stretching vertically too much
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: pages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    final isActive = index == _currentPage;

                    return GestureDetector(
                      onTap: () => _goToImportedPage(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primary.withValues(alpha: 0.18)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.primary
                                : AppTheme.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.dashboard_customize,
                              size: 18,
                              color: isActive
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              page.label,
                              style: TextStyle(
                                color: isActive
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildInlineNowNext(),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _handleImportedPageChanged,
            itemCount: pages.length,
            itemBuilder: (context, pageIndex) {
              final page = pages[pageIndex];
              final board = boardSet.boardsByPath[page.path];

              if (board == null) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _ImportedBoardPageView(
                  board: board,
                  packagedFiles: boardSet.filesByPath,
                  onButtonTap: _handleImportedButtonTap,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _goToImportedPage(int index) {
    final boardSet = widget.importedBoardSet;
    if (boardSet == null) return;

    final pages = _importedPagesFor(boardSet);

    if (index == _currentPage || index < 0 || index >= pages.length) {
      return;
    }

    setState(() {
      _currentPage = index;
    });

    widget.onImportedBoardChange?.call(pages[index].path);

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleImportedPageChanged(int index) {
    final boardSet = widget.importedBoardSet;
    if (!mounted || boardSet == null || index == _currentPage) {
      return;
    }

    final pages = _importedPagesFor(boardSet);

    setState(() {
      _currentPage = index;
    });

    if (index >= 0 && index < pages.length) {
      widget.onImportedBoardChange?.call(pages[index].path);
    }
  }

  void _handleImportedButtonTap(
    ImportedButton button,
    ResolvedImportedImage? image,
  ) {
    final linkedPath = button.linkedBoardPath;
    if (linkedPath != null && linkedPath.isNotEmpty) {
      final targetIndex = _importedPageIndexFor(linkedPath);
      _goToImportedPage(targetIndex);
      return;
    }

    widget.onSymbolTap(
      Symbol(
        id: button.id,
        label: button.speechText,
        category: SymbolCategory.noun,
        // Carry the pictogram and the author's colours so the sentence rail
        // matches the imported board instead of falling back to a blank
        // Colourful Semantics tile.
        imageBytes: image?.bytes,
        imageUrl: image?.url,
        isSvg: image?.isSvg ?? false,
        backgroundColor: button.backgroundColor ?? AppTheme.surface,
        borderColor: button.borderColor ?? AppTheme.border,
      ),
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
    
    final provider = context.read<AACProvider>();
    if (provider.gridColumns != null) {
      final columns = provider.gridColumns!;
      final rows = (itemCount / columns).ceil();
      final cellWidth = (size.width - (spacing * (columns - 1))) / columns;
      final cellHeight = (size.height - (spacing * (rows - 1))) / rows;
      
      return _GridMetrics(
        crossAxisCount: columns,
        childAspectRatio: (cellWidth > 0 && cellHeight > 0) ? cellWidth / cellHeight : 1.0,
        spacing: spacing,
      );
    }

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

class _ImportedBoardPage {
  final String path;
  final String label;

  const _ImportedBoardPage({required this.path, required this.label});
}

class _ContextSuggestionsPage extends StatefulWidget {
  final String? teacherPrompt;
  final bool isLoading;
  final List<String> suggestions;
  final bool authRequired;
  final Function(Symbol) onSuggestionTap;
  final VoidCallback onClose;

  const _ContextSuggestionsPage({
    required this.teacherPrompt,
    required this.isLoading,
    required this.suggestions,
    this.authRequired = false,
    required this.onSuggestionTap,
    required this.onClose,
  });

  @override
  State<_ContextSuggestionsPage> createState() => _ContextSuggestionsPageState();
}

class _ContextSuggestionsPageState extends State<_ContextSuggestionsPage> {
  final ArasaacService _arasaacService = ArasaacService();
  final Map<String, String?> _imageUrls = {};
  final Map<String, IconData?> _icons = {};

  @override
  void didUpdateWidget(covariant _ContextSuggestionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suggestions != widget.suggestions) {
      _fetchImages();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  void _fetchImages() {
    final provider = context.read<AACProvider>();
    final allSymbols = [
      ..._CommunicationGridState.symbols,
      ...provider.customSymbols,
    ];

    for (final suggestion in widget.suggestions) {
      if (!_imageUrls.containsKey(suggestion) && !_icons.containsKey(suggestion)) {
        final localMatch = allSymbols.where((s) => s.label.toLowerCase() == suggestion.toLowerCase()).firstOrNull;

        if (localMatch != null && (localMatch.imageUrl != null || localMatch.icon != null)) {
          if (mounted) {
            setState(() {
              _imageUrls[suggestion] = localMatch.imageUrl;
              _icons[suggestion] = localMatch.icon;
            });
          }
        } else {
          _arasaacService.getPictogramUrl(suggestion).then((url) {
            if (mounted) {
              setState(() {
                _imageUrls[suggestion] = url;
                _icons[suggestion] = null;
              });
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleSuggestions = widget.isLoading ? const <String>[] : widget.suggestions;

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
                    widget.teacherPrompt != null
                        ? '"${widget.teacherPrompt}"'
                        : 'Context suggestions',
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
                  onPressed: widget.onClose,
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
              child: widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.authRequired
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, size: 48, color: AppTheme.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'Please log in to use smart suggestions',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Go to the Dashboard and tap the Login button',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : visibleSuggestions.isEmpty
                  ? Center(
                      child: Text(
                        'No suggestions available.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final totalItems = visibleSuggestions.length + 1;
                        
                        int bestCols = 1;
                        int bestRows = totalItems;
                        double bestAspectRatioDiff = double.infinity;

                        // Subtract 2.0 from max height to prevent Flutter floating-point overflow errors
                        double safeMaxHeight = constraints.maxHeight - 2.0;

                        for (int cols = 1; cols <= totalItems; cols++) {
                          int rows = (totalItems / cols).ceil();
                          double itemWidth = (constraints.maxWidth - (cols - 1) * 10) / cols;
                          double itemHeight = (safeMaxHeight - (rows - 1) * 10) / rows;
                          
                          if (itemHeight <= 0 || itemWidth <= 0) continue;
                          
                          double ratio = itemWidth / itemHeight;
                          double diff = (ratio - 1.0).abs();
                          
                          // We prefer slightly wider tiles
                          if (ratio > 0.8 && ratio < 3.0 && diff < bestAspectRatioDiff) {
                            bestAspectRatioDiff = diff;
                            bestCols = cols;
                            bestRows = rows;
                          } else if (bestAspectRatioDiff == double.infinity) {
                             bestAspectRatioDiff = diff;
                             bestCols = cols;
                             bestRows = rows;
                          }
                        }

                        double finalItemWidth = (constraints.maxWidth - (bestCols - 1) * 10) / bestCols;
                        double finalItemHeight = (safeMaxHeight - (bestRows - 1) * 10) / bestRows;
                        double finalAspectRatio = (finalItemWidth / finalItemHeight).clamp(0.1, 10.0);

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: bestCols,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: finalAspectRatio,
                          ),
                          itemCount: visibleSuggestions.length + 1,
                          itemBuilder: (context, index) {
                            if (index == visibleSuggestions.length) {
                              return SymbolTile(
                                symbol: const Symbol(
                                  id: 'more_options',
                                  label: 'More options',
                                  icon: Icons.add,
                                  category: SymbolCategory.noun,
                                ),
                                onTap: () {
                                  context.read<AACProvider>().fetchSuggestions(append: true);
                                },
                                size: double.infinity,
                              );
                            }
                            
                            final suggestion = visibleSuggestions[index];
                            final imageUrl = _imageUrls[suggestion];
                            final icon = _icons[suggestion];
                            final symbol = Symbol(
                              id: 'context_$index',
                              label: suggestion,
                              category: SymbolCategory.noun,
                              imageUrl: imageUrl,
                              icon: icon,
                            );
                            return SymbolTile(
                              symbol: symbol,
                              onTap: () {
                                // Record the accepted AI suggestion for KPI
                                // measurement (acceptance rate, keystroke savings).
                                KpiLogger.instance.logSuggestionTap(suggestion);
                                widget.onSuggestionTap(symbol);
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

class _ImportedBoardPageView extends StatelessWidget {
  final ImportedBoard board;
  final Map<String, List<int>> packagedFiles;
  // Receives the resolved image alongside the button so the tap target (e.g.
  // the sentence rail) can show the same pictogram the tile rendered, without
  // re-resolving it from the archive.
  final void Function(ImportedButton button, ResolvedImportedImage? image)
      onButtonTap;

  const _ImportedBoardPageView({
    required this.board,
    required this.packagedFiles,
    required this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    final buttonMap = board.buttonsById;
    final orderedIds = board.grid.order.expand((row) => row).toList();
    final imageResolver = ImportedImageResolver();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = board.grid.columns <= 0 ? 1 : board.grid.columns;
        final rows = board.grid.rows <= 0 ? 1 : board.grid.rows;

        const spacing = 10.0;

        final cellWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
        final cellHeight =
            (constraints.maxHeight - ((rows - 1) * spacing)) / rows;
        final aspectRatio = cellHeight > 0 ? cellWidth / cellHeight : 1.0;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: orderedIds.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final buttonId = orderedIds[index];

            if (buttonId == null) {
              return const SizedBox.shrink();
            }

            final button = buttonMap[buttonId];
            if (button == null) {
              return const SizedBox.shrink();
            }

            final image = button.imageId != null
                ? board.imagesById[button.imageId]
                : null;
            final resolvedImage = imageResolver.resolve(image, packagedFiles);

            return _ImportedBoardTile(
              button: button,
              imageBytes: resolvedImage?.bytes,
              imageUrl: resolvedImage?.url,
              isSvg: resolvedImage?.isSvg ?? false,
              onTap: () => onButtonTap(button, resolvedImage),
            );
          },
        );
      },
    );
  }
}

class _ImportedBoardTile extends StatelessWidget {
  final ImportedButton button;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final bool isSvg;
  final VoidCallback onTap;

  const _ImportedBoardTile({
    required this.button,
    required this.onTap,
    this.imageBytes,
    this.imageUrl,
    this.isSvg = false,
  });

  @override
  Widget build(BuildContext context) {
    // Honour the OBF author's colours where given; otherwise fall back to the
    // app's default tile styling. Imported boards are intentionally NOT painted
    // with the Colourful Semantics palette — that stays exclusive to the
    // default board.
    final backgroundColor = button.backgroundColor ?? AppTheme.surface;
    final borderColor = button.borderColor ?? AppTheme.border;
    // Pick a legible label/icon colour for whatever background we ended up with.
    final foregroundColor = obfForegroundColor(backgroundColor);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: _buildImage(foregroundColor)),
              const SizedBox(height: 8),
              Text(
                button.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the button's picture, choosing a decoder by source type. SVG must
  /// go through [SvgPicture] — the raster [Image] widget throws on SVG, which
  /// is why many imported symbols (CommuniKate ships most of its as SVG) were
  /// falling back to the placeholder icon. Both byte and URL sources are
  /// supported for each format.
  Widget _buildImage(Color foregroundColor) {
    final hasBytes = imageBytes != null && imageBytes!.isNotEmpty;
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;

    final fallback = Icon(
      Icons.image_outlined,
      color: foregroundColor,
      size: 32,
    );

    if (hasBytes) {
      return isSvg
          ? SvgPicture.memory(
              imageBytes!,
              fit: BoxFit.contain,
              placeholderBuilder: (_) => fallback,
            )
          : Image.memory(
              imageBytes!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => fallback,
            );
    }

    if (hasUrl) {
      return isSvg
          ? SvgPicture.network(
              imageUrl!,
              fit: BoxFit.contain,
              placeholderBuilder: (_) => fallback,
            )
          : Image.network(
              imageUrl!,
              fit: BoxFit.contain,
              // Pictograms render in small tiles; cap the decoded bitmap size
              // so the image cache doesn't hold full-res copies.
              cacheWidth: 200,
              errorBuilder: (_, _, _) => fallback,
            );
    }

    return fallback;
  }
}

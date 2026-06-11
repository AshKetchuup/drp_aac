import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/fill_blanks_models.dart';
import '../providers/aac_provider.dart';
import '../providers/fill_blanks_controller.dart';
import '../services/arasaac_service.dart';
import '../theme/app_theme.dart';

/// ─── SCREEN WRAPPER ──────────────────────────────────────────────────────────
/// Thin shell that supplies the app's TTS to the (otherwise self-contained)
/// game widget. Push this from anywhere: the game manages its own state.
class FillBlanksGameScreen extends StatelessWidget {
  final SentenceGameSession? session;

  const FillBlanksGameScreen({super.key, this.session});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AACProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FillBlanksGame(
          session: session ?? SentenceGameSession.starter(),
          onSpeak: provider.speak,
          onExit: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

/// ─── GAME WIDGET ─────────────────────────────────────────────────────────────
/// Self-contained "Fill in the Blanks" minigame. Owns a [FillBlanksController]
/// and renders: scene image → sentence strip with one coloured blank → three
/// option cards (correct + semantic distractor + grammatical distractor).
class FillBlanksGame extends StatefulWidget {
  final SentenceGameSession session;

  /// Spoken feedback hook (wired to the app's TTS by the screen wrapper).
  final Future<void> Function(String text)? onSpeak;

  final VoidCallback? onExit;

  const FillBlanksGame({
    super.key,
    required this.session,
    this.onSpeak,
    this.onExit,
  });

  @override
  State<FillBlanksGame> createState() => _FillBlanksGameState();
}

class _FillBlanksGameState extends State<FillBlanksGame> {
  late final FillBlanksController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FillBlanksController(session: widget.session);
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onStateChanged() => setState(() {});

  void _handleCardTap(GameCard card) {
    final solved = _controller.selectCard(card);
    // Auditory reinforcement: hear the word you pressed; hear the whole
    // modelled sentence once the blank is filled correctly.
    if (solved) {
      widget.onSpeak?.call(_controller.currentQuestion.spokenSentence);
    } else {
      widget.onSpeak?.call(card.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isComplete) {
      return _CompletionView(
        score: _controller.score,
        total: _controller.totalQuestions,
        onReplay: _controller.restart,
        onExit: widget.onExit,
      );
    }

    final question = _controller.currentQuestion;

    return Column(
      children: [
        _GameTopBar(
          questionNumber: _controller.questionNumber,
          totalQuestions: _controller.totalQuestions,
          score: _controller.score,
          onExit: widget.onExit,
        ),

        // ─── TARGET SCENE ────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              padding: const EdgeInsets.all(16),
              child: _Pictogram(
                keyword: question.sceneKeyword,
                fallbackIcon: question.sceneFallbackIcon,
                iconColor:
                    AppTheme.isHighContrast ? Colors.black : Colors.black54,
              ),
            ),
          ),
        ),

        // ─── SENTENCE STRIP WITH COLOURED BLANK ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: _SentenceStrip(
            question: question,
            filledCard: _controller.isCorrect == true
                ? question.correctCard
                : null,
          ),
        ),

        // ─── OPTION CARDS ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardSize = math.min(
                150.0,
                (constraints.maxWidth - 32) / 3,
              );
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final card in _controller.options) ...[
                    if (card != _controller.options.first)
                      const SizedBox(width: 16),
                    _OptionCard(
                      card: card,
                      size: cardSize,
                      isSolved: _controller.isCorrect == true &&
                          card.id == question.correctCard.id,
                      isEliminated: _controller.isEliminated(card),
                      // Re-keying on shakeTick restarts the shake even if the
                      // learner taps the same wrong card again.
                      shakeTick: _controller.selectedAnswer?.id == card.id &&
                              _controller.isCorrect == false
                          ? _controller.shakeTick
                          : 0,
                      onTap: () => _handleCardTap(card),
                    ),
                  ],
                ],
              );
            },
          ),
        ),

        // ─── NEXT BUTTON (appears once solved; learner sets the pace) ────────
        SizedBox(
          height: 64,
          child: _controller.isCorrect == true
              ? ElevatedButton.icon(
                  onPressed: _controller.nextQuestion,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    _controller.questionNumber == _controller.totalQuestions
                        ? 'Finish'
                        : 'Next',
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// ─── TOP BAR: EXIT, PROGRESS, SCORE ─────────────────────────────────────────
class _GameTopBar extends StatelessWidget {
  final int questionNumber;
  final int totalQuestions;
  final int score;
  final VoidCallback? onExit;

  const _GameTopBar({
    required this.questionNumber,
    required this.totalQuestions,
    required this.score,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onExit,
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            tooltip: 'Exit game',
          ),
          const SizedBox(width: 4),
          const Text(
            'Fill in the Blanks',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '$questionNumber of $totalQuestions',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: AppTheme.warning, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── SENTENCE STRIP ──────────────────────────────────────────────────────────
/// Fixed text segments plus the single coloured blank. The blank shows the cue
/// question ("Doing?") while empty and the winning card once solved.
class _SentenceStrip extends StatelessWidget {
  final GameQuestion question;

  /// Non-null once the learner answers correctly.
  final GameCard? filledCard;

  const _SentenceStrip({required this.question, this.filledCard});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final segment in question.segments)
          segment.isBlank
              ? _BlankSlot(type: question.blankType, filledCard: filledCard)
              : Text(
                  segment.text!,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
      ],
    );
  }
}

/// The drop-target blank, colour-coded to its semantic category.
class _BlankSlot extends StatelessWidget {
  final SemanticType type;
  final GameCard? filledCard;

  const _BlankSlot({required this.type, this.filledCard});

  @override
  Widget build(BuildContext context) {
    final isFilled = filledCard != null;

    return Semantics(
      label: isFilled
          ? 'Blank filled with ${filledCard!.label}'
          : 'Empty blank, ${type.question}',
      child: AnimatedContainer(
        // Green success flash: border and glow snap to green on fill, then the
        // bounce below draws the eye to the completed word.
        duration: const Duration(milliseconds: 250),
        constraints: const BoxConstraints(minWidth: 130, minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.isHighContrast
              ? type.color
              : type.color.withValues(alpha: isFilled ? 0.9 : 0.22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFilled
                ? (AppTheme.isHighContrast
                    ? AppTheme.focusHighlight
                    : const Color(0xFF22C55E))
                : (AppTheme.isHighContrast
                    ? AppTheme.onColor(type.color)
                    : type.color),
            width: 3,
          ),
          boxShadow: AppTheme.isHighContrast
              ? null
              : isFilled
                  ? [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
        ),
        child: isFilled
            ? TweenAnimationBuilder<double>(
                // Success bounce: scale 0 → 1 with an elastic overshoot.
                key: ValueKey(filledCard!.id),
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Text(
                  filledCard!.label,
                  style: TextStyle(
                    color: AppTheme.isHighContrast
                        ? AppTheme.onColor(type.color)
                        : type.onColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : Center(
                child: Text(
                  type.question,
                  style: TextStyle(
                    color: AppTheme.isHighContrast
                        ? AppTheme.onColor(type.color)
                        : type == SemanticType.whatKind
                            ? type.color
                            : type.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
      ),
    );
  }
}

/// ─── OPTION CARD ─────────────────────────────────────────────────────────────
/// Tappable symbol card filled with its Colourful Semantics colour (same
/// visual language as [SymbolTile]). Shakes when tapped wrongly, glows green
/// when it solves the blank, dims once eliminated.
class _OptionCard extends StatelessWidget {
  final GameCard card;
  final double size;
  final bool isSolved;
  final bool isEliminated;

  /// 0 = idle; any positive change re-triggers the shake animation.
  final int shakeTick;

  final VoidCallback onTap;

  const _OptionCard({
    required this.card,
    required this.size,
    required this.isSolved,
    required this.isEliminated,
    required this.shakeTick,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEliminated ? 0.35 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: card.semanticType.color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            // Cyan in High Contrast: visible on every semantic fill (a green
            // ring would vanish on the green noun cards).
            color: isSolved
                ? (AppTheme.isHighContrast
                    ? AppTheme.focusHighlight
                    : const Color(0xFF22C55E))
                : Colors.black87,
            width: isSolved ? 4 : 1.5,
          ),
          boxShadow: isSolved && !AppTheme.isHighContrast
              ? [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.55),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: _Pictogram(
                keyword: card.pictogramKeyword,
                fallbackIcon: card.fallbackIcon,
                iconColor: card.semanticType.onColor,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                card.label,
                style: TextStyle(
                  color: card.semanticType.onColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: !isEliminated,
      label: 'Option: ${card.label}',
      child: GestureDetector(
        onTap: onTap,
        child: shakeTick > 0 ? _Shake(tick: shakeTick, child: tile) : tile,
      ),
    );
  }
}

/// Gentle horizontal shake — a damped sine wave, re-run whenever [tick]
/// changes so repeated wrong taps each give feedback.
class _Shake extends StatelessWidget {
  final int tick;
  final Widget child;

  const _Shake({required this.tick, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(tick),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.linear,
      builder: (context, t, child) {
        final offset = math.sin(t * math.pi * 4) * 8 * (1 - t);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: child,
    );
  }
}

/// ─── PICTOGRAM RESOLVER ──────────────────────────────────────────────────────
/// Same lookup chain as the communication grid: bundled ARASAAC asset →
/// ARASAAC API → Material icon. Keeps the game fully usable offline for the
/// core vocabulary.
class _Pictogram extends StatelessWidget {
  final String keyword;
  final IconData fallbackIcon;
  final Color iconColor;

  const _Pictogram({
    required this.keyword,
    required this.fallbackIcon,
    required this.iconColor,
  });

  String get _assetPath {
    final searchWord = keyword
        .split('/')[0]
        .replaceAll('?', '')
        .replaceAll("'", '')
        .replaceAll(' ', '_')
        .toLowerCase()
        .trim();
    return 'assets/arasaac/$searchWord.png';
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _NetworkPictogram(
        keyword: keyword,
        fallbackIcon: fallbackIcon,
        iconColor: iconColor,
      ),
    );
  }
}

class _NetworkPictogram extends StatelessWidget {
  final String keyword;
  final IconData fallbackIcon;
  final Color iconColor;

  const _NetworkPictogram({
    required this.keyword,
    required this.fallbackIcon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ArasaacService().getPictogramUrl(keyword),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) {
          return Center(
            child: Icon(fallbackIcon, size: 48, color: iconColor),
          );
        }
        return Image.network(
          url,
          fit: BoxFit.contain,
          // Pictograms render at modest sizes; cap the decoded bitmap size so
          // the image cache doesn't hold full-res copies.
          cacheWidth: 200,
          errorBuilder: (_, _, _) => Center(
            child: Icon(fallbackIcon, size: 48, color: iconColor),
          ),
        );
      },
    );
  }
}

/// ─── COMPLETION VIEW ─────────────────────────────────────────────────────────
class _CompletionView extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onReplay;
  final VoidCallback? onExit;

  const _CompletionView({
    required this.score,
    required this.total,
    required this.onReplay,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: AppTheme.warning,
            size: 96,
          ),
          const SizedBox(height: 16),
          const Text(
            'Great job!',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$score of $total first try',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onReplay,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Play again'),
              ),
              if (onExit != null) ...[
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: onExit,
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Done'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

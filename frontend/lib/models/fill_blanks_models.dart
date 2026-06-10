import 'package:flutter/material.dart';

/// ─── COLOURFUL SEMANTICS SCHEMA ──────────────────────────────────────────────
/// Colour coding follows the Colourful Semantics therapy framework (Bryan).
/// These colours are a clinical convention shared with printed materials, so
/// they are fixed here and must NOT follow the app theme or the grid's
/// category palette.
enum SemanticType {
  /// Subject / noun — "Who?"
  who('Who?', Color(0xFFF97316)),

  /// Action / verb — "Doing?"
  doing('Doing?', Color(0xFFFACC15)),

  /// Object / noun — "What?"
  what('What?', Color(0xFF22C55E)),

  /// Place / prepositional phrase — "Where?"
  where('Where?', Color(0xFF3B82F6)),

  /// Adjective — "What kind?"
  whatKind('What kind?', Color(0xFFF4F4F4));

  const SemanticType(this.question, this.color);

  /// The cue question shown inside an empty blank slot.
  final String question;

  /// The Colourful Semantics colour for borders, card fills and drop zones.
  final Color color;

  /// All schema colours are light pastels, so black text stays readable on
  /// every card — same convention as [SymbolTile].
  Color get onColor => Colors.black87;
}

/// Why a wrong option is wrong. Each question carries one of each kind so the
/// game tests true comprehension, not just colour matching.
enum DistractorKind {
  /// Same colour category as the answer (e.g. "sleeping" vs "eating").
  /// Colour matching alone cannot solve the question.
  semantic,

  /// Different colour category (e.g. a Place card in a Doing slot).
  /// Tests sentence-structure awareness.
  grammatical,
}

/// A tappable word/symbol card shown as an answer option.
class GameCard {
  final String id;

  /// Display text, inflected to read naturally in the sentence ("drinks").
  final String label;

  final SemanticType semanticType;

  /// Resolves to `assets/arasaac/<keyword>.png` first, then the ARASAAC API,
  /// then [fallbackIcon] — same lookup chain as [SymbolTile].
  final String pictogramKeyword;

  final IconData fallbackIcon;

  const GameCard({
    required this.id,
    required this.label,
    required this.semanticType,
    required this.pictogramKeyword,
    this.fallbackIcon = Icons.help_outline,
  });
}

/// One piece of the sentence strip: either fixed text or the single blank.
class SentenceSegment {
  final String? text;

  const SentenceSegment.text(String this.text);
  const SentenceSegment.blank() : text = null;

  bool get isBlank => text == null;
}

/// A single "fill in the blank" round.
class GameQuestion {
  final String id;

  /// Keyword for the target scene image (same lookup chain as card images).
  final String sceneKeyword;

  final IconData sceneFallbackIcon;

  /// The sentence strip. Must contain exactly one blank; the blank takes the
  /// colour of [correctCard]'s semantic type.
  final List<SentenceSegment> segments;

  final GameCard correctCard;

  /// Wrong answer of the SAME colour category as [correctCard].
  final GameCard semanticDistractor;

  /// Wrong answer of a DIFFERENT colour category.
  final GameCard grammaticalDistractor;

  GameQuestion({
    required this.id,
    required this.sceneKeyword,
    required this.segments,
    required this.correctCard,
    required this.semanticDistractor,
    required this.grammaticalDistractor,
    this.sceneFallbackIcon = Icons.image_outlined,
  })  : assert(
          segments.where((s) => s.isBlank).length == 1,
          'A question must have exactly one blank',
        ),
        assert(
          semanticDistractor.semanticType == correctCard.semanticType,
          'The semantic distractor must share the answer\'s colour category',
        ),
        assert(
          grammaticalDistractor.semanticType != correctCard.semanticType,
          'The grammatical distractor must be a different colour category',
        );

  /// The colour category of the missing slot.
  SemanticType get blankType => correctCard.semanticType;

  List<GameCard> get options =>
      [correctCard, semanticDistractor, grammaticalDistractor];

  DistractorKind? distractorKindOf(GameCard card) {
    if (card.id == semanticDistractor.id) return DistractorKind.semantic;
    if (card.id == grammaticalDistractor.id) return DistractorKind.grammatical;
    return null;
  }

  /// Full sentence with the blank resolved — used for TTS reinforcement.
  String get spokenSentence =>
      segments.map((s) => s.isBlank ? correctCard.label : s.text!).join(' ');
}

/// A playable session: an ordered set of questions plus display metadata.
class SentenceGameSession {
  final String id;
  final String title;
  final List<GameQuestion> questions;

  const SentenceGameSession({
    required this.id,
    required this.title,
    required this.questions,
  });

  /// Built-in starter session covering every semantic colour once.
  /// Vocabulary prefers words with bundled ARASAAC assets so the game works
  /// offline; the rest resolve through the ARASAAC API at runtime.
  factory SentenceGameSession.starter() {
    return SentenceGameSession(
      id: 'starter',
      title: 'Fill in the Blanks',
      questions: [
        // Doing? (yellow) — the canonical example shape.
        GameQuestion(
          id: 'q_doing',
          sceneKeyword: 'drink',
          segments: const [
            SentenceSegment.text('The boy'),
            SentenceSegment.blank(),
            SentenceSegment.text('water.'),
          ],
          correctCard: const GameCard(
            id: 'drinks',
            label: 'drinks',
            semanticType: SemanticType.doing,
            pictogramKeyword: 'drink',
            fallbackIcon: Icons.local_drink,
          ),
          semanticDistractor: const GameCard(
            id: 'eats',
            label: 'eats',
            semanticType: SemanticType.doing,
            pictogramKeyword: 'eat',
            fallbackIcon: Icons.restaurant,
          ),
          grammaticalDistractor: const GameCard(
            id: 'at_school',
            label: 'at school',
            semanticType: SemanticType.where,
            pictogramKeyword: 'school',
            fallbackIcon: Icons.school,
          ),
        ),

        // Who? (orange)
        GameQuestion(
          id: 'q_who',
          sceneKeyword: 'eat',
          segments: const [
            SentenceSegment.blank(),
            SentenceSegment.text('eats food.'),
          ],
          correctCard: const GameCard(
            id: 'the_boy',
            label: 'The boy',
            semanticType: SemanticType.who,
            pictogramKeyword: 'boy',
            fallbackIcon: Icons.face,
          ),
          semanticDistractor: const GameCard(
            id: 'the_girl',
            label: 'The girl',
            semanticType: SemanticType.who,
            pictogramKeyword: 'girl',
            fallbackIcon: Icons.face_3,
          ),
          grammaticalDistractor: const GameCard(
            id: 'sleeping',
            label: 'sleeping',
            semanticType: SemanticType.doing,
            pictogramKeyword: 'sleep',
            fallbackIcon: Icons.bedtime,
          ),
        ),

        // What? (green)
        GameQuestion(
          id: 'q_what',
          sceneKeyword: 'water',
          segments: const [
            SentenceSegment.text('I drink'),
            SentenceSegment.blank(),
          ],
          correctCard: const GameCard(
            id: 'water',
            label: 'water',
            semanticType: SemanticType.what,
            pictogramKeyword: 'water',
            fallbackIcon: Icons.water_drop,
          ),
          semanticDistractor: const GameCard(
            id: 'food',
            label: 'food',
            semanticType: SemanticType.what,
            pictogramKeyword: 'food',
            fallbackIcon: Icons.fastfood,
          ),
          grammaticalDistractor: const GameCard(
            id: 'happy_card',
            label: 'happy',
            semanticType: SemanticType.whatKind,
            pictogramKeyword: 'happy',
            fallbackIcon: Icons.sentiment_very_satisfied,
          ),
        ),

        // Where? (blue)
        GameQuestion(
          id: 'q_where',
          sceneKeyword: 'school',
          segments: const [
            SentenceSegment.text('We play'),
            SentenceSegment.blank(),
          ],
          correctCard: const GameCard(
            id: 'at_school2',
            label: 'at school',
            semanticType: SemanticType.where,
            pictogramKeyword: 'school',
            fallbackIcon: Icons.school,
          ),
          semanticDistractor: const GameCard(
            id: 'at_home',
            label: 'at home',
            semanticType: SemanticType.where,
            pictogramKeyword: 'home',
            fallbackIcon: Icons.home,
          ),
          grammaticalDistractor: const GameCard(
            id: 'sad_card',
            label: 'sad',
            semanticType: SemanticType.whatKind,
            pictogramKeyword: 'sad',
            fallbackIcon: Icons.sentiment_dissatisfied,
          ),
        ),

        // What kind? (white)
        GameQuestion(
          id: 'q_whatkind',
          sceneKeyword: 'happy',
          segments: const [
            SentenceSegment.text('The boy is'),
            SentenceSegment.blank(),
          ],
          correctCard: const GameCard(
            id: 'happy',
            label: 'happy',
            semanticType: SemanticType.whatKind,
            pictogramKeyword: 'happy',
            fallbackIcon: Icons.sentiment_very_satisfied,
          ),
          semanticDistractor: const GameCard(
            id: 'sad',
            label: 'sad',
            semanticType: SemanticType.whatKind,
            pictogramKeyword: 'sad',
            fallbackIcon: Icons.sentiment_dissatisfied,
          ),
          grammaticalDistractor: const GameCard(
            id: 'the_girl2',
            label: 'the girl',
            semanticType: SemanticType.who,
            pictogramKeyword: 'girl',
            fallbackIcon: Icons.face_3,
          ),
        ),
      ],
    );
  }
}

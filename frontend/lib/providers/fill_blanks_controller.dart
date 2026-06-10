import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/fill_blanks_models.dart';

/// State machine for one play-through of a [SentenceGameSession].
///
/// UI-agnostic on purpose: the widget layer listens and renders, so the same
/// controller can back a different layout (or a test) without changes.
class FillBlanksController extends ChangeNotifier {
  FillBlanksController({required this.session, Random? random})
      : _random = random ?? Random() {
    _shuffledOptions = _shuffle(currentQuestion.options);
  }

  final SentenceGameSession session;
  final Random _random;

  int _questionIndex = 0;
  List<GameCard> _shuffledOptions = const [];
  GameCard? _selectedAnswer;
  bool? _isCorrect;
  int _wrongAttempts = 0;
  int _score = 0;
  int _shakeTick = 0;
  bool _isComplete = false;

  // ─── READ-ONLY STATE ───────────────────────────────────────────────────────
  GameQuestion get currentQuestion => session.questions[_questionIndex];
  int get questionNumber => _questionIndex + 1;
  int get totalQuestions => session.questions.length;

  /// Options for the current question in a stable shuffled order, so the
  /// correct card isn't always in the same position.
  List<GameCard> get options => _shuffledOptions;

  GameCard? get selectedAnswer => _selectedAnswer;

  /// null = nothing chosen yet, true = blank filled, false = last tap wrong.
  bool? get isCorrect => _isCorrect;

  /// One point per question solved without a wrong tap (errorless-learning
  /// friendly: retries are unlimited and never go negative).
  int get score => _score;

  bool get isComplete => _isComplete;

  /// Increments on every wrong tap; the UI keys its shake animation off this
  /// so tapping the same wrong card twice shakes twice.
  int get shakeTick => _shakeTick;

  /// Cards already tried and found wrong this round (rendered dimmed).
  final Set<String> _eliminatedIds = {};
  bool isEliminated(GameCard card) => _eliminatedIds.contains(card.id);

  // ─── ACTIONS ───────────────────────────────────────────────────────────────
  /// Handle a card tap. Returns true if the tap solved the blank, so callers
  /// can trigger side effects (TTS of the full sentence) without re-deriving.
  bool selectCard(GameCard card) {
    if (_isComplete || _isCorrect == true || isEliminated(card)) return false;

    _selectedAnswer = card;
    if (card.id == currentQuestion.correctCard.id) {
      _isCorrect = true;
      if (_wrongAttempts == 0) _score++;
    } else {
      _isCorrect = false;
      _wrongAttempts++;
      _shakeTick++;
      _eliminatedIds.add(card.id);
    }
    notifyListeners();
    return _isCorrect == true;
  }

  /// Advance after a correct answer; marks the session complete after the
  /// last question.
  void nextQuestion() {
    if (_isCorrect != true || _isComplete) return;

    if (_questionIndex >= session.questions.length - 1) {
      _isComplete = true;
    } else {
      _questionIndex++;
      _resetRound();
    }
    notifyListeners();
  }

  /// Start the whole session over (keeps the same question order).
  void restart() {
    _questionIndex = 0;
    _score = 0;
    _isComplete = false;
    _resetRound();
    notifyListeners();
  }

  void _resetRound() {
    _selectedAnswer = null;
    _isCorrect = null;
    _wrongAttempts = 0;
    _eliminatedIds.clear();
    _shuffledOptions = _shuffle(currentQuestion.options);
  }

  List<GameCard> _shuffle(List<GameCard> cards) {
    final copy = List<GameCard>.from(cards);
    copy.shuffle(_random);
    return copy;
  }
}

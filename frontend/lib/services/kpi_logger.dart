import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// On-device KPI telemetry for the AI smart-suggestion feature.
///
/// This is the frontend counterpart of `backend/kpi/measure_kpis.py`. Instead
/// of replaying a gold benchmark against the deployed endpoint with a manually
/// grabbed bearer token, it measures the SAME KPIs from REAL app usage — every
/// time suggestions are fetched and every time the child actually taps one. No
/// token, no benchmark: just what really happened in the app.
///
/// Every event is appended as one JSON object per line (JSONL) to
/// `<app-documents>/kpi/kpi_events.jsonl`, and a rolling KPI snapshot is
/// rewritten to `<app-documents>/kpi/kpi_summary.json` after each event. Both
/// are also echoed to the console (`debugPrint`) so they show up in
/// `flutter run` / `flutter logs` and work on web, where file IO is skipped.
///
/// KPIs measured (real-usage analogues of the benchmark metrics):
///   KPI 1 — Smart-Suggestion Relevance
///     - Acceptance Rate    : % of fetches where the child tapped >=1 suggestion
///                            (real-usage analogue of benchmark "Hit Rate")
///     - Dislike-Leak Rate  : % of fetches that surfaced a disliked word (guardrail, target 0)
///     - Format-Validity    : % of fetches returning a clean 4-10 item list (guardrail)
///   KPI 2 — Communication Efficiency
///     - Keystroke Savings  : mean (baseline_taps - 1) / baseline_taps over tapped words
///     - Vocab-Expansion    : % of tapped words NOT on the static board
class KpiLogger {
  KpiLogger._();
  static final KpiLogger instance = KpiLogger._();

  // ── static-grid baseline, mirrors backend/kpi/benchmark.json "baseline" ──
  static const int _navTapsToCategoryWord = 4; // taps to reach a board word
  static const int _aiTapsPerWord = 1; // one tap to accept a suggestion
  static const bool _spellIfOffboard = true; // off-board words must be spelt

  /// Labels of the words already reachable on the static board. Registered by
  /// the grid (its single source of truth) so off-board / vocab-expansion can
  /// be judged. Lower-cased for matching.
  final Set<String> _boardVocab = {};

  // ── rolling counters (this session) ──
  int _fetches = 0;
  int _fetchesAccepted = 0; // fetches with >=1 tapped suggestion
  int _dislikeLeaks = 0;
  int _validFormat = 0;
  int _suggestionsTotal = 0;
  final List<double> _ksrValues = [];
  int _tappedWords = 0;
  int _vocabExpansionWords = 0;
  final List<double> _latencies = [];

  int _fetchSeq = 0;
  int? _lastFetchId; // fetch a subsequent tap is attributed to
  bool _lastFetchAccepted = false;

  File? _eventsFile;
  File? _summaryFile;
  bool _initStarted = false;
  Completer<void>? _ready;

  /// The grid registers the static board vocabulary here so KSR / vocab
  /// expansion can tell on-board words from off-board (spelt) ones.
  void setBoardVocabulary(Iterable<String> labels) {
    _boardVocab
      ..clear()
      ..addAll(labels.map(_norm).where((s) => s.isNotEmpty));
  }

  // ─────────────────────── matching helpers (ported) ───────────────────────
  // Mirror measure_kpis.py: lower-case, strip punctuation, collapse whitespace.
  static final RegExp _punct = RegExp(r'[^a-z0-9\s]');
  static final RegExp _ws = RegExp(r'\s+');

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(_punct, ' ').replaceAll(_ws, ' ').trim();

  /// Token-aware, case-insensitive match. Handles plurals/articles
  /// ("Dogs" vs "dog") and multi-word targets ("guinea pig").
  static bool _matches(String suggestion, String target) {
    final s = _norm(suggestion);
    final t = _norm(target);
    if (s.isEmpty || t.isEmpty) return false;
    if (s == t) return true;
    if (t.contains(' ')) return s.contains(t) || t.contains(s);
    return RegExp('\\b${RegExp.escape(t)}s?\\b').hasMatch(s);
  }

  static bool _anyMatch(String suggestion, List<String> targets) =>
      targets.any((t) => _matches(suggestion, t));

  bool _onBoard(String word) =>
      _boardVocab.any((b) => _matches(word, b) || _matches(b, word));

  // ─────────────────────────── event recording ─────────────────────────────

  /// Record a completed suggestion fetch (call only on a real 200 response).
  Future<void> logFetch({
    required String prompt,
    required List<String> suggestions,
    required List<String> likes,
    required List<String> dislikes,
    required int latencyMs,
  }) async {
    final n = suggestions.length;
    final leaked =
        suggestions.where((s) => _anyMatch(s, dislikes)).toList(growable: false);
    final formatValid = n >= 4 && n <= 10;

    _fetches += 1;
    _suggestionsTotal += n;
    if (leaked.isNotEmpty) _dislikeLeaks += 1;
    if (formatValid) _validFormat += 1;
    _latencies.add(latencyMs.toDouble());

    final fetchId = ++_fetchSeq;
    _lastFetchId = fetchId;
    _lastFetchAccepted = false;

    await _write({
      'event': 'fetch',
      'fetch_id': fetchId,
      'prompt': prompt,
      'likes': likes,
      'dislikes': dislikes,
      'suggestions': suggestions,
      'n_suggestions': n,
      'format_valid': formatValid,
      'dislike_leak': leaked.isNotEmpty,
      'leaked_words': leaked,
      'latency_ms': latencyMs,
    });
  }

  /// Record the child accepting a suggestion (tapping a suggestion tile).
  Future<void> logSuggestionTap(String word) async {
    final onBoard = _onBoard(word);
    final int baselineTaps;
    if (onBoard) {
      baselineTaps = _navTapsToCategoryWord;
    } else if (_spellIfOffboard) {
      // Off-board word: a static board would make the user spell it out,
      // char by char (at least as costly as opening a category).
      final letters = _norm(word).replaceAll(' ', '').length;
      baselineTaps = letters > _navTapsToCategoryWord ? letters : _navTapsToCategoryWord;
    } else {
      baselineTaps = _navTapsToCategoryWord;
    }
    final ksr = (baselineTaps - _aiTapsPerWord) / baselineTaps;

    _tappedWords += 1;
    _ksrValues.add(ksr);
    if (!onBoard) _vocabExpansionWords += 1;
    // Attribute the tap to the most recent fetch for the acceptance KPI.
    if (_lastFetchId != null && !_lastFetchAccepted) {
      _lastFetchAccepted = true;
      _fetchesAccepted += 1;
    }

    await _write({
      'event': 'tap',
      'fetch_id': _lastFetchId,
      'word': word,
      'on_board': onBoard,
      'baseline_taps': baselineTaps,
      'ai_taps': _aiTapsPerWord,
      'ksr': double.parse(ksr.toStringAsFixed(4)),
      'vocab_expansion': !onBoard,
    });
  }

  /// Current rolling KPI snapshot (also persisted to kpi_summary.json).
  Map<String, dynamic> snapshot() {
    double pct(int part, int whole) => whole == 0 ? 0.0 : 100.0 * part / whole;
    double mean(List<double> xs) =>
        xs.isEmpty ? 0.0 : xs.reduce((a, b) => a + b) / xs.length;
    double percentile(List<double> xs, double p) {
      if (xs.isEmpty) return 0.0;
      final sorted = [...xs]..sort();
      final i = ((p * sorted.length).ceil() - 1).clamp(0, sorted.length - 1);
      return sorted[i];
    }

    return {
      'samples_fetches': _fetches,
      'samples_taps': _tappedWords,
      // KPI 1 — relevance
      'acceptance_rate': pct(_fetchesAccepted, _fetches),
      'dislike_leak_rate': pct(_dislikeLeaks, _fetches),
      'format_validity_rate': pct(_validFormat, _fetches),
      'avg_suggestions': _fetches == 0 ? 0.0 : _suggestionsTotal / _fetches,
      // KPI 2 — efficiency
      'ksr': 100.0 * mean(_ksrValues),
      'vocab_expansion_rate': pct(_vocabExpansionWords, _tappedWords),
      // supporting — responsiveness
      'latency_p50_ms': percentile(_latencies, 0.50),
      'latency_p95_ms': percentile(_latencies, 0.95),
      'latency_mean_ms': mean(_latencies),
    };
  }

  // ─────────────────────────── persistence ──────────────────────────────────

  Future<void> _ensureFiles() async {
    if (kIsWeb) return; // no file IO on web — console only
    if (_initStarted) return _ready?.future;
    _initStarted = true;
    _ready = Completer<void>();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final kpiDir = Directory('${dir.path}/kpi');
      if (!await kpiDir.exists()) await kpiDir.create(recursive: true);
      _eventsFile = File('${kpiDir.path}/kpi_events.jsonl');
      _summaryFile = File('${kpiDir.path}/kpi_summary.json');
      debugPrint('[KPI] logging to ${kpiDir.path}');
    } catch (e) {
      debugPrint('[KPI] file logging unavailable, console only: $e');
    }
    _ready!.complete();
    return _ready!.future;
  }

  Future<void> _write(Map<String, dynamic> event) async {
    event['ts'] = DateTime.now().toUtc().toIso8601String();
    final line = jsonEncode(event);
    final summary = snapshot();

    // Console (works everywhere, incl. web).
    debugPrint('[KPI] $line');
    debugPrint('[KPI] summary ${jsonEncode(summary)}');

    if (kIsWeb) return;
    await _ensureFiles();
    try {
      await _eventsFile?.writeAsString('$line\n',
          mode: FileMode.append, flush: true);
      await _summaryFile?.writeAsString(
          const JsonEncoder.withIndent('  ').convert(summary),
          flush: true);
    } catch (e) {
      debugPrint('[KPI] failed to write log file: $e');
    }
  }
}

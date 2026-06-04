import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/symbol_tile.dart';

// ─── Public entry point ───────────────────────────────────────────────────────

class NowNextMode extends StatefulWidget {
  final VoidCallback onExit;
  final List<Symbol> availableSymbols;
  final VoidCallback? onSpeak;

  const NowNextMode({
    super.key,
    required this.onExit,
    required this.availableSymbols,
    this.onSpeak,
  });

  @override
  State<NowNextMode> createState() => _NowNextModeState();
}

// ─── Board mode ───────────────────────────────────────────────────────────────

enum _BoardMode { nowNext, sentence }

// ─── State ────────────────────────────────────────────────────────────────────

class _NowNextModeState extends State<NowNextMode> {
  _BoardMode _mode = _BoardMode.nowNext;

  // Now / Next slots — each holds at most one symbol
  Symbol? _now;
  Symbol? _next;

  // Sentence builder — ordered list of symbols
  final List<Symbol> _sentence = [];

  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-GN');
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speakCurrent() async {
    String textToSpeak = '';
    if (_mode == _BoardMode.nowNext) {
      if (_now != null && _next != null) {
        textToSpeak = 'Now ${_now!.label}, then ${_next!.label}';
      } else if (_now != null) {
        textToSpeak = 'Now ${_now!.label}';
      } else if (_next != null) {
        textToSpeak = 'Next ${_next!.label}';
      }
    } else {
      if (_sentence.isNotEmpty) {
        textToSpeak = 'First, I need to ${_sentence.first.label}';
        if (_sentence.length > 1) {
          textToSpeak += ', then I can ${_sentence[1].label}';
        }
      }
    }
    
    if (textToSpeak.isNotEmpty) {
      await _flutterTts.speak(textToSpeak);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _clearAll() => setState(() {
        _now = null;
        _next = null;
        _sentence.clear();
      });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              _Header(
                mode: _mode,
                onModeChanged: (m) => setState(() => _mode = m),
                onClear: _clearAll,
                onSpeak: _speakCurrent,
                onExit: widget.onExit,
              ),

              const SizedBox(height: 16),

              // Main board — fills available space
              Expanded(
                child: _mode == _BoardMode.nowNext
                    ? _NowNextBoard(
                        now: _now,
                        next: _next,
                        availableSymbols: widget.availableSymbols,
                        onNowChanged: (s) => setState(() => _now = s),
                        onNextChanged: (s) => setState(() => _next = s),
                      )
                    : _SentenceBoard(
                        sentence: _sentence,
                        availableSymbols: widget.availableSymbols,
                        onAdd: (s) => setState(() => _sentence.add(s)),
                        onRemove: (i) =>
                            setState(() => _sentence.removeAt(i)),
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _sentence.removeAt(oldIndex);
                            _sentence.insert(newIndex, item);
                          });
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Now / Next board ─────────────────────────────────────────────────────────

class _NowNextBoard extends StatelessWidget {
  final Symbol? now;
  final Symbol? next;
  final List<Symbol> availableSymbols;
  final ValueChanged<Symbol?> onNowChanged;
  final ValueChanged<Symbol?> onNextChanged;

  const _NowNextBoard({
    required this.now,
    required this.next,
    required this.availableSymbols,
    required this.onNowChanged,
    required this.onNextChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final pickerH = constraints.maxHeight * 0.28;
      final boardH = constraints.maxHeight - pickerH - 16;

      return Column(
        children: [
          // Now / Next drop zones
          SizedBox(
            height: boardH,
            child: Row(
              children: [
                Expanded(
                  child: _SingleDropZone(
                    label: 'NOW',
                    labelColor: const Color(0xFF2196F3),
                    symbol: now,
                    onAccept: onNowChanged,
                    onTap: () => onNowChanged(null),
                  ),
                ),
                const SizedBox(width: 16),

                // Arrow between zones
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 40,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),

                const SizedBox(width: 16),
                Expanded(
                  child: _SingleDropZone(
                    label: 'NEXT',
                    labelColor: const Color(0xFF4CAF50),
                    symbol: next,
                    onAccept: onNextChanged,
                    onTap: () => onNextChanged(null),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Symbol picker
          _SymbolPicker(
            symbols: availableSymbols,
            height: pickerH,
          ),
        ],
      );
    });
  }
}

// ─── Single drop zone (Now / Next) ───────────────────────────────────────────

class _SingleDropZone extends StatelessWidget {
  final String label;
  final Color labelColor;
  final Symbol? symbol;
  final ValueChanged<Symbol?> onAccept;
  final VoidCallback onTap; // tap to clear

  const _SingleDropZone({
    required this.label,
    required this.labelColor,
    required this.symbol,
    required this.onAccept,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Symbol>(
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (context, candidateData, _) {
        final highlight = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: highlight ? labelColor : AppTheme.border,
              width: 3,
            ),
          ),
          child: Column(
            children: [
              // Label bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: labelColor.withOpacity(0.15),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17)),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),

              // Symbol or placeholder
              Expanded(
                child: symbol == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 40,
                                color: AppTheme.textSecondary
                                    .withOpacity(0.4)),
                            const SizedBox(height: 8),
                            Text(
                              'Drop activity here',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: onTap,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SymbolTile(
                              symbol: symbol!, onTap: onTap),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Sentence board ───────────────────────────────────────────────────────────

class _SentenceBoard extends StatelessWidget {
  final List<Symbol> sentence;
  final List<Symbol> availableSymbols;
  final ValueChanged<Symbol> onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int, int) onReorder;

  const _SentenceBoard({
    required this.sentence,
    required this.availableSymbols,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final pickerH = constraints.maxHeight * 0.28;
      final sentenceH = constraints.maxHeight - pickerH - 16;

      return Column(
        children: [
          SizedBox(
            height: sentenceH,
            child: _StructuredSentenceStrip(
              sentence: sentence,
              onAdd: onAdd,
              onRemove: onRemove,
            ),
          ),

          const SizedBox(height: 16),

          _SymbolPicker(
            symbols: availableSymbols,
            height: pickerH,
          ),
        ],
      );
    });
  }
}

// ─── Structured sentence strip ───────────────────────────────────────────────

class _StructuredSentenceStrip extends StatelessWidget {
  final List<Symbol> sentence;
  final ValueChanged<Symbol> onAdd;
  final ValueChanged<int> onRemove;

  const _StructuredSentenceStrip({
    required this.sentence,
    required this.onAdd,
    required this.onRemove,
  });

  Symbol? get firstSymbol =>
      sentence.isNotEmpty ? sentence[0] : null;

  Symbol? get secondSymbol =>
      sentence.length > 1 ? sentence[1] : null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _SentenceText('First, I need to'),
              _SentenceDropBox(
                symbol: firstSymbol,
                onAccept: (symbol) {
                  if (sentence.isEmpty) {
                    onAdd(symbol);
                  } else {
                    sentence[0] = symbol;
                  }
                },
                onClear: firstSymbol != null
                    ? () => onRemove(0)
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 28),

          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _SentenceText('Then, I can'),
              _SentenceDropBox(
                symbol: secondSymbol,
                onAccept: (symbol) {
                  if (sentence.length < 2) {
                    onAdd(symbol);
                  } else {
                    sentence[1] = symbol;
                  }
                },
                onClear: secondSymbol != null
                    ? () => onRemove(1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Sentence text ────────────────────────────────────────────────────────────

class _SentenceText extends StatelessWidget {
  final String text;

  const _SentenceText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ─── Sentence drop box ────────────────────────────────────────────────────────

class _SentenceDropBox extends StatelessWidget {
  final Symbol? symbol;
  final ValueChanged<Symbol> onAccept;
  final VoidCallback? onClear;

  const _SentenceDropBox({
    required this.symbol,
    required this.onAccept,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Symbol>(
      onAcceptWithDetails: (details) {
        onAccept(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final highlight = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 140,
          height: 140,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlight
                  ? AppTheme.primary
                  : AppTheme.border,
              width: 3,
            ),
          ),
          child: symbol == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 36,
                      color:
                          AppTheme.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Drop here',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: SymbolTile(
                        symbol: symbol!,
                        onTap: onClear ?? () {},
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
// ─── Shared symbol picker ─────────────────────────────────────────────────────

class _SymbolPicker extends StatelessWidget {
  final List<Symbol> symbols;
  final double height;
  // Optional: if provided, tapping a tile calls this instead of drag-only
  final ValueChanged<Symbol>? onTap;

  const _SymbolPicker({
    required this.symbols,
    required this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        const spacing = 8.0;
        final layout = _bestTileLayout(
          count: symbols.length,
          w: constraints.maxWidth,
          h: constraints.maxHeight,
          spacing: spacing,
          padding: 0,
        );
        final tileSize = layout.tileSize;
        final cols = layout.cols;
        final rows = (symbols.length / cols).ceil();

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(rows, (row) {
            final start = row * cols;
            final end = (start + cols).clamp(0, symbols.length);
            return Padding(
              padding:
                  EdgeInsets.only(bottom: row < rows - 1 ? spacing : 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(end - start, (col) {
                  final symbol = symbols[start + col];
                  return Padding(
                    padding: EdgeInsets.only(
                        right:
                            col < (end - start) - 1 ? spacing : 0),
                    child: SizedBox(
                      width: tileSize,
                      height: tileSize,
                      child: Draggable<Symbol>(
                        data: symbol,
                        feedback: SizedBox(
                          width: tileSize,
                          height: tileSize,
                          child: Material(
                            color: Colors.transparent,
                            child: SymbolTile(
                                symbol: symbol, onTap: () {}),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.4,
                          child:
                              SymbolTile(symbol: symbol, onTap: () {}),
                        ),
                        child: SymbolTile(
                          symbol: symbol,
                          onTap: onTap != null
                              ? () => onTap!(symbol)
                              : () {},
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      }),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final _BoardMode mode;
  final ValueChanged<_BoardMode> onModeChanged;
  final VoidCallback onClear;
  final VoidCallback? onSpeak;
  final VoidCallback onExit;

  const _Header({
    required this.mode,
    required this.onModeChanged,
    required this.onClear,
    required this.onExit,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(
            'Now & Next',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),

        // Mode toggle
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleChip(
                label: 'Now / Next',
                selected: mode == _BoardMode.nowNext,
                onTap: mode != _BoardMode.nowNext
                    ? () => onModeChanged(_BoardMode.nowNext)
                    : null,
              ),
              _ToggleChip(
                label: 'Sentence',
                selected: mode == _BoardMode.sentence,
                onTap: mode != _BoardMode.sentence
                    ? () => onModeChanged(_BoardMode.sentence)
                    : null,
              ),
            ],
          ),
        ),

        IconButton(
            onPressed: onSpeak, icon: const Icon(Icons.volume_up)),
        IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline)),
        IconButton(onPressed: onExit, icon: const Icon(Icons.close)),
      ],
    );
  }
}

// ─── Toggle chip (same pattern as schedule page) ─────────────────────────────

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ToggleChip(
      {required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Layout helper (identical to schedule_mode.dart) ─────────────────────────

({double tileSize, int cols}) _bestTileLayout({
  required int count,
  required double w,
  required double h,
  required double spacing,
  required double padding,
}) {
  if (count == 0) return (tileSize: 0, cols: 1);
  final innerW = w - padding * 2;
  final innerH = h - padding * 2;
  double bestSize = 0;
  int bestCols = 1;
  for (int c = 1; c <= count; c++) {
    final rows = (count / c).ceil();
    final tileW = (innerW - spacing * (c - 1)) / c;
    final tileH = (innerH - spacing * (rows - 1)) / rows;
    final size = tileW < tileH ? tileW : tileH;
    if (size > bestSize) {
      bestSize = size;
      bestCols = c;
    }
  }
  return (tileSize: bestSize, cols: bestCols);
}
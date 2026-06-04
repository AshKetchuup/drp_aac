import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'symbol_tile.dart';

class ScheduleMode extends StatefulWidget {
  final VoidCallback onExit;
  final List<Symbol> availableSymbols;
  final VoidCallback? onSpeakSchedule;

  const ScheduleMode({
    super.key,
    required this.onExit,
    required this.availableSymbols,
    this.onSpeakSchedule,
  });

  @override
  State<ScheduleMode> createState() => _ScheduleModeState();
}

enum TimeSlot { morning, afternoon, evening }

extension TimeSlotLabel on TimeSlot {
  String get label => switch (this) {
        TimeSlot.morning => '🌅 Morning',
        TimeSlot.afternoon => '☀️ Afternoon',
        TimeSlot.evening => '🌙 Evening',
      };
}

const List<String> _kDays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

typedef SlotKey = (int, TimeSlot);

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

class _ScheduleModeState extends State<ScheduleMode> {
  late final Map<SlotKey, List<Symbol>> _schedule = {
    for (var d = 0; d < _kDays.length; d++)
      for (final slot in TimeSlot.values) (d, slot): [],
  };

  bool _weekView = true;

  // Default to today; clamp to Mon–Sun range
  int _currentDayIndex = () {
    final wd = DateTime.now().weekday; // 1=Mon … 7=Sun
    return wd - 1;
  }();

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
    int dayToSpeak = _weekView ? (DateTime.now().weekday - 1) : _currentDayIndex;
    String dayName = _kDays[dayToSpeak];
    String textToSpeak = 'On $dayName, ';
    
    for (final slot in TimeSlot.values) {
      final symbols = _schedule[(dayToSpeak, slot)] ?? [];
      if (symbols.isNotEmpty) {
        textToSpeak += 'in the ${slot.name}, ';
        textToSpeak += symbols.map((s) => s.label).join(' and ');
        textToSpeak += '. ';
      }
    }
    
    if (textToSpeak.length > 'On $dayName, '.length) {
      await _flutterTts.speak(textToSpeak);
    } else {
      await _flutterTts.speak('Nothing is scheduled for $dayName');
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _removeItem(SlotKey key, int index) =>
      setState(() => _schedule[key]!.removeAt(index));

  void _clearSchedule() => setState(() {
        for (final key in _schedule.keys) {
          _schedule[key]!.clear();
        }
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
              _Header(
                onExit: widget.onExit,
                onClear: _clearSchedule,
                onSpeak: _speakCurrent,
                weekView: _weekView,
                onToggleView: () => setState(() => _weekView = !_weekView),
              ),

              const SizedBox(height: 16),

              // Symbol picker
              Container(
                height: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 8.0;
                    final layout = _bestTileLayout(
                      count: widget.availableSymbols.length,
                      w: constraints.maxWidth,
                      h: constraints.maxHeight,
                      spacing: spacing,
                      padding: 0,
                    );
                    final tileSize = layout.tileSize;
                    final cols = layout.cols;
                    final rows =
                        (widget.availableSymbols.length / cols).ceil();

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(rows, (row) {
                        final start = row * cols;
                        final end = (start + cols)
                            .clamp(0, widget.availableSymbols.length);
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: row < rows - 1 ? spacing : 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(end - start, (col) {
                              final symbol =
                                  widget.availableSymbols[start + col];
                              return Padding(
                                padding: EdgeInsets.only(
                                    right: col < (end - start) - 1
                                        ? spacing
                                        : 0),
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
                                      child: SymbolTile(
                                          symbol: symbol, onTap: () {}),
                                    ),
                                    child: SymbolTile(
                                        symbol: symbol, onTap: () {}),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (_weekView) {
                      return _WeekGrid(
                        schedule: _schedule,
                        availableWidth: constraints.maxWidth,
                        availableHeight: constraints.maxHeight,
                        onAccept: (key, symbol) =>
                            setState(() => _schedule[key]!.add(symbol)),
                        onRemove: _removeItem,
                      );
                    } else {
                      return _DayView(
                        schedule: _schedule,
                        dayIndex: _currentDayIndex,
                        availableWidth: constraints.maxWidth,
                        availableHeight: constraints.maxHeight,
                        onAccept: (key, symbol) =>
                            setState(() => _schedule[key]!.add(symbol)),
                        onRemove: _removeItem,
                        onDayChanged: (d) =>
                            setState(() => _currentDayIndex = d),
                      );
                    }
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

// ─── Week grid (unchanged logic, same as before) ────────────────────────────

class _WeekGrid extends StatelessWidget {
  final Map<SlotKey, List<Symbol>> schedule;
  final double availableWidth;
  final double availableHeight;
  final void Function(SlotKey, Symbol) onAccept;
  final void Function(SlotKey, int) onRemove;

  const _WeekGrid({
    required this.schedule,
    required this.availableWidth,
    required this.availableHeight,
    required this.onAccept,
    required this.onRemove,
  });

  static const double _labelColWidth = 90;
  static const double _headerRowHeight = 36;
  static const int _numDays = 7;
  static const int _numSlots = 3;

  @override
  Widget build(BuildContext context) {
    final dayColWidth = (availableWidth - _labelColWidth) / _numDays;
    final slotRowHeight = (availableHeight - _headerRowHeight) / _numSlots;

    return Column(
      children: [
        SizedBox(
          height: _headerRowHeight,
          child: Row(
            children: [
              SizedBox(width: _labelColWidth),
              ..._kDays.map((day) => SizedBox(
                    width: dayColWidth,
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
        ...TimeSlot.values.map((slot) => SizedBox(
              height: slotRowHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: _labelColWidth,
                    child: Center(
                      child: Text(
                        slot.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  ..._kDays.asMap().entries.map((entry) {
                    final key = (entry.key, slot);
                    const cellPad = 4.0;
                    final cellW = dayColWidth - cellPad * 2;
                    final cellH = slotRowHeight - cellPad * 2;
                    return _DropCell(
                      key: ValueKey(key),
                      slotKey: key,
                      symbols: schedule[key]!,
                      cellW: cellW,
                      cellH: cellH,
                      cellPad: cellPad,
                      onAccept: onAccept,
                      onRemove: onRemove,
                    );
                  }),
                ],
              ),
            )),
      ],
    );
  }
}

// ─── Day view ────────────────────────────────────────────────────────────────

class _DayView extends StatelessWidget {
  final Map<SlotKey, List<Symbol>> schedule;
  final int dayIndex;
  final double availableWidth;
  final double availableHeight;
  final void Function(SlotKey, Symbol) onAccept;
  final void Function(SlotKey, int) onRemove;
  final void Function(int) onDayChanged;

  const _DayView({
    required this.schedule,
    required this.dayIndex,
    required this.availableWidth,
    required this.availableHeight,
    required this.onAccept,
    required this.onRemove,
    required this.onDayChanged,
  });

  static const double _headerRowHeight = 52;
  static const double _labelColWidth = 90;
  static const int _numSlots = 3;

  @override
  Widget build(BuildContext context) {
    final slotRowHeight =
        (availableHeight - _headerRowHeight) / _numSlots;
    // Each slot row is one wide cell minus the label column
    final cellW = availableWidth - _labelColWidth - 8; // 8 = 2×cellPad
    final cellH = slotRowHeight - 8;

    return Column(
      children: [
        // Day selector
        SizedBox(
          height: _headerRowHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: dayIndex > 0
                    ? () => onDayChanged(dayIndex - 1)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                _kDays[dayIndex],
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: dayIndex < _kDays.length - 1
                    ? () => onDayChanged(dayIndex + 1)
                    : null,
              ),
            ],
          ),
        ),

        // One row per time slot, full width
        ...TimeSlot.values.map((slot) {
          final key = (dayIndex, slot);
          return SizedBox(
            height: slotRowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _labelColWidth,
                  child: Center(
                    child: Text(
                      slot.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                _DropCell(
                  key: ValueKey(key),
                  slotKey: key,
                  symbols: schedule[key]!,
                  cellW: cellW,
                  cellH: cellH,
                  cellPad: 4,
                  onAccept: onAccept,
                  onRemove: onRemove,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Shared drop cell ─────────────────────────────────────────────────────────

class _DropCell extends StatelessWidget {
  final SlotKey slotKey;
  final List<Symbol> symbols;
  final double cellW;
  final double cellH;
  final double cellPad;
  final void Function(SlotKey, Symbol) onAccept;
  final void Function(SlotKey, int) onRemove;

  const _DropCell({
    super.key,
    required this.slotKey,
    required this.symbols,
    required this.cellW,
    required this.cellH,
    required this.cellPad,
    required this.onAccept,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(cellPad),
      child: DragTarget<Symbol>(
        onAcceptWithDetails: (details) => onAccept(slotKey, details.data),
        builder: (context, candidateData, _) {
          return Container(
            width: cellW,
            height: cellH,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? AppTheme.primary
                    : AppTheme.border,
                width: 2,
              ),
            ),
            child: symbols.isEmpty
                ? Center(
                    child: Text(
                      'Drop here',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  )
                : _SlotCellContents(
                    symbols: symbols,
                    cellWidth: cellW,
                    cellHeight: cellH,
                    onRemove: (i) => onRemove(slotKey, i),
                  ),
          );
        },
      ),
    );
  }
}

// ─── Tile layout inside a cell ───────────────────────────────────────────────

class _SlotCellContents extends StatelessWidget {
  final List<Symbol> symbols;
  final double cellWidth;
  final double cellHeight;
  final void Function(int) onRemove;

  const _SlotCellContents({
    required this.symbols,
    required this.cellWidth,
    required this.cellHeight,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const borderWidth = 2.0;
    const innerPad = 4.0;
    const spacing = 4.0;

    final contentW = cellWidth - borderWidth * 2 - innerPad * 2;
    final contentH = cellHeight - borderWidth * 2 - innerPad * 2;

    final layout = _bestTileLayout(
      count: symbols.length,
      w: contentW,
      h: contentH,
      spacing: spacing,
      padding: 0,
    );

    final tileSize = layout.tileSize;
    final cols = layout.cols;
    final rows = (symbols.length / cols).ceil();

    return Padding(
      padding: const EdgeInsets.all(innerPad),
      child: Column(
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
                final index = start + col;
                return Padding(
                  padding: EdgeInsets.only(
                      right: col < (end - start) - 1 ? spacing : 0),
                  child: SizedBox(
                    width: tileSize,
                    height: tileSize,
                    child: SymbolTile(
                      symbol: symbols[index],
                      onTap: () => onRemove(index),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onExit;
  final VoidCallback onClear;
  final VoidCallback? onSpeak;
  final bool weekView;
  final VoidCallback onToggleView;

  const _Header({
    required this.onExit,
    required this.onClear,
    required this.weekView,
    required this.onToggleView,
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
            'Visual Schedule',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),

        // Day / Week toggle
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
                label: 'Day',
                selected: !weekView,
                onTap: weekView ? onToggleView : null,
              ),
              _ToggleChip(
                label: 'Week',
                selected: weekView,
                onTap: !weekView ? onToggleView : null,
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

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

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
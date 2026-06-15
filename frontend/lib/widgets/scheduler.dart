// lib/screens/schedule_mode.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/symbol_tile.dart';
import '../widgets/now_next_display.dart'; // Ensure this matches your file location
import '../providers/aac_provider.dart';

enum TimeSlot { morning, afternoon, evening }

extension TimeSlotLabel on TimeSlot {
  String get label => switch (this) {
    TimeSlot.morning => '🌅 Morning',
    TimeSlot.afternoon => '☀️ Afternoon',
    TimeSlot.evening => '🌙 Evening',
  };
}

const List<String> _kDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

typedef SlotKey = (int, TimeSlot);

// ─── View Modes ───────────────────────────────────────────────────────────────
enum ScheduleViewMode { nowNext, day, week }

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

class ScheduleMode extends StatefulWidget {
  final VoidCallback onExit;
  final List<Symbol> availableSymbols;
  final VoidCallback? onSpeakSchedule;
  final ScheduleViewMode initialView;

  const ScheduleMode({
    super.key,
    required this.onExit,
    required this.availableSymbols,
    this.onSpeakSchedule,
    this.initialView = ScheduleViewMode.week,
  });

  @override
  State<ScheduleMode> createState() => _ScheduleModeState();
}

class _ScheduleModeState extends State<ScheduleMode> {
  // Controlled view state defaulted to initialView
  late ScheduleViewMode _currentView = widget.initialView;

  // Default to today; clamp to Mon–Sun range
  int _currentDayIndex = () {
    final wd = DateTime.now().weekday; // 1=Mon … 7=Sun
    return wd - 1;
  }();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        Provider.of<AACProvider>(context, listen: false).loadSchedule();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AACProvider>(
      builder: (context, provider, child) {
        final currentSchedule = provider.schedule;
        final nowNextData = provider.calculateNowNext();

        return Material(
          color: AppTheme.background,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _Header(
                    onExit: widget.onExit,
                    onClear: () => provider.clearSchedule(),
                    currentView: _currentView,
                    onViewChanged: (newMode) =>
                        setState(() => _currentView = newMode),
                    onSpeak: () {
                      final sentences = <String>[];

                      if (_currentView == ScheduleViewMode.nowNext) {
                        final nowText = nowNextData.now != null
                            ? "Now ${nowNextData.now!.label}."
                            : "";
                        final nextText = nowNextData.next != null
                            ? "Next ${nowNextData.next!.label}."
                            : "";
                        sentences.add("$nowText $nextText".trim());
                      } else if (_currentView == ScheduleViewMode.week) {
                        for (int d = 0; d < _kDays.length; d++) {
                          final dayName = _kDays[d];
                          final morning =
                              currentSchedule[(d, TimeSlot.morning)] ?? [];
                          final afternoon =
                              currentSchedule[(d, TimeSlot.afternoon)] ?? [];
                          final evening =
                              currentSchedule[(d, TimeSlot.evening)] ?? [];

                          if (morning.isNotEmpty ||
                              afternoon.isNotEmpty ||
                              evening.isNotEmpty) {
                            sentences.add("On $dayName.");
                            if (morning.isNotEmpty) {
                              sentences.add(
                                "In the morning: ${morning.map((s) => s.label).join(', ')}.",
                              );
                            }
                            if (afternoon.isNotEmpty) {
                              sentences.add(
                                "In the afternoon: ${afternoon.map((s) => s.label).join(', ')}.",
                              );
                            }
                            if (evening.isNotEmpty) {
                              sentences.add(
                                "In the evening: ${evening.map((s) => s.label).join(', ')}.",
                              );
                            }
                          }
                        }
                      } else {
                        final dayName = _kDays[_currentDayIndex];
                        final morning =
                            currentSchedule[(
                              _currentDayIndex,
                              TimeSlot.morning,
                            )] ??
                            [];
                        final afternoon =
                            currentSchedule[(
                              _currentDayIndex,
                              TimeSlot.afternoon,
                            )] ??
                            [];
                        final evening =
                            currentSchedule[(
                              _currentDayIndex,
                              TimeSlot.evening,
                            )] ??
                            [];

                        sentences.add("For $dayName.");
                        if (morning.isNotEmpty) {
                          sentences.add(
                            "In the morning: ${morning.map((s) => s.label).join(', ')}.",
                          );
                        }
                        if (afternoon.isNotEmpty) {
                          sentences.add(
                            "In the afternoon: ${afternoon.map((s) => s.label).join(', ')}.",
                          );
                        }
                        if (evening.isNotEmpty) {
                          sentences.add(
                            "In the evening: ${evening.map((s) => s.label).join(', ')}.",
                          );
                        }
                      }

                      if (sentences.isEmpty ||
                          sentences.join(' ').trim().isEmpty) {
                        provider.speak("The schedule is empty.");
                      } else {
                        provider.speak(sentences.join(' '));
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Symbol picker (Hidden entirely when viewing the dedicated Now/Next screen)
                  if (_currentView != ScheduleViewMode.nowNext) ...[
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
                          final rows = (widget.availableSymbols.length / cols)
                              .ceil();

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(rows, (row) {
                              final start = row * cols;
                              final end = (start + cols).clamp(
                                0,
                                widget.availableSymbols.length,
                              );
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: row < rows - 1 ? spacing : 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(end - start, (col) {
                                    final symbol =
                                        widget.availableSymbols[start + col];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: col < (end - start) - 1
                                            ? spacing
                                            : 0,
                                      ),
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
                                                symbol: symbol,
                                                onTap: () {},
                                              ),
                                            ),
                                          ),
                                          childWhenDragging: Opacity(
                                            opacity: 0.4,
                                            child: SymbolTile(
                                              symbol: symbol,
                                              onTap: () {},
                                            ),
                                          ),
                                          child: SymbolTile(
                                            symbol: symbol,
                                            onTap: () {},
                                          ),
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
                  ],

                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        switch (_currentView) {
                          case ScheduleViewMode.week:
                            return _WeekGrid(
                              schedule: currentSchedule,
                              availableWidth: constraints.maxWidth,
                              availableHeight: constraints.maxHeight,
                              onAccept: (key, symbol) =>
                                  provider.addToSchedule(key, symbol),
                              onRemove: (key, index) =>
                                  provider.removeFromSchedule(key, index),
                            );
                          case ScheduleViewMode.day:
                            return _DayView(
                              schedule: currentSchedule,
                              dayIndex: _currentDayIndex,
                              availableWidth: constraints.maxWidth,
                              availableHeight: constraints.maxHeight,
                              onAccept: (key, symbol) =>
                                  provider.addToSchedule(key, symbol),
                              onRemove: (key, index) =>
                                  provider.removeFromSchedule(key, index),
                              onDayChanged: (d) =>
                                  setState(() => _currentDayIndex = d),
                            );
                          case ScheduleViewMode.nowNext:
                            return NowNextDisplay(
                              now: nowNextData.now,
                              next: nowNextData.next,
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
      },
    );
  }
}

// ─── Week grid ───────────────────────────────────────────────────────────────

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
              ..._kDays.map(
                (day) => SizedBox(
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
                ),
              ),
            ],
          ),
        ),
        ...TimeSlot.values.map(
          (slot) => SizedBox(
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
                    symbols: schedule[key] ?? [],
                    cellW: cellW,
                    cellH: cellH,
                    cellPad: cellPad,
                    onAccept: onAccept,
                    onRemove: onRemove,
                  );
                }),
              ],
            ),
          ),
        ),
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
    final slotRowHeight = (availableHeight - _headerRowHeight) / _numSlots;
    final cellW = availableWidth - _labelColWidth - 8;
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
                  symbols: schedule[key] ?? [],
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
        onWillAcceptWithDetails: (d) => true,
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
                    ? (AppTheme.isHighContrast
                        ? AppTheme.focusHighlight
                        : AppTheme.primary)
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
            padding: EdgeInsets.only(bottom: row < rows - 1 ? spacing : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(end - start, (col) {
                final index = start + col;
                return Padding(
                  padding: EdgeInsets.only(
                    right: col < (end - start) - 1 ? spacing : 0,
                  ),
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
  final ScheduleViewMode currentView;
  final ValueChanged<ScheduleViewMode> onViewChanged;

  const _Header({
    required this.onExit,
    required this.onClear,
    required this.currentView,
    required this.onViewChanged,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onExit, icon: const Icon(Icons.arrow_back)),
        const SizedBox(width: 4),
        Text(
          'Visual Schedule',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),

        // Unified Tri-State Segment Toggle Control
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
                selected: currentView == ScheduleViewMode.day,
                onTap: () => onViewChanged(ScheduleViewMode.day),
              ),
              _ToggleChip(
                label: 'Week',
                selected: currentView == ScheduleViewMode.week,
                onTap: () => onViewChanged(ScheduleViewMode.week),
              ),
              _ToggleChip(
                label: 'Now / Next',
                selected: currentView == ScheduleViewMode.nowNext,
                onTap: () => onViewChanged(ScheduleViewMode.nowNext),
              ),
            ],
          ),
        ),

        IconButton(onPressed: onSpeak, icon: const Icon(Icons.volume_up)),
        IconButton(onPressed: onClear, icon: const Icon(Icons.delete_outline)),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ToggleChip({required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            // Dark ink on the lime selected chip — white was unreadable on the
            // light-green fill. onColor picks the higher-contrast ink for both
            // the Dark and High Contrast palettes.
            color: selected
                ? AppTheme.onColor(AppTheme.primary)
                : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

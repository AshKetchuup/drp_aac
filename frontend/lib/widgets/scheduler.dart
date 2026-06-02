import 'package:flutter/material.dart';

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

class _ScheduleModeState extends State<ScheduleMode> {
  final List<Symbol> _schedule = [];

  void _removeItem(int index) {
    setState(() {
      _schedule.removeAt(index);
    });
  }

  void _clearSchedule() {
    setState(() {
      _schedule.clear();
    });
  }

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
                onSpeak: widget.onSpeakSchedule,
              ),

              const SizedBox(height: 16),

              Container(
                height: 180,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: GridView.builder(
                  itemCount: widget.availableSymbols.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final symbol = widget.availableSymbols[index];

                    return Draggable<Symbol>(
                      data: symbol,
                      feedback: SizedBox(
                        width: 100,
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
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: DragTarget<Symbol>(
                  onAcceptWithDetails: (details) {
                    setState(() {
                      _schedule.add(details.data);
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: candidateData.isNotEmpty
                              ? AppTheme.primary
                              : AppTheme.border,
                          width: 2,
                        ),
                      ),
                      child: _schedule.isEmpty
                          ? Center(
                              child: Text(
                                'Drag symbols here to build a schedule',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _schedule.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final symbol = _schedule[index];

                                return SizedBox(
                                  width: 140,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: SymbolTile(
                                          symbol: symbol,
                                          onTap: () =>
                                              _removeItem(index),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    );
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

class _Header extends StatelessWidget {
  final VoidCallback onExit;
  final VoidCallback onClear;
  final VoidCallback? onSpeak;

  const _Header({
    required this.onExit,
    required this.onClear,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
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

        IconButton(
          onPressed: onSpeak,
          icon: const Icon(Icons.volume_up),
        ),

        IconButton(
          onPressed: onClear,
          icon: const Icon(Icons.delete_outline),
        ),

        IconButton(
          onPressed: onExit,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}
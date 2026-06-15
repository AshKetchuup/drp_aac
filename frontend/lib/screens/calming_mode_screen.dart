import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:frontend/screens/debrief_mode_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/symbol_grid_section.dart';
import '../widgets/symbol_tile.dart';
import '../models/models.dart';

const _emotions = [
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
    icon: Icons.mood_bad,
    category: SymbolCategory.feeling,
  ),
  Symbol(
    id: 'scared',
    label: 'Scared',
    icon: Icons.warning_rounded,
    category: SymbolCategory.feeling,
  ),
  Symbol(
    id: 'tired',
    label: 'Tired',
    icon: Icons.bedtime,
    category: SymbolCategory.feeling,
  ),
  Symbol(
    id: 'calm',
    label: 'Calm',
    icon: Icons.spa,
    category: SymbolCategory.feeling,
  ),
  Symbol(
    id: 'frustrated',
    label: 'Frustrated',
    icon: Icons.sentiment_very_dissatisfied,
    category: SymbolCategory.feeling,
  ),
  Symbol(
    id: 'confused',
    label: 'Confused',
    icon: Icons.psychology_alt,
    category: SymbolCategory.feeling,
  ),
];

const _zones = [
  Symbol(
    id: 'green_zone',
    label: 'Green Zone',
    icon: Icons.sentiment_satisfied,
    category: SymbolCategory.folder,
  ),
  Symbol(
    id: 'blue_zone',
    label: 'Blue Zone',
    icon: Icons.battery_1_bar,
    category: SymbolCategory.folder,
  ),
  Symbol(
    id: 'yellow_zone',
    label: 'Yellow Zone',
    icon: Icons.warning_amber_rounded,
    category: SymbolCategory.folder,
  ),
  Symbol(
    id: 'red_zone',
    label: 'Red Zone',
    icon: Icons.stop_circle_outlined,
    category: SymbolCategory.folder,
  ),
];

const _zoneEmotions = {
  'blue_zone': ['sad', 'tired'],
  'green_zone': ['happy', 'calm'],
  'yellow_zone': ['frustrated', 'confused'],
  'red_zone': ['angry', 'scared'],
};

const _zoneColors = {
  'green_zone': Color(0xFF22C55E),
  'blue_zone': Color(0xFF3B82F6),
  'yellow_zone': Color(0xFFFACC15),
  'red_zone': Color(0xFFEF4444),
};

const _emotionColors = {
  'happy': Color(0xFF22C55E),
  'calm': Color(0xFF22C55E),
  'sad': Color(0xFF3B82F6),
  'tired': Color(0xFF3B82F6),
  'frustrated': Color(0xFFFACC15),
  'confused': Color(0xFFFACC15),
  'angry': Color(0xFFEF4444),
  'scared': Color(0xFFEF4444),
};

const _needs = [
  Symbol(
    id: 'outside',
    label: 'Go outside',
    icon: Icons.park,
    category: SymbolCategory.activity,
  ),
  Symbol(
    id: 'play',
    label: 'Play',
    icon: Icons.sports_esports,
    category: SymbolCategory.activity,
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
    id: 'toilet',
    label: 'Toilet',
    icon: Icons.wc,
    category: SymbolCategory.verb,
  ),
  Symbol(
    id: 'rest',
    label: 'Rest',
    icon: Icons.king_bed,
    category: SymbolCategory.verb,
  ),
  Symbol(
    id: 'hug',
    label: 'A hug',
    icon: Icons.favorite,
    category: SymbolCategory.feeling,
  ),
  Symbol(
    id: 'help',
    label: 'Help',
    icon: Icons.pan_tool,
    category: SymbolCategory.feeling,
  ),
];

class CalmingModeScreen extends StatefulWidget {
  const CalmingModeScreen({super.key});

  @override
  State<CalmingModeScreen> createState() => _CalmingModeScreenState();
}

class _CalmingModeScreenState extends State<CalmingModeScreen> {
  final FlutterTts _tts = FlutterTts();
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.4);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  void _speak(String text) => _tts.speak(text);

  void _goToPage(int page) {
    setState(() {});
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics:
              const NeverScrollableScrollPhysics(), // controlled by buttons only
          onPageChanged: (page) => setState(() {}),
          children: [
            _ZoneAndFeelPage(
              onSpeak: _speak,
              onBack: () => Navigator.pop(context),
              onNext: () => _goToPage(1),
            ),
            _WantPage(
              onSpeak: _speak,
              onBack: () => _goToPage(0),
              onFeelBetter: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DebriefModeScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 0: Zones & Feelings ───────────────────────────────────────────────────

class _ZoneAndFeelPage extends StatefulWidget {
  final void Function(String) onSpeak;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _ZoneAndFeelPage({
    required this.onSpeak,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<_ZoneAndFeelPage> createState() => _ZoneAndFeelPageState();
}

class _ZoneAndFeelPageState extends State<_ZoneAndFeelPage> {
  String? _selectedZoneId;

  @override
  Widget build(BuildContext context) {
    final List<Symbol> filteredEmotions = _selectedZoneId != null
        ? _emotions.where((e) => _zoneEmotions[_selectedZoneId]!.contains(e.id)).toList()
        : <Symbol>[];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _Header(title: 'Calming Mode', onBack: widget.onBack),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Pane: Zones Sidebar
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: List.generate(_zones.length, (index) {
                        final zone = _zones[index];
                        final isSelected = _selectedZoneId == zone.id;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: index < _zones.length - 1 ? 8.0 : 0,
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // To prevent massive squares on very wide screens or awkward fitting, 
                                // we ensure it tries to be square but doesn't overflow.
                                return Center(
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: SymbolTile(
                                      symbol: zone,
                                      isSelected: isSelected,
                                      overrideBackgroundColor: _zoneColors[zone.id],
                                      onTap: () => setState(() => _selectedZoneId = zone.id),
                                    ),
                                  ),
                                );
                              }
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Right Pane: Emotions Detail
                Expanded(
                  flex: 2,
                  child: _selectedZoneId == null
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Center(
                            child: Text(
                              'Select a zone to see feelings.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        )
                      : SymbolGridSection(
                          title: 'I feel...',
                          items: filteredEmotions,
                          onTap: widget.onSpeak,
                          overrideItemColors: _emotionColors,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _BottomButton(
            label: 'I want...',
            onTap: widget.onNext,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }
}

// ── Page 1: I want ────────────────────────────────────────────────────────────

class _WantPage extends StatelessWidget {
  final void Function(String) onSpeak;
  final VoidCallback onBack;
  final VoidCallback onFeelBetter;

  const _WantPage({
    required this.onSpeak,
    required this.onBack,
    required this.onFeelBetter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _Header(title: 'Calming Mode', onBack: onBack),
          const SizedBox(height: 16),
          Expanded(
            child: SymbolGridSection(
              title: 'I want...',
              items: _needs,
              onTap: onSpeak,
            ),
          ),
          const SizedBox(height: 16),
          _BottomButton(
            label: 'I feel better',
            onTap: onFeelBetter,
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  const _BottomButton({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.isHighContrast
              ? AppTheme.surfaceLight
              : AppTheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.isHighContrast
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, color: AppTheme.primary, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

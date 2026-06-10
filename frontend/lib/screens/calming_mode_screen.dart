import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:frontend/screens/debrief_mode_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/symbol_grid_section.dart';
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
    id: 'excited',
    label: 'Excited',
    icon: Icons.celebration,
    category: SymbolCategory.feeling,
  ),
  Symbol(
    id: 'confused',
    label: 'Confused',
    icon: Icons.help_outline,
    category: SymbolCategory.feeling,
  ),
];

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
    id: 'toilet',
    label: 'Toilet',
    icon: Icons.wc,
    category: SymbolCategory.verb,
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
  int _currentPage = 0;

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
    setState(() => _currentPage = page);
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
          onPageChanged: (page) => setState(() => _currentPage = page),
          children: [
            _FeelPage(
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

// ── Page 1: I feel ────────────────────────────────────────────────────────────

class _FeelPage extends StatelessWidget {
  final void Function(String) onSpeak;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _FeelPage({
    required this.onSpeak,
    required this.onBack,
    required this.onNext,
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
              title: 'I feel...',
              items: _emotions,
              onTap: onSpeak,
              overrideItemColors: const {
                'happy': Color(0xFF22C55E), // Green Zone
                'calm': Color(0xFF22C55E),  // Green Zone
                'sad': Color(0xFF3B82F6),   // Blue Zone
                'tired': Color(0xFF3B82F6), // Blue Zone
                'excited': Color(0xFFFACC15), // Yellow Zone
                'confused': Color(0xFFFACC15), // Yellow Zone
                'angry': Color(0xFFEF4444), // Red Zone
                'scared': Color(0xFFEF4444), // Red Zone
              },
            ),
          ),
          const SizedBox(height: 16),
          _BottomButton(
            label: 'I want...',
            onTap: onNext,
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }
}

// ── Page 2: I want ────────────────────────────────────────────────────────────

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
        GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.arrow_back, color: AppTheme.textSecondary, size: 18),
                SizedBox(width: 6),
                Text(
                  'Back',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
          color: AppTheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6)),
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

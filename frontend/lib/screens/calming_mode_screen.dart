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
];

class CalmingModeScreen extends StatefulWidget {
  const CalmingModeScreen({super.key});

  @override
  State<CalmingModeScreen> createState() => _CalmingModeScreenState();
}

class _CalmingModeScreenState extends State<CalmingModeScreen> {
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.4);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  void _speak(String text) => _tts.speak(text);

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _Header(onExit: () => Navigator.pop(context)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, // ← align to top, not stretch
                children: [
                  Expanded(
                    child: SymbolGridSection(
                      title: 'I feel...',
                      items: _emotions,
                      onTap: _speak,
                      cellSize: 110,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SymbolGridSection(
                      title: 'I want...',
                      items: _needs,
                      onTap: _speak,
                      cellSize: 110,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DebriefModeScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6)),
                  ),
                  child: const Text(
                    'I feel better',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
  const _Header({required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
              const Text(
                'Calming Mode',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onExit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                SizedBox(width: 6),
                Text(
                  'Exit',
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
      ],
    );
  }
}

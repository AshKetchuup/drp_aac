import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/aac_provider.dart';
import '../models/models.dart';
import '../widgets/sentence_rail.dart';
import '../widgets/communication_grid.dart';
import '../widgets/smart_suggestions.dart';
import '../widgets/emotions_bar.dart';
import 'calming_mode_screen.dart';
import 'dashboard_screen.dart';
import '../widgets/scheduler.dart';
import 'now_next_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  String? _activeCategory;
  bool _showEmotions = false; // Toggle for emotions view
  bool _showSchedule = false;

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

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  final _scheduleSymbols = [
  Symbol(
    id: 'home',
    label: 'Home',
    icon: Icons.home,
    category: SymbolCategory.activity,
  ),
  Symbol(
    id: 'school',
    label: 'School',
    icon: Icons.school,
    category: SymbolCategory.activity,
  ),
  Symbol(
    id: 'break',
    label: 'Break',
    icon: Icons.chair,
    category: SymbolCategory.activity,
  ),
  Symbol(
    id: 'lunch',
    label: 'Lunch',
    icon: Icons.restaurant,
    category: SymbolCategory.activity,
  ),
  Symbol(
    id: 'outside',
    label: 'Outside',
    icon: Icons.park,
    category: SymbolCategory.activity,
  ),
  Symbol(
    id: 'tablet',
    label: 'Tablet',
    icon: Icons.tablet,
    category: SymbolCategory.activity,
  ),
];

  void _handleSymbolTap(Symbol symbol) {
    final provider = Provider.of<AACProvider>(context, listen: false);
    provider.addToSentence(symbol);
  }

  void _handleSuggestionTap(String suggestion) {
    final provider = Provider.of<AACProvider>(context, listen: false);
    final dynamicSymbol = Symbol(
      id: 'dyn_${DateTime.now().millisecondsSinceEpoch}',
      label: suggestion,
      category: SymbolCategory.noun,
      icon: Icons.fastfood,
    );
    provider.addToSentence(dynamicSymbol);

    // Speak the full sentence after adding the new word
    _speak(provider.currentSentence);
  }

  void _handleSpeak() {
    final provider = Provider.of<AACProvider>(context, listen: false);
    _speak(provider.currentSentence);
  }

  void _handleClear() {
    final provider = Provider.of<AACProvider>(context, listen: false);
    provider.clearSentence();
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AACProvider>(
      builder: (context, provider, child) {

        if (_showSchedule) {
          return ScheduleMode(
            onExit: () {
              setState(() {
                _showSchedule = false;
              });
            },
            availableSymbols: _scheduleSymbols,
            onSpeakSchedule: _handleSpeak,
          );
        }

        return Scaffold(
          backgroundColor: Colors.black, // Dark borders
          body: SafeArea(
            child: Column(
              children: [
                // Top thin menu bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: Colors.blue,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            provider.currentProfile?.name ?? 'My Board',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DashboardScreen(),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.apps_rounded, color: Colors.black54, size: 20),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showEmotions = !_showEmotions;
                              });
                            },
                            child: Row(
                              children: [
                                Icon(
                                  _showEmotions
                                      ? Icons.emoji_emotions
                                      : Icons.emoji_emotions_outlined,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Emotions',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CalmingModeScreen(),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.spa_rounded,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Calming mode',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: _openSettings,
                            child: Icon(
                              Icons.settings,
                              color: Colors.black87,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Sentence builder rail
                SentenceRail(onSpeak: _handleSpeak, onClear: _handleClear),
                // Smart suggestions or Emotions Bar
                _showEmotions
                    ? EmotionsBar(onTap: (val) => _speak(val))
                    : SmartSuggestions(onSuggestionTap: _handleSuggestionTap),
                // Main communication grid
                Expanded(
                  child: CommunicationGrid(
                    onSymbolTap: _handleSymbolTap,
                    activeCategory: _activeCategory,
                    onCategoryChange: (category) {
                      setState(() => _activeCategory = category);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}

class _SettingsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _SettingsTile(
            icon: Icons.person_outline,
            label: 'Edit Profile',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.volume_up_outlined,
            label: 'Voice Settings',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.grid_view_outlined,
            label: 'Grid Layout',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.color_lens_outlined,
            label: 'Appearance',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.cloud_outlined,
            label: 'Backup & Sync',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          Consumer<AACProvider>(
            builder: (context, provider, _) => SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  provider.resetSetup();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.logout, color: AppTheme.error),
                label: Text(
                  'Switch Profile',
                  style: TextStyle(color: AppTheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

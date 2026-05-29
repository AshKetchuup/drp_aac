import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/aac_provider.dart';
import '../models/models.dart';
import '../widgets/sentence_rail.dart';
import '../widgets/communication_grid.dart';
import '../widgets/smart_suggestions.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/overload_mode.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  String? _activeCategory;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.4);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  void _handleSymbolTap(Symbol symbol) {
    final provider = Provider.of<AACProvider>(context, listen: false);
    provider.addToSentence(symbol);
  }

  void _handleSuggestionTap(String suggestion) {
    _speak(suggestion);
  }

  void _handleSpeak() {
    final provider = Provider.of<AACProvider>(context, listen: false);
    _speak(provider.currentSentence);
  }

  void _handleClear() {
    final provider = Provider.of<AACProvider>(context, listen: false);
    provider.clearSentence();
  }

  void _handleEmergencySelect(String id) {
    final labels = {
      'quiet': 'I need quiet. I need a break.',
      'drink': 'I want a drink please.',
      'hurt': 'I am hurt. I need help.',
      'leave': 'I want to leave. I need to exit.',
    };
    _speak(labels[id] ?? '');
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
        if (provider.isOverloadMode) {
          return OverloadMode(
            onExit: () => provider.setOverloadMode(false),
            onSelect: _handleEmergencySelect,
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                // Sentence builder rail
                SentenceRail(
                  onSpeak: _handleSpeak,
                  onClear: _handleClear,
                ),
                // Smart suggestions
                SmartSuggestions(
                  onSuggestionTap: _handleSuggestionTap,
                ),
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
                // Bottom bar
                BottomBar(
                  userName: provider.currentProfile?.name,
                  avatarId: provider.currentProfile?.avatarId,
                  isOverloadMode: provider.isOverloadMode,
                  onOverloadToggle: provider.toggleOverloadMode,
                  onSettingsTap: _openSettings,
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
          border: Border(
            bottom: BorderSide(color: AppTheme.border),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textSecondary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

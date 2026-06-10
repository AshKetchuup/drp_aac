import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/obf/obf_parser.dart';
import 'package:frontend/services/obf/obz_parser.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/aac_provider.dart';
import '../models/models.dart';
import '../widgets/sentence_rail.dart';
import '../widgets/communication_grid.dart';
import '../widgets/smart_suggestions.dart';
import '../widgets/emotions_bar.dart';
import '../widgets/settings_dialogs.dart';
import 'calming_mode_screen.dart';
import 'dashboard_screen.dart';
import '../widgets/scheduler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _activeCategory;
  bool _showEmotions = false; // Toggle for emotions view


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
    provider.speak(provider.currentSentence);
  }

  void _handleSpeak() {
    final provider = Provider.of<AACProvider>(context, listen: false);
    provider.speak(provider.currentSentence);
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
      builder: (context) => SettingsSheet(),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<AACProvider>(
      builder: (context, provider, child) {
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
                      Expanded(
                        child: Row(
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
                            Expanded(
                              child: Text(
                                provider.importedBoardSet?.boardsByPath[provider.activeImportedBoardPath]?.name ?? provider.currentProfile?.name ?? 'My Board',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
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
                    _showEmotions
                        ? EmotionsBar(onTap: (val) => Provider.of<AACProvider>(context, listen: false).speak(val))
                        : SmartSuggestions(onSuggestionTap: _handleSuggestionTap),
                // Main communication grid
                Expanded(
                  child: CommunicationGrid(
                    onSymbolTap: _handleSymbolTap,
                    activeCategory: _activeCategory,
                    onCategoryChange: (category) {
                      setState(() => _activeCategory = category);
                    },

                    importedBoardSet: provider.importedBoardSet,
                    activeImportedBoardPath:
                        provider.activeImportedBoardPath,

                    onImportedBoardChange: (path) {
                      provider.setActiveImportedBoard(path);
                    },

                    nowNextData: provider.calculateNowNext(),
                    onNowNextTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScheduleMode(
                            onExit: () => Navigator.pop(context),
                            availableSymbols: DashboardScreen.scheduleSymbols,
                            initialView: ScheduleViewMode.nowNext,
                          ),
                        ),
                      );
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
}

class SettingsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AACProvider>(
      builder: (context, provider, _) {
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
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SettingsTile(
                        icon: Icons.person_outline,
                        label: 'Edit Profile',
                        onTap: () {},
                      ),
                      SettingsTile(
                        icon: Icons.volume_up_outlined,
                        label: 'Voice Settings',
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (_) => const VoiceSettingsDialog(),
                          );
                        },
                      ),
                      SettingsTile(
                        icon: Icons.grid_view_outlined,
                        label: 'Grid Layout',
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (_) => const GridLayoutDialog(),
                          );
                        },
                      ),
                      SettingsTile(
                        icon: Icons.color_lens_outlined,
                        label: 'Appearance',
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (_) => const AppearanceDialog(),
                          );
                        },
                      ),
                      SettingsTile(
                        icon: Icons.cloud_outlined,
                        label: 'Backup & Sync',
                        onTap: () {},
                      ),
                      SettingsTile(
                        icon: Icons.help_outline,
                        label: 'Help & Support',
                        onTap: () {},
                      ),
                      SettingsTile(
                        icon: Icons.dashboard_outlined,
                        label: 'Load Default Board',
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            await provider.activateDefaultBoard();
                          } catch (e) {
                            debugPrint('Error loading default board: $e');
                          }
                        },
                      ),
                      SettingsTile(
                        icon: Icons.file_upload_outlined,
                        label: 'Import OBF/OBZ Board',
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            await provider.importBoard();
                          } catch (e) {
                            debugPrint('Error importing board: $e');
                          }
                        },
                      ),
                      if (provider.importedBoardSet != null)
                        SettingsTile(
                          icon: Icons.clear_all_outlined,
                          label: 'Clear Imported Board',
                          onTap: () {
                            provider.clearImportedBoardSet();
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
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
            ],
          ),
        );
      },
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
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
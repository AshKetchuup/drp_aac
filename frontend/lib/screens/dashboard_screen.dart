import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aac_provider.dart';
import '../models/models.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';
import 'calming_mode_screen.dart';
import 'now_next_screen.dart';
import '../widgets/scheduler.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Schedule symbols shared with NowNext and Schedule screens
  static final _scheduleSymbols = [
    Symbol(id: 'home', label: 'Home', icon: Icons.home, category: SymbolCategory.activity),
    Symbol(id: 'school', label: 'School', icon: Icons.school, category: SymbolCategory.activity),
    Symbol(id: 'break', label: 'Break', icon: Icons.chair, category: SymbolCategory.activity),
    Symbol(id: 'lunch', label: 'Lunch', icon: Icons.restaurant, category: SymbolCategory.activity),
    Symbol(id: 'outside', label: 'Outside', icon: Icons.park, category: SymbolCategory.activity),
    Symbol(id: 'tablet', label: 'Tablet', icon: Icons.tablet, category: SymbolCategory.activity),
  ];
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AACProvider>(context);
    final name = provider.currentProfile?.name ?? 'Friend';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.apps_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $name! 👋',
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'What would you like to do?',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Settings button
                  GestureDetector(
                    onTap: () {
                      // TODO: settings
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: Color(0xFF64748B),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Tiles grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    _DashboardTile(
                      title: 'My Board',
                      subtitle: 'Start communicating',
                      icon: Icons.grid_view_rounded,
                      gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen(),
                          ),
                        );
                      },
                    ),
                    _DashboardTile(
                      title: 'Profile',
                      subtitle: 'Edit your profile',
                      icon: Icons.person_rounded,
                      gradient: const [Color(0xFF22C55E), Color(0xFF16A34A)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileSetup(
                              onComplete: (profile) {
                                provider.setProfile(profile);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    _DashboardTile(
                      title: 'Minigames',
                      subtitle: 'Learn & play',
                      icon: Icons.sports_esports_rounded,
                      gradient: const [Color(0xFFF97316), Color(0xFFEA580C)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MinigamesPlaceholder(),
                          ),
                        );
                      },
                    ),
                    _DashboardTile(
                      title: 'Now & Next',
                      subtitle: 'Visual schedule',
                      icon: Icons.view_agenda_rounded,
                      gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NowNextMode(
                              onExit: () => Navigator.pop(context),
                              availableSymbols: _scheduleSymbols,
                              onSpeak: () {},
                            ),
                          ),
                        );
                      },
                    ),
                    _DashboardTile(
                      title: 'Schedule',
                      subtitle: 'Plan your day',
                      icon: Icons.calendar_today_rounded,
                      gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScheduleMode(
                              onExit: () => Navigator.pop(context),
                              availableSymbols: _scheduleSymbols,
                              onSpeakSchedule: () {},
                            ),
                          ),
                        );
                      },
                    ),
                    _DashboardTile(
                      title: 'Calming Mode',
                      subtitle: 'Relax & breathe',
                      icon: Icons.spa_rounded,
                      gradient: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CalmingModeScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_DashboardTile> createState() => _DashboardTileState();
}

class _DashboardTileState extends State<_DashboardTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.gradient[0].withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder screen for Minigames — to be replaced with real content later
class MinigamesPlaceholder extends StatelessWidget {
  const MinigamesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Minigames',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Minigames',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming soon!',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aac_provider.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'calming_mode_screen.dart';
import 'now_next_screen.dart';
import 'fill_blanks_game_screen.dart';
import '../widgets/scheduler.dart';
import 'login_screen.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  // Schedule symbols shared with NowNext and Schedule screens
  static final scheduleSymbols = [
    Symbol(id: 'home', label: 'Home', icon: Icons.home, category: SymbolCategory.activity),
    Symbol(id: 'school', label: 'School', icon: Icons.school, category: SymbolCategory.activity),
    Symbol(id: 'break', label: 'Break', icon: Icons.chair, category: SymbolCategory.activity),
    Symbol(id: 'lunch', label: 'Lunch', icon: Icons.restaurant, category: SymbolCategory.activity),
    Symbol(id: 'outside', label: 'Outside', icon: Icons.park, category: SymbolCategory.activity),
    Symbol(id: 'tablet', label: 'Tablet', icon: Icons.tablet, category: SymbolCategory.activity),
  ];

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final loggedIn = await _authService.isLoggedIn();
    String? name;

    if (loggedIn) {
      name = await _extractUserName();
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _userName = name;
      });
    }
  }

  /// Decode the user's name from the stored ID token (JWT) without verification.
  Future<String?> _extractUserName() async {
    final idToken = await _authService.getIdToken();
    if (idToken == null) return null;

    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;

      // JWT payload is base64url encoded
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;

      return claims['name'] as String? ??
          claims['preferred_username'] as String? ??
          claims['email'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleLoginTap() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    if (result == true) {
      await _checkAuthState();
      // Now that a token exists, refresh the session and pull this account's
      // child profiles remotely.
      if (mounted) {
        await context.read<AACProvider>().refreshSession();
      }
    }
  }

  Future<void> _handleLogoutTap() async {
    // Clears the token and all profile state, returning the app to the
    // welcome/login screen.
    await context.read<AACProvider>().logoutSession();
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _userName = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.isHighContrast ? Colors.black : const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'alpAACa',
                          style: TextStyle(
                            color: AppTheme.isHighContrast ? Colors.white : const Color(0xFF1E293B),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ── Dynamic Login / Logout Button ──
                  if (_isLoggedIn) ...[
                    // Show user name
                    if (_userName != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          _userName!,
                          style: TextStyle(
                            color: AppTheme.isHighContrast ? AppTheme.textSecondary : const Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Logout button
                    GestureDetector(
                      onTap: _handleLogoutTap,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2), // Light red bg
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.isHighContrast ? null : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFDC2626), // Red icon
                          size: 24,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Login button
                    GestureDetector(
                      onTap: _handleLoginTap,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.isHighContrast ? AppTheme.surfaceLight : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppTheme.isHighContrast ? null : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.login_rounded,
                          color: AppTheme.isHighContrast ? Colors.white : const Color(0xFF64748B),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              // Tiles grid
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisSpacing = 16.0;
                    final mainAxisSpacing = 16.0;
                    // Calculate exact aspect ratio to fit 2 rows of 3 columns
                    final cellWidth = (constraints.maxWidth - (crossAxisSpacing * 2)) / 3;
                    final cellHeight = (constraints.maxHeight - mainAxisSpacing) / 2;
                    final aspectRatio = cellWidth / cellHeight;

                    return GridView.count(
                      physics: const NeverScrollableScrollPhysics(), // No scrolling needed!
                      crossAxisCount: 3,
                      mainAxisSpacing: mainAxisSpacing,
                      crossAxisSpacing: crossAxisSpacing,
                      childAspectRatio: aspectRatio,
                      children: [
                        _DashboardTile(
                          title: 'My Board',
                      icon: Icons.grid_view_rounded,
                      backgroundColor: const Color(0xFFDCFCE7), // Soft Green (What)
                      iconColor: const Color(0xFF16A34A),
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
                          title: 'Calming Mode',
                      icon: Icons.spa_rounded,
                      backgroundColor: const Color(0xFFDBEAFE), // Soft Blue (Where/Describe)
                      iconColor: const Color(0xFF2563EB),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CalmingModeScreen(),
                          ),
                        );
                      },
                    ),
                        _DashboardTile(
                          title: 'Minigames',
                      icon: Icons.sports_esports_rounded,
                      backgroundColor: const Color(0xFFFEF9C3), // Soft Yellow (What doing)
                      iconColor: const Color(0xFFCA8A04),
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
                      icon: Icons.view_agenda_rounded,
                      backgroundColor: const Color(0xFFEFEBE9), // Soft Brown (When)
                      iconColor: const Color(0xFF795548),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NowNextMode(
                              onExit: () => Navigator.pop(context),
                              availableSymbols: DashboardScreen.scheduleSymbols,
                            ),
                          ),
                        );
                      },
                    ),
                        _DashboardTile(
                          title: 'Schedule',
                      icon: Icons.calendar_today_rounded,
                      backgroundColor: const Color(0xFFEFEBE9), // Soft Brown (When)
                      iconColor: const Color(0xFF795548),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScheduleMode(
                              onExit: () => Navigator.pop(context),
                              availableSymbols: DashboardScreen.scheduleSymbols,
                            ),
                          ),
                        );
                      },
                    ),
                        _DashboardTile(
                          title: 'Settings',
                      icon: Icons.settings_rounded,
                      backgroundColor: const Color(0xFFE2E8F0), // Soft Slate (Tools)
                      iconColor: const Color(0xFF475569),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                      ],
                    );
                  },
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
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.title,
    required this.icon,
    this.backgroundColor,
    this.iconColor,
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
            color: widget.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(16), // More square, blocky
            border: Border.all(color: widget.iconColor ?? Colors.black, width: 4), // Chunky outline
            boxShadow: AppTheme.isHighContrast ? null : [
              // Hard drop shadow for pixel art / neo-brutalist feel
              BoxShadow(
                color: widget.iconColor ?? Colors.black,
                blurRadius: 0,
                offset: const Offset(4, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12), // Square with slight rounding
                      border: Border.all(color: widget.iconColor ?? Colors.black, width: 3),
                      boxShadow: AppTheme.isHighContrast ? null : [
                        BoxShadow(
                          color: widget.iconColor ?? Colors.black,
                          blurRadius: 0,
                          offset: const Offset(3, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.icon,
                        size: 56, // Massive icon
                        color: widget.iconColor ?? Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 22, 
                    fontWeight: FontWeight.w900, // Extra bold for blocky feel
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Minigames',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _MinigameTile(
            title: 'Fill in the Blanks',
            subtitle: 'Pick the word that completes the sentence',
            icon: Icons.edit_note_rounded,
            // Colourful Semantics "Doing?" yellow — matches the game itself.
            gradient: const [Color(0xFFFACC15), Color(0xFFCA8A04)],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FillBlanksGameScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'More minigames coming soon!',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single launchable minigame entry in the [MinigamesPlaceholder] hub.
class _MinigameTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _MinigameTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppTheme.border,
          width: AppTheme.isHighContrast ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 32, color: AppTheme.isHighContrast ? Colors.black : Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

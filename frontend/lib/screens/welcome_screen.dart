import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Opening screen shown while signed out: log in with Authentik, or explore the
/// app with a built-in demo profile. [onLoggedIn] runs after a successful login
/// (the caller refreshes the session); [onDemo] activates the demo profile.
class WelcomeScreen extends StatefulWidget {
  final Future<void> Function() onLoggedIn;
  final VoidCallback onDemo;

  const WelcomeScreen({
    super.key,
    required this.onLoggedIn,
    required this.onDemo,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _loggingIn = false;

  Future<void> _login() async {
    setState(() => _loggingIn = true);
    bool success = false;
    try {
      success = await AuthService().login();
    } catch (_) {
      success = false;
    }
    if (!mounted) return;
    setState(() => _loggingIn = false);
    if (success) {
      await widget.onLoggedIn();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hc = AppTheme.isHighContrast;
    final bg = hc ? Colors.black : const Color(0xFFF0F4F8);
    final ink = hc ? Colors.white : const Color(0xFF1E293B);
    final sub = hc ? Colors.white70 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'alpAACa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to sync profiles, custom tiles and boards across '
                    'devices, or try a demo profile on this device.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: sub, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  FilledButton.icon(
                    onPressed: _loggingIn ? null : _login,
                    icon: _loggingIn
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(_loggingIn ? 'Signing in…' : 'Log in with Authentik'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loggingIn ? null : widget.onDemo,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Use a demo profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ink,
                      side: BorderSide(color: ink.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

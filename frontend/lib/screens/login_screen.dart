import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

final authService = AuthService();

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This screen is light-styled by design; in High Contrast it flips to
    // black surfaces with white text (colour-only change).
    final hc = AppTheme.isHighContrast;
    final bg = hc ? Colors.black : const Color(0xFFF0F4F8);
    final ink = hc ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ink),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'Login',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: ElevatedButton(
        onPressed: () async {
          final success = await authService.login();
          if (success && context.mounted) {
            Navigator.pop(context, true); // Return true to signal login success
          }
        },
        child: const Text('Login with Authentik'),
        ),
      ),
    );
  }
}

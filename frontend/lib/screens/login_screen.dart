import 'package:flutter/material.dart';
import '../services/auth_service.dart';

final authService = AuthService();

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Login',
          style: TextStyle(
            color: Color(0xFF1E293B),
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

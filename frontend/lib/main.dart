import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/aac_provider.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations for tablet
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const SpeakEasyApp());
}

class SpeakEasyApp extends StatelessWidget {
  const SpeakEasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AACProvider(),
      child: Consumer<AACProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'SpeakEasy AAC',
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.light, // Let AppTheme.getTheme handle the actual colors based on mode instead of letting flutter switch theme based on OS
            theme: AppTheme.getTheme(provider.themeMode),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AACProvider>(
      builder: (context, provider, child) {
        if (!provider.isProfileSetupComplete) {
          return ProfileSetup(
            onComplete: (profile) {
              provider.setProfile(profile);
            },
          );
        }
        return const DashboardScreen();
      },
    );
  }
}

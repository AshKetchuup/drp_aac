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
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const AlpaacaApp());
}

class AlpaacaApp extends StatelessWidget {
  const AlpaacaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AACProvider(),
      child: Consumer<AACProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'alpAACa',
            debugShowCheckedModeBanner: false,
            // Two themes: default Dark, or High Contrast when the toggle is on.
            // The OS never switches themes (no darkTheme is supplied).
            theme: AppTheme.getTheme(highContrast: provider.highContrast),
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
        // While the teacher's child profiles are loading from the backend.
        if (provider.bootstrapping) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
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

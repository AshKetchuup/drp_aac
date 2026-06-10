import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette - Dark slate with lime green accents
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceLight = Color(0xFF334155);
  static const Color primary = Color(0xFFA3E635); // Lime green
  static const Color secondary = Color(0xFF38BDF8); // Sky blue
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color border = Color(0xFF334155);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFACC15);

  // ─── Colourful Semantics palette ──────────────────────────────────────────
  // The clinical colour convention (Bryan). These are the SAME hex values as
  // the Fill-in-the-Blanks minigame's SemanticType, so the communication
  // boards and the games speak one shared colour language.
  static const Color categoryPronoun = Color(0xFFF97316); // Orange — Who? (subject)
  static const Color categoryVerb = Color(0xFFFACC15); // Yellow — Doing? (action)
  static const Color categoryNoun = Color(0xFF22C55E); // Green — What? (object)
  static const Color categoryPlace = Color(0xFF3B82F6); // Blue — Where? (place)
  static const Color categoryAdjective = Color(0xFFF4F4F4); // White — What kind? (describe)

  // Categories that share a Colourful Semantics role point at the same colour.
  static const Color categoryFood = categoryNoun; // food is an object → green
  static const Color categoryActivity = categoryVerb; // activities are actions → yellow
  static const Color categoryFeeling = categoryAdjective; // feelings describe → white
  static const Color categoryPreposition = categoryPlace; // location words → blue

  // Outside the core 5-role scheme — kept visually distinct, not CS colours.
  static const Color categoryQuestion = Color(0xFFD8BFD8); // Purple — question words
  static const Color categoryFolder = Color(0xFF40E0D0); // Teal — topics / folders

  // Emotion Colors
  static const Color emotionHappy = Color(0xFFFACC15);
  static const Color emotionSad = Color(0xFF3B82F6);
  static const Color emotionAngry = Color(0xFFEF4444);
  static const Color emotionScared = Color(0xFFA855F7);
  static const Color emotionCalm = Color(0xFF22C55E);
  static const Color emotionTired = Color(0xFF6B7280);

  static ThemeData getTheme(ThemeMode mode) {
    if (mode == ThemeMode.light) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: secondary,
          surface: Colors.white,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8FAFC),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 32, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 16),
          bodyMedium: TextStyle(color: Color(0xFF475569), fontSize: 14),
        ),
      );
    }

    if (mode == ThemeMode.system) { // we use system for High Contrast since flutter doesn't have a built-in high contrast ThemeMode enum
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.yellow,
          secondary: Colors.cyan,
          surface: Colors.black,
          error: Colors.red,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white, width: 3),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    }

    // Default Dark
    return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: surface,
          error: error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: background,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: border, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: const TextStyle(color: textSecondary),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          displayMedium: TextStyle(
            color: textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineLarge: TextStyle(
            color: textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            color: textPrimary,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: textSecondary,
            fontSize: 14,
          ),
          labelLarge: TextStyle(
            color: textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
  }
}

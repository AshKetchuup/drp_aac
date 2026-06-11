import 'package:flutter/material.dart';

/// The app has two themes, chosen by a single toggle: the default Dark theme
/// and a Windows-style High Contrast theme. There is no Light mode.
class AppTheme {
  // ─── Chrome palette ──────────────────────────────────────────────────────
  // Dark slate with lime green accents (the default look). The five fields
  // below are intentionally NOT const: [getTheme] swaps them to a Windows-style
  // high-contrast palette (pure black surfaces, white borders, near-white
  // secondary text) when High Contrast is on, and restores the slate values
  // for the default Dark theme — so Dark renders exactly as before.
  static const Color _slateBackground = Color(0xFF0F172A);
  static const Color _slateSurface = Color(0xFF1E293B);
  static const Color _slateSurfaceLight = Color(0xFF334155);
  static const Color _slateTextSecondary = Color(0xFF94A3B8);
  static const Color _slateBorder = Color(0xFF334155);

  static Color background = _slateBackground;
  static Color surface = _slateSurface;
  static Color surfaceLight = _slateSurfaceLight;
  static Color textSecondary = _slateTextSecondary;
  static Color border = _slateBorder;

  static const Color primary = Color(0xFFA3E635); // Lime green
  static const Color secondary = Color(0xFF38BDF8); // Sky blue
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFACC15);

  /// Bright cyan used in High Contrast mode for focus rings and selected
  /// outlines — clearly distinguishable from every Colourful Semantics hue.
  static const Color focusHighlight = Color(0xFF00E5FF);

  /// True while the active theme is High Contrast. Set by [getTheme] before
  /// any widget builds; lets leaf widgets (e.g. SymbolTile) draw stronger
  /// outlines without changing their layout.
  static bool isHighContrast = false;

  // ─── Colourful Semantics palette ──────────────────────────────────────────
  // The clinical colour convention (Bryan). These are the SAME hex values as
  // the Fill-in-the-Blanks minigame's SemanticType, so the communication
  // boards and the games speak one shared colour language.
  //
  // Core AAC functionality — NEVER altered by any appearance mode. High
  // Contrast improves tile legibility with stronger outlines and label ink
  // chosen via [onColor], not by changing these hues.
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

  /// Returns black or white — whichever has the higher WCAG contrast ratio
  /// against [bg]. Lets High Contrast mode maximise label/outline legibility
  /// on the fixed Colourful Semantics fills without touching the fills.
  static Color onColor(Color bg) {
    final l = bg.computeLuminance();
    final blackContrast = (l + 0.05) / 0.05;
    final whiteContrast = 1.05 / (l + 0.05);
    return blackContrast >= whiteContrast ? Colors.black : Colors.white;
  }

  static ThemeData getTheme({bool highContrast = false}) {
    // Swap the shared chrome tokens BEFORE widgets read them. The default Dark
    // theme keeps the original slate values; High Contrast goes pure black.
    isHighContrast = highContrast;
    background = isHighContrast ? Colors.black : _slateBackground;
    surface = isHighContrast ? Colors.black : _slateSurface;
    surfaceLight = isHighContrast ? const Color(0xFF1A1A1A) : _slateSurfaceLight;
    textSecondary = isHighContrast ? const Color(0xFFE0E0E0) : _slateTextSecondary;
    border = isHighContrast ? Colors.white : _slateBorder;

    return isHighContrast ? _highContrastTheme() : _darkTheme();
  }

  // ─── High Contrast (Windows-style) ─────────────────────────────────────────
  // Pure black backgrounds, white text, stark white borders, yellow controls,
  // cyan focus. Every metric (font size, padding, radius) matches the Dark
  // theme exactly — this mode changes contrast only, never sizing or layout.
  static ThemeData _highContrastTheme() {
    const Color hcYellow = Color(0xFFFFFF00);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      focusColor: focusHighlight,
      dividerColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      colorScheme: const ColorScheme.dark(
        primary: hcYellow,
        onPrimary: Colors.black,
        secondary: focusHighlight,
        onSecondary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
        error: Color(0xFFFF5252),
        onError: Colors.black,
        outline: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: hcYellow,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          // Strong, unmistakable keyboard/switch focus indicator.
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? const BorderSide(color: focusHighlight, width: 3)
                : const BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? const BorderSide(color: focusHighlight, width: 3)
                : const BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: hcYellow).copyWith(
          overlayColor: const WidgetStatePropertyAll(Colors.white24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: focusHighlight, width: 3),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: Color(0xFFE0E0E0)),
      ),
      // Same sizes/weights as the Dark theme — colours only.
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
        labelLarge: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
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
          side: BorderSide(color: border, width: 1),
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
          side: BorderSide(color: border, width: 1),
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
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: textSecondary),
      ),
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: const TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: const TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: const TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: const TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        labelLarge: const TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

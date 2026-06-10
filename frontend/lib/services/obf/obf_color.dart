import 'package:flutter/material.dart';

/// Parses a CSS-style colour string from an Open Board Format file into a
/// Flutter [Color].
///
/// Imported OBF boards are not authored with Colourful Semantics in mind, so
/// rather than re-colour them by grammar role we respect whatever colour the
/// board author baked in. OBF buttons carry their styling in the CSS
/// convention via `background_color` / `border_color`, most commonly:
///
///   "rgb(255, 0, 0)"        // the canonical OBF form
///   "rgba(255, 0, 0, 0.5)"  // with an alpha channel (0..1)
///
/// Hex (`#rgb` / `#rrggbb` / `#rrggbbaa`) and a handful of CSS named colours
/// are accepted as a courtesy, since some exporters emit them.
///
/// Returns `null` for null, empty, `transparent`, or unparseable input so the
/// caller can fall back to its own default styling instead of rendering an
/// invisible or garbage colour.
Color? parseObfColor(String? raw) {
  if (raw == null) return null;
  final value = raw.trim().toLowerCase();
  if (value.isEmpty || value == 'transparent' || value == 'none') {
    return null;
  }

  return _parseRgbFunction(value) ?? _parseHex(value) ?? _namedColors[value];
}

/// Chooses a legible foreground (label / fallback-icon) colour for an arbitrary
/// imported [background].
///
/// The default board relies on the fixed Colourful Semantics palette where
/// black-on-colour is always readable, but imported boards bring their own
/// backgrounds — a white button would swallow white text. Picks black or white
/// using the WCAG relative-luminance of the background.
Color obfForegroundColor(Color background) {
  return background.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
}

final _rgbPattern = RegExp(r'^rgba?\(([^)]*)\)$');

Color? _parseRgbFunction(String value) {
  final match = _rgbPattern.firstMatch(value);
  if (match == null) return null;

  final parts = match
      .group(1)!
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length != 3 && parts.length != 4) return null;

  final r = _channel(parts[0]);
  final g = _channel(parts[1]);
  final b = _channel(parts[2]);
  if (r == null || g == null || b == null) return null;

  var alpha = 255;
  if (parts.length == 4) {
    final a = double.tryParse(parts[3]);
    if (a == null) return null;
    alpha = (a.clamp(0.0, 1.0) * 255).round();
  }

  return Color.fromARGB(alpha, r, g, b);
}

/// Resolves a single colour channel, which may be an integer (`255`) or a
/// percentage (`100%`) per the CSS spec, clamped into the valid 0–255 range.
int? _channel(String token) {
  if (token.endsWith('%')) {
    final pct = double.tryParse(token.substring(0, token.length - 1));
    if (pct == null) return null;
    return (pct.clamp(0.0, 100.0) / 100 * 255).round();
  }
  final n = num.tryParse(token);
  if (n == null) return null;
  return n.round().clamp(0, 255);
}

Color? _parseHex(String value) {
  if (!value.startsWith('#')) return null;
  var hex = value.substring(1);

  // Expand shorthand #rgb / #rgba to #rrggbb / #rrggbbaa.
  if (hex.length == 3 || hex.length == 4) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  // CSS orders hex as RRGGBB[AA]; Flutter's Color wants AARRGGBB.
  if (hex.length == 6) {
    hex = 'ff$hex';
  } else if (hex.length == 8) {
    hex = '${hex.substring(6)}${hex.substring(0, 6)}';
  } else {
    return null;
  }

  final intValue = int.tryParse(hex, radix: 16);
  if (intValue == null) return null;
  return Color(intValue);
}

/// A small subset of CSS named colours that turn up in real OBF exports.
const Map<String, Color> _namedColors = {
  'black': Color(0xFF000000),
  'white': Color(0xFFFFFFFF),
  'red': Color(0xFFFF0000),
  'green': Color(0xFF008000),
  'blue': Color(0xFF0000FF),
  'yellow': Color(0xFFFFFF00),
  'orange': Color(0xFFFFA500),
  'purple': Color(0xFF800080),
  'pink': Color(0xFFFFC0CB),
  'gray': Color(0xFF808080),
  'grey': Color(0xFF808080),
};

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/obf/obf_color.dart';

void main() {
  group('parseObfColor', () {
    test('parses the canonical OBF rgb() form', () {
      expect(parseObfColor('rgb(255, 0, 0)'), const Color(0xFFFF0000));
      expect(parseObfColor('rgb(255,255,255)'), const Color(0xFFFFFFFF));
    });

    test('tolerates whitespace and casing', () {
      expect(parseObfColor('  RGB( 0 , 128 , 64 ) '), const Color(0xFF008040));
    });

    test('parses rgba() with a 0..1 alpha channel', () {
      expect(parseObfColor('rgba(0, 0, 0, 0.5)'), const Color(0x80000000));
      expect(parseObfColor('rgba(255, 0, 0, 1)'), const Color(0xFFFF0000));
      expect(parseObfColor('rgba(255, 0, 0, 0)'), const Color(0x00FF0000));
    });

    test('supports percentage channels', () {
      expect(parseObfColor('rgb(100%, 0%, 0%)'), const Color(0xFFFF0000));
    });

    test('clamps out-of-range channel values', () {
      expect(parseObfColor('rgb(300, -20, 0)'), const Color(0xFFFF0000));
    });

    test('parses hex in CSS order (#rrggbb) into ARGB', () {
      expect(parseObfColor('#ff0000'), const Color(0xFFFF0000));
      expect(parseObfColor('#FFF'), const Color(0xFFFFFFFF));
      expect(parseObfColor('#ff000080'), const Color(0x80FF0000));
    });

    test('parses common named colours', () {
      expect(parseObfColor('white'), const Color(0xFFFFFFFF));
      expect(parseObfColor('black'), const Color(0xFF000000));
    });

    test('returns null for absent / empty / transparent / garbage input', () {
      expect(parseObfColor(null), isNull);
      expect(parseObfColor(''), isNull);
      expect(parseObfColor('transparent'), isNull);
      expect(parseObfColor('rgb(1, 2)'), isNull);
      expect(parseObfColor('not-a-colour'), isNull);
    });
  });

  group('obfForegroundColor', () {
    test('uses dark text on light backgrounds', () {
      expect(obfForegroundColor(const Color(0xFFFFFFFF)), Colors.black87);
    });

    test('uses light text on dark backgrounds', () {
      expect(obfForegroundColor(const Color(0xFF000000)), Colors.white);
    });
  });
}

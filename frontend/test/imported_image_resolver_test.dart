import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/services/obf/imported_image_resolver.dart';

void main() {
  final resolver = ImportedImageResolver();

  group('SVG detection', () {
    test('flags isSvg from the OBF content_type', () {
      final packaged = {
        'images/no.svg': utf8.encode('<svg/>'),
      };
      final image = ImportedImage(
        id: '1',
        path: 'images/no.svg',
        contentType: 'image/svg+xml',
      );

      final resolved = resolver.resolve(image, packaged);

      expect(resolved, isNotNull);
      expect(resolved!.isSvg, isTrue);
      expect(resolved.hasBytes, isTrue);
    });

    test('falls back to the .svg file extension when content_type is absent',
        () {
      final packaged = {
        'images/pet.svg': utf8.encode('<svg/>'),
      };
      final image = ImportedImage(id: '2', path: 'images/pet.svg');

      final resolved = resolver.resolve(image, packaged);

      expect(resolved!.isSvg, isTrue);
    });

    test('detects SVG via a data: URI mime type', () {
      final svg = base64Encode(utf8.encode('<svg/>'));
      final image = ImportedImage(
        id: '3',
        dataUri: 'data:image/svg+xml;base64,$svg',
      );

      final resolved = resolver.resolve(image, const {});

      expect(resolved!.isSvg, isTrue);
      expect(resolved.hasBytes, isTrue);
    });

    test('detects SVG on a remote url with a query string', () {
      final image = ImportedImage(
        id: '4',
        url: 'https://example.com/symbols/yes.svg?v=2',
      );

      final resolved = resolver.resolve(image, const {});

      expect(resolved!.isSvg, isTrue);
      expect(resolved.hasUrl, isTrue);
    });

    test('does NOT flag raster PNG images', () {
      final packaged = {
        'images/cup.png': [0x89, 0x50, 0x4e, 0x47],
      };
      final image = ImportedImage(
        id: '5',
        path: 'images/cup.png',
        contentType: 'image/png',
      );

      final resolved = resolver.resolve(image, packaged);

      expect(resolved!.isSvg, isFalse);
      expect(resolved.hasBytes, isTrue);
    });
  });
}

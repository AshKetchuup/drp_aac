import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/obf/imported_image_resolver.dart';
import 'package:frontend/services/obf/obz_parser.dart';

/// Guards the generated starter board (`assets/boards/default_board.obz`)
/// against the app's real parsing path, so a regeneration that breaks the
/// format is caught here rather than at runtime.
void main() {
  final bytes = File('assets/boards/default_board.obz').readAsBytesSync();
  final boardSet = ObzParser().parseObzBytes(bytes);

  test('root board is the menu and links to every category', () {
    expect(boardSet.rootPath, 'root.obf');
    final root = boardSet.rootBoard!;
    expect(root.name, 'My Board');

    final linkedPaths = root.buttons
        .map((b) => b.linkedBoardPath)
        .whereType<String>()
        .toSet();
    expect(
      linkedPaths,
      containsAll(<String>['pronoun.obf', 'verb.obf', 'noun.obf']),
    );
  });

  test('category buttons carry baked Colourful Semantics colours', () {
    final nouns = boardSet.boardsByPath['noun.obf']!;
    final food = nouns.buttonsById['food']!;
    // Green — What? (AppTheme.categoryNoun 0xFF22C55E)
    expect(food.backgroundColor, const Color(0xFF22C55E));
    expect(food.borderColor, const Color(0xFF000000));
  });

  test('embedded images resolve to bytes (offline-ready)', () {
    final resolver = ImportedImageResolver();
    final nouns = boardSet.boardsByPath['noun.obf']!;
    final food = nouns.buttonsById['food']!;

    final image = nouns.imagesById[food.imageId];
    final resolved = resolver.resolve(image, boardSet.filesByPath);

    expect(resolved, isNotNull);
    expect(resolved!.hasBytes, isTrue);
    expect(resolved.isSvg, isFalse);
  });
}

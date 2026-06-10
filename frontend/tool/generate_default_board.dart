// Generates `assets/boards/default_board.obz` from the app's default
// communication board.
//
// This is the single source for the bundled starter board: it mirrors the
// symbols defined in `lib/widgets/communication_grid.dart` and the Colourful
// Semantics palette in `lib/theme/app_theme.dart`, and emits a self-contained
// Open Board Format package:
//   * one board per category (a root menu links out to each), and
//   * each button's `background_color` baked from its category so the imported
//     board keeps the Colourful Semantics look, and
//   * the matching ARASAAC PNGs embedded so the package renders offline.
//
// Run from the `frontend/` directory with:
//   dart run tool/generate_default_board.dart
//
// Pure Dart (no Flutter imports) so it runs under `dart run`. If you change the
// default board, re-run this to regenerate the asset.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

/// Colourful Semantics colours, kept in sync with `AppTheme`. Stored as hex and
/// rendered to the `rgb(r, g, b)` form the OBF parser expects.
const _categoryColors = <String, String>{
  'pronoun': 'F97316', // Orange — Who?
  'verb': 'FACC15', // Yellow — Doing?
  'noun': '22C55E', // Green — What?
  'preposition': '3B82F6', // Blue — Where? (little words)
  'activity': 'FACC15', // Yellow — actions
  'feeling': 'F4F4F4', // White — describing
  'question': 'D8BFD8', // Purple — question words
};

/// Display names for the category boards / root menu buttons.
const _categoryLabels = <String, String>{
  'pronoun': 'Pronouns',
  'verb': 'Verbs',
  'noun': 'Nouns',
  'preposition': 'Little Words',
  'activity': 'Activities',
  'feeling': 'Feelings',
  'question': 'Questions',
};

/// Category render order, matching the home board's category chips.
const _categoryOrder = <String>[
  'pronoun',
  'verb',
  'noun',
  'preposition',
  'activity',
  'feeling',
  'question',
];

/// The default symbols, mirrored from `_CommunicationGridState.symbols`.
/// (id, label, category)
const _symbols = <List<String>>[
  // Pronouns
  ['i', 'I', 'pronoun'],
  ['you', 'You', 'pronoun'],
  ['we', 'We', 'pronoun'],
  ['they', 'They', 'pronoun'],
  // Verbs
  ['want', 'Want', 'verb'],
  ['need', 'Need', 'verb'],
  ['like', 'Like', 'verb'],
  ['dont_like', "Don't Like", 'verb'],
  ['go', 'Go', 'verb'],
  ['play', 'Play', 'verb'],
  ['eat', 'Eat', 'verb'],
  ['drink', 'Drink', 'verb'],
  ['see', 'See', 'verb'],
  ['help', 'Help', 'verb'],
  // Nouns
  ['food', 'Food', 'noun'],
  ['water', 'Water', 'noun'],
  ['home', 'Home', 'noun'],
  ['school', 'School', 'noun'],
  ['bathroom', 'Bathroom', 'noun'],
  ['outside', 'Outside', 'noun'],
  // Little words
  ['the', 'The', 'preposition'],
  ['a', 'A', 'preposition'],
  ['at', 'At', 'preposition'],
  ['that', 'That', 'preposition'],
  ['this', 'This', 'preposition'],
  ['to', 'To', 'preposition'],
  ['in', 'In', 'preposition'],
  ['on', 'On', 'preposition'],
  ['and', 'And', 'preposition'],
  ['with', 'With', 'preposition'],
  ['not', 'Not', 'preposition'],
  // Activities
  ['minecraft', 'Minecraft', 'activity'],
  ['roblox', 'Roblox', 'activity'],
  ['youtube', 'YouTube', 'activity'],
  ['tablet', 'Tablet', 'activity'],
  ['music', 'Music', 'activity'],
  ['drawing', 'Drawing', 'activity'],
  // Feelings
  ['happy', 'Happy', 'feeling'],
  ['sad', 'Sad', 'feeling'],
  ['angry', 'Angry', 'feeling'],
  ['tired', 'Tired', 'feeling'],
  ['scared', 'Scared', 'feeling'],
  ['calm', 'Calm', 'feeling'],
  // Questions
  ['what', 'What?', 'question'],
  ['where', 'Where?', 'question'],
  ['when', 'When?', 'question'],
  ['why', 'Why?', 'question'],
];

const _columns = 4;
const _arasaacDir = 'assets/arasaac';
const _outputPath = 'assets/boards/default_board.obz';

void main() {
  final archive = Archive();
  // Track embedded image files so we don't add the same PNG twice and can build
  // the manifest's image path map.
  final imagePathsById = <String, String>{};
  final boardPaths = <String, String>{};

  // ── Category boards ────────────────────────────────────────────────────────
  for (final category in _categoryOrder) {
    final boardId = category;
    final boardFile = '$boardId.obf';
    boardPaths[boardId] = boardFile;

    final symbols =
        _symbols.where((s) => s[2] == category).toList(growable: false);

    final buttons = <Map<String, dynamic>>[];
    final images = <Map<String, dynamic>>[];

    for (final symbol in symbols) {
      final id = symbol[0];
      final label = symbol[1];

      final button = <String, dynamic>{
        'id': id,
        'label': label,
        'background_color': _rgb(_categoryColors[category]!),
        'border_color': 'rgb(0, 0, 0)',
      };

      // Embed the ARASAAC PNG if one exists for this symbol.
      final asset = _assetFor(id);
      if (asset != null) {
        final imageId = 'img_$id';
        final imagePath = 'images/$id.png';
        button['image_id'] = imageId;

        images.add({
          'id': imageId,
          'content_type': 'image/png',
          'path': imagePath,
        });

        if (!imagePathsById.containsKey(imageId)) {
          imagePathsById[imageId] = imagePath;
          archive.addFile(
            ArchiveFile(imagePath, asset.length, asset),
          );
        }
      }

      buttons.add(button);
    }

    final board = {
      'format': 'open-board-0.1',
      'id': boardId,
      'locale': 'en',
      'name': _categoryLabels[category],
      'buttons': buttons,
      'images': images,
      'sounds': const [],
      'grid': _grid(buttons.map((b) => b['id'] as String).toList()),
    };

    _addJson(archive, boardFile, board);
  }

  // ── Root menu board: one folder button per category ────────────────────────
  const rootId = 'root';
  const rootFile = 'root.obf';
  boardPaths[rootId] = rootFile;

  final rootButtons = <Map<String, dynamic>>[];
  for (final category in _categoryOrder) {
    rootButtons.add({
      'id': 'go_$category',
      'label': _categoryLabels[category],
      'background_color': _rgb(_categoryColors[category]!),
      'border_color': 'rgb(0, 0, 0)',
      'load_board': {
        'id': category,
        'name': _categoryLabels[category],
        'path': boardPaths[category],
      },
    });
  }

  final rootBoard = {
    'format': 'open-board-0.1',
    'id': rootId,
    'locale': 'en',
    'name': 'My Board',
    'buttons': rootButtons,
    'images': const [],
    'sounds': const [],
    'grid': _grid(rootButtons.map((b) => b['id'] as String).toList()),
  };
  _addJson(archive, rootFile, rootBoard);

  // ── Manifest ───────────────────────────────────────────────────────────────
  final manifest = {
    'format': 'open-board-0.1',
    'root': rootFile,
    'paths': {
      'boards': boardPaths,
      'images': imagePathsById,
    },
  };
  _addJson(archive, 'manifest.json', manifest);

  // ── Write the .obz (a zip) ──────────────────────────────────────────────────
  final bytes = ZipEncoder().encode(archive);
  final outFile = File(_outputPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsBytesSync(bytes);

  final imageCount = imagePathsById.length;
  stdout.writeln(
    'Wrote $_outputPath '
    '(${boardPaths.length} boards, $imageCount images, ${bytes.length} bytes).',
  );
}

/// Returns the PNG bytes for a symbol id, or null when no asset exists.
List<int>? _assetFor(String id) {
  final file = File('$_arasaacDir/$id.png');
  if (!file.existsSync()) return null;
  return file.readAsBytesSync();
}

/// Builds an OBF grid (rows × [_columns]) from an ordered list of button ids,
/// row-major, padding the final row with nulls.
Map<String, dynamic> _grid(List<String> buttonIds) {
  final rows = (buttonIds.length / _columns).ceil();
  final order = <List<String?>>[];
  var index = 0;
  for (var r = 0; r < rows; r++) {
    final row = <String?>[];
    for (var c = 0; c < _columns; c++) {
      row.add(index < buttonIds.length ? buttonIds[index] : null);
      index++;
    }
    order.add(row);
  }
  return {'rows': rows, 'columns': _columns, 'order': order};
}

/// Converts a `RRGGBB` hex string to the OBF `rgb(r, g, b)` form.
String _rgb(String hex) {
  final value = int.parse(hex, radix: 16);
  final r = (value >> 16) & 0xFF;
  final g = (value >> 8) & 0xFF;
  final b = value & 0xFF;
  return 'rgb($r, $g, $b)';
}

void _addJson(Archive archive, String path, Object json) {
  final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(json));
  archive.addFile(ArchiveFile(path, bytes.length, bytes));
}

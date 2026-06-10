import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:frontend/models/models.dart';

import 'obf_parser.dart';

class ObzParser {
  final ObfParser _obfParser;

  ObzParser({ObfParser? obfParser}) : _obfParser = obfParser ?? ObfParser();

  Future<ImportedBoardSet> parseObzFile(File file) async {
    final bytes = await file.readAsBytes();
    return parseObzBytes(bytes);
  }

  ImportedBoardSet parseObzBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    final filesByPath = <String, List<int>>{};
    final boardsByPath = <String, ImportedBoard>{};
    String? rootPath;

    for (final entry in archive) {
      if (!entry.isFile) {
        continue;
      }

      final path = entry.name;
      final content = entry.content;
      filesByPath[path] = List<int>.from(content);
    }

    final manifestBytes = filesByPath['manifest.json'];
    if (manifestBytes != null) {
      final manifestText = utf8.decode(manifestBytes);
      final decoded = json.decode(manifestText);

      if (decoded is Map<String, dynamic>) {
        rootPath = decoded['root']?.toString();
      }
    }

    for (final entry in filesByPath.entries) {
      final path = entry.key;
      if (!path.toLowerCase().endsWith('.obf')) {
        continue;
      }

      final text = utf8.decode(entry.value);
      final board = _obfParser.parseObfString(text, sourcePath: path);
      boardsByPath[path] = board;
    }

    if (rootPath == null && boardsByPath.length == 1) {
      rootPath = boardsByPath.keys.first;
    }

    return ImportedBoardSet(
      rootPath: rootPath,
      boardsByPath: boardsByPath,
      filesByPath: filesByPath,
    );
  }
}
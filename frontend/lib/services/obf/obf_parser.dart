import 'dart:convert';

import 'package:frontend/models/models.dart';
import 'package:frontend/services/obf/obf_color.dart';

class ObfParser {
  ImportedBoard parseObfString(String jsonString, {String? sourcePath}) {
    final decoded = json.decode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('OBF root must be a JSON object.');
    }

    return parseObfJson(decoded, sourcePath: sourcePath);
  }

  ImportedBoard parseObfJson(Map<String, dynamic> json, {String? sourcePath}) {
    final buttonsJson = (json['buttons'] as List? ?? const []);
    final imagesJson = (json['images'] as List? ?? const []);
    final gridJson = (json['grid'] as Map<String, dynamic>? ?? const {});

    final buttons = buttonsJson
        .whereType<Map<String, dynamic>>()
        .map(_parseButton)
        .toList();

    final images = imagesJson
        .whereType<Map<String, dynamic>>()
        .map(_parseImage)
        .toList();

    final imagesById = <String, ImportedImage>{
      for (final image in images) image.id: image,
    };

    return ImportedBoard(
      id: _asString(json['id']) ?? '',
      name: _asString(json['name']) ?? 'Untitled Board',
      grid: _parseGrid(gridJson),
      buttons: buttons,
      imagesById: imagesById,
      sourcePath: sourcePath,
    );
  }

  BoardGrid _parseGrid(Map<String, dynamic> json) {
    final rawOrder = (json['order'] as List? ?? const []);

    final order = rawOrder.map<List<String?>>((row) {
      if (row is! List) {
        return <String?>[];
      }

      return row.map<String?>((cell) {
        if (cell == null) return null;
        return cell.toString();
      }).toList();
    }).toList();

    final rows = _asInt(json['rows']) ?? order.length;
    final columns = _asInt(json['columns']) ??
        (order.isNotEmpty ? order.map((row) => row.length).reduce((a, b) => a > b ? a : b) : 0);

    return BoardGrid(
      rows: rows,
      columns: columns,
      order: order,
    );
  }

  ImportedButton _parseButton(Map<String, dynamic> json) {
    final loadBoard = json['load_board'];
    final loadBoardMap = loadBoard is Map<String, dynamic> ? loadBoard : null;

    return ImportedButton(
      id: _asString(json['id']) ?? '',
      label: _asString(json['label']) ?? '',
      vocalization: _asString(json['vocalization']),
      imageId: _asString(json['image_id']),
      linkedBoardPath: _asString(loadBoardMap?['path']),
      linkedBoardId: _asString(loadBoardMap?['id']),
      linkedBoardName: _asString(loadBoardMap?['name']),
      // Respect the colours the OBF author baked in, since imported boards are
      // not designed around Colourful Semantics. Falls back to null (→ default
      // tile styling) when absent or unparseable.
      backgroundColor: parseObfColor(_asString(json['background_color'])),
      borderColor: parseObfColor(_asString(json['border_color'])),
    );
  }

  ImportedImage _parseImage(Map<String, dynamic> json) {
    return ImportedImage(
      id: _asString(json['id']) ?? '',
      dataUri: _asString(json['data']),
      path: _asString(json['path']),
      url: _asString(json['url']),
      contentType: _asString(json['content_type']),
    );
  }

  String? _asString(Object? value) {
    if (value == null) return null;
    return value.toString();
  }

  int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
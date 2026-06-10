import 'dart:convert';
import 'dart:typed_data';

import 'package:frontend/models/models.dart';

class ImportedImageResolver {
  ResolvedImportedImage? resolve(
    ImportedImage? image,
    Map<String, List<int>> packagedFiles,
  ) {
    if (image == null) {
      return null;
    }

    final isSvg = _isSvg(image);

    final dataUri = image.dataUri;
    if (dataUri != null && dataUri.startsWith('data:')) {
      final bytes = _decodeDataUri(dataUri);
      if (bytes != null && bytes.isNotEmpty) {
        return ResolvedImportedImage(bytes: bytes, isSvg: isSvg);
      }
    }

    final path = image.path;
    if (path != null && path.isNotEmpty) {
      final packaged = packagedFiles[path];
      if (packaged != null && packaged.isNotEmpty) {
        return ResolvedImportedImage(
          bytes: Uint8List.fromList(packaged),
          isSvg: isSvg,
        );
      }
    }

    final url = image.url;
    if (url != null && url.isNotEmpty) {
      return ResolvedImportedImage(url: url, isSvg: isSvg);
    }

    return null;
  }

  /// Detects SVG sources so the UI can pick an SVG decoder. Many OBF libraries
  /// (e.g. Mulberry in CommuniKate) ship the bulk of their symbols as SVG, and
  /// Flutter's raster [Image] widget throws on them. Checks the declared
  /// `content_type` first, then falls back to the data-URI mime and the file
  /// extension on the path/url.
  bool _isSvg(ImportedImage image) {
    final contentType = image.contentType?.toLowerCase();
    if (contentType != null && contentType.contains('svg')) {
      return true;
    }

    final dataUri = image.dataUri?.toLowerCase();
    if (dataUri != null && dataUri.startsWith('data:image/svg')) {
      return true;
    }

    for (final candidate in [image.path, image.url]) {
      if (candidate == null) continue;
      // Strip any query string before checking the extension.
      final withoutQuery = candidate.toLowerCase().split('?').first;
      if (withoutQuery.endsWith('.svg')) {
        return true;
      }
    }

    return false;
  }

  Uint8List? _decodeDataUri(String dataUri) {
    final commaIndex = dataUri.indexOf(',');
    if (commaIndex == -1) {
      return null;
    }

    final metadata = dataUri.substring(0, commaIndex);
    final payload = dataUri.substring(commaIndex + 1);

    if (!metadata.contains(';base64')) {
      return null;
    }

    try {
      return Uint8List.fromList(base64Decode(payload));
    } catch (_) {
      return null;
    }
  }
}
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

    final dataUri = image.dataUri;
    if (dataUri != null && dataUri.startsWith('data:')) {
      final bytes = _decodeDataUri(dataUri);
      if (bytes != null && bytes.isNotEmpty) {
        return ResolvedImportedImage(bytes: bytes);
      }
    }

    final path = image.path;
    if (path != null && path.isNotEmpty) {
      final packaged = packagedFiles[path];
      if (packaged != null && packaged.isNotEmpty) {
        return ResolvedImportedImage(bytes: Uint8List.fromList(packaged));
      }
    }

    final url = image.url;
    if (url != null && url.isNotEmpty) {
      return ResolvedImportedImage(url: url);
    }

    return null;
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
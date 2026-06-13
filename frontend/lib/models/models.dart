import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

enum SymbolCategory {
  pronoun,
  verb,
  noun,
  adjective,
  activity,
  food,
  feeling,
  place,
  question,
  preposition,
  folder,
}

class Symbol {
  final String id;
  final String label;
  final IconData? icon;
  final SymbolCategory category;
  final String? audioPath;
  final String? imageUrl;
  final bool isFolder;

  /// Raw image bytes for symbols whose picture isn't a network URL — e.g.
  /// buttons imported from an OBZ board, whose pictograms are embedded in the
  /// archive (or as data URIs). Takes precedence over [imageUrl] when set.
  final Uint8List? imageBytes;

  /// Whether [imageBytes]/[imageUrl] points at an SVG, so the UI uses an SVG
  /// decoder rather than the raster [Image] widget (which throws on SVG).
  final bool isSvg;

  /// Author-supplied tile colours, carried over from an imported board so the
  /// sentence rail matches the board's appearance instead of repainting the
  /// symbol with the default Colourful Semantics palette. Null → default tile
  /// styling (category colour).
  final Color? backgroundColor;
  final Color? borderColor;

  const Symbol({
    required this.id,
    required this.label,
    this.icon,
    required this.category,
    this.audioPath,
    this.imageUrl,
    this.isFolder = false,
    this.imageBytes,
    this.isSvg = false,
    this.backgroundColor,
    this.borderColor,
  });

  Symbol copyWith({
    String? id,
    String? label,
    IconData? icon,
    SymbolCategory? category,
    String? audioPath,
    String? imageUrl,
    bool? isFolder,
    Uint8List? imageBytes,
    bool? isSvg,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Symbol(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      audioPath: audioPath ?? this.audioPath,
      imageUrl: imageUrl ?? this.imageUrl,
      isFolder: isFolder ?? this.isFolder,
      imageBytes: imageBytes ?? this.imageBytes,
      isSvg: isSvg ?? this.isSvg,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  /// JSON round-trip for local caching (schedules) and the backend tile API.
  ///
  /// Custom/drawn tiles carry their picture in [imageBytes]; we serialise those
  /// bytes as base64 ([imageB64]) so a redrawn tile survives a save/reload.
  /// Author tile colours are stored as 32-bit ARGB ints. [icon_name] is kept for
  /// backwards-compatibility with the predefined-icon lookup used by the bundled
  /// board; arbitrary [IconData] code points are intentionally NOT reconstructed
  /// to stay compatible with `--tree-shake-icons` release builds.
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'category': category.name,
    // Store it as a predictable string name instead of a codePoint integer
    'icon_name': id,
    'isSvg': isSvg,
    if (icon != null) 'iconCodePoint': icon!.codePoint,
    if (imageBytes != null) 'imageB64': base64Encode(imageBytes!),
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (backgroundColor != null) 'backgroundColor': backgroundColor!.toARGB32(),
    if (borderColor != null) 'borderColor': borderColor!.toARGB32(),
  };

  factory Symbol.fromJson(Map<String, dynamic> json) {
    final imageB64 = json['imageB64'] as String?;
    final mappedIcon = _getIconDataFromName((json['icon_name'] as String?) ?? '');
    return Symbol(
      id: json['id'] as String,
      label: json['label'] as String,
      category: SymbolCategory.values.byName(
        (json['category'] as String?) ?? 'noun',
      ),
      // Look up a known IconData by name; custom tiles fall back to a star so
      // there's always something to show when there is no picture.
      icon: mappedIcon ?? (imageB64 == null ? null : Icons.star),
      imageUrl: json['imageUrl'] as String?,
      imageBytes: imageB64 != null ? base64Decode(imageB64) : null,
      isSvg: json['isSvg'] as bool? ?? false,
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
      borderColor: json['borderColor'] != null
          ? Color(json['borderColor'] as int)
          : null,
    );
  }

  /// Backend tile-API shape: the same payload but keyed by `tile_id` (the
  /// backend Tile model) instead of the client-side `id`.
  Map<String, dynamic> toTileJson() {
    final json = toJson();
    json.remove('id');
    json.remove('icon_name');
    return {'tile_id': id, ...json};
  }

  factory Symbol.fromTileJson(Map<String, dynamic> json) {
    return Symbol.fromJson({...json, 'id': json['tile_id']});
  }

  static IconData? _getIconDataFromName(String name) {
    switch (name.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'break':
        return Icons.chair;
      case 'restaurant':
        return Icons.restaurant;
      case 'outside':
        return Icons.park;
      case 'tablet':
        return Icons.tablet;
      default:
        return null; // Let your UI fallback logic take care of the rest
    }
  }
}

class UserProfile {
  final String id;
  final String name;
  final int? age;
  final String? pronoun;
  final String avatarId;
  final List<String> likes;
  final List<String> dislikes;
  final String? currentMood;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    this.age,
    this.pronoun,
    this.avatarId = 'avatar_1',
    this.likes = const [],
    this.dislikes = const [],
    this.currentMood,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? pronoun,
    String? avatarId,
    List<String>? likes,
    List<String>? dislikes,
    String? currentMood,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      pronoun: pronoun ?? this.pronoun,
      avatarId: avatarId ?? this.avatarId,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      currentMood: currentMood ?? this.currentMood,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Matches the backend `Profile` model (frontend `id` maps to `profile_id`).
  /// Used both for the remote API and the local SharedPreferences cache.
  Map<String, dynamic> toJson() => {
    'profile_id': id,
    'name': name,
    if (age != null) 'age': age,
    if (pronoun != null) 'pronoun': pronoun,
    'avatarId': avatarId,
    'likes': likes,
    'dislikes': dislikes,
    if (currentMood != null) 'currentMood': currentMood,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: (json['profile_id'] ?? json['id']) as String,
    name: json['name'] as String,
    age: json['age'] as int?,
    pronoun: json['pronoun'] as String?,
    avatarId: (json['avatarId'] as String?) ?? 'avatar_1',
    likes: (json['likes'] as List?)?.cast<String>() ?? const [],
    dislikes: (json['dislikes'] as List?)?.cast<String>() ?? const [],
    currentMood: json['currentMood'] as String?,
    createdAt: json['createdAt'] != null
        ? (DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now())
        : DateTime.now(),
  );
}

class EmergencyOption {
  final String id;
  final String label;
  final IconData? icon;
  final Color color;
  final String? imageUrl;

  const EmergencyOption({
    required this.id,
    required this.label,
    this.icon,
    required this.color,
    this.imageUrl,
  });
}

class ImportedBoard {
  final String id;
  final String name;
  final BoardGrid grid;
  final List<ImportedButton> buttons;
  final Map<String, ImportedImage> imagesById;
  final String? sourcePath;

  const ImportedBoard({
    required this.id,
    required this.name,
    required this.grid,
    required this.buttons,
    required this.imagesById,
    this.sourcePath,
  });

  Map<String, ImportedButton> get buttonsById {
    return {for (final button in buttons) button.id: button};
  }
}

class BoardGrid {
  final int rows;
  final int columns;
  final List<List<String?>> order;

  const BoardGrid({
    required this.rows,
    required this.columns,
    required this.order,
  });
}

class ImportedButton {
  final String id;
  final String label;
  final String? vocalization;
  final String? imageId;
  final String? linkedBoardPath;
  final String? linkedBoardId;
  final String? linkedBoardName;

  /// Colours declared by the OBF author (`background_color` / `border_color`).
  /// Null when the board left them unspecified, so the UI can fall back to its
  /// own default styling. Imported boards are never re-coloured by Colourful
  /// Semantics — that scheme is reserved for the default hardcoded board.
  final Color? backgroundColor;
  final Color? borderColor;

  const ImportedButton({
    required this.id,
    required this.label,
    this.vocalization,
    this.imageId,
    this.linkedBoardPath,
    this.linkedBoardId,
    this.linkedBoardName,
    this.backgroundColor,
    this.borderColor,
  });

  String get speechText {
    final value = vocalization?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return label;
  }

  bool get hasLink {
    return (linkedBoardPath != null && linkedBoardPath!.isNotEmpty) ||
        (linkedBoardId != null && linkedBoardId!.isNotEmpty);
  }
}

class ImportedImage {
  final String id;
  final String? dataUri;
  final String? path;
  final String? url;

  /// OBF `content_type` (e.g. `image/png`, `image/svg+xml`). Used to decide
  /// which decoder to use — Flutter's raster [Image] cannot render SVG.
  final String? contentType;

  const ImportedImage({
    required this.id,
    this.dataUri,
    this.path,
    this.url,
    this.contentType,
  });
}

class ImportedBoardSet {
  final String? rootPath;
  final Map<String, ImportedBoard> boardsByPath;
  final Map<String, List<int>> filesByPath;

  const ImportedBoardSet({
    required this.rootPath,
    required this.boardsByPath,
    required this.filesByPath,
  });

  ImportedBoard? get rootBoard {
    if (rootPath == null) return null;
    return boardsByPath[rootPath];
  }
}

class ResolvedImportedImage {
  final Uint8List? bytes;
  final String? url;

  /// Whether the resolved source is an SVG, so the UI renders it with an SVG
  /// decoder rather than the raster [Image] widget (which throws on SVG).
  final bool isSvg;

  const ResolvedImportedImage({this.bytes, this.url, this.isSvg = false});

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
  bool get hasUrl => url != null && url!.isNotEmpty;
}

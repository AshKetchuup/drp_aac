import 'package:flutter/material.dart';
import 'dart:typed_data';

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

  const Symbol({
    required this.id,
    required this.label,
    this.icon,
    required this.category,
    this.audioPath,
    this.imageUrl,
    this.isFolder = false,
  });

  Symbol copyWith({
    String? id,
    String? label,
    IconData? icon,
    SymbolCategory? category,
    String? audioPath,
    String? imageUrl,
    bool? isFolder,
  }) {
    return Symbol(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      audioPath: audioPath ?? this.audioPath,
      imageUrl: imageUrl ?? this.imageUrl,
      isFolder: isFolder ?? this.isFolder,
    );
  }

  // Add to your Symbol class:
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'category': category.name,
    // Store it as a predictable string name instead of a codePoint integer
    'icon_name': id,
  };

  factory Symbol.fromJson(Map<String, dynamic> json) {
    return Symbol(
      id: json['id'] as String,
      label: json['label'] as String,
      category: SymbolCategory.values.byName(json['category'] as String),
      // Look up the IconData directly using the static mapping system
      icon: _getIconDataFromName(json['icon_name'] as String),
    );
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
  final String? location;
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
    this.location,
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
    String? location,
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
      location: location ?? this.location,
      avatarId: avatarId ?? this.avatarId,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      currentMood: currentMood ?? this.currentMood,
      createdAt: createdAt ?? this.createdAt,
    );
  }
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

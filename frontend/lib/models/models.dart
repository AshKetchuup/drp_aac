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

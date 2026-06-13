import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_client.dart';

/// Child profiles, persisted remotely (per teacher account) with a local
/// SharedPreferences cache so the app keeps working offline.
class ProfileRepository {
  ProfileRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;
  static const _cacheKey = 'profiles_cache';

  /// Remote list (source of truth); falls back to the cache when offline.
  Future<List<UserProfile>> load() async {
    try {
      final data = await _api.getJson('/api/profiles') as List? ?? [];
      final profiles = data
          .map((j) => UserProfile.fromJson(j as Map<String, dynamic>))
          .toList();
      await _writeCache(profiles);
      return profiles;
    } catch (_) {
      return _readCache();
    }
  }

  /// Write-through: update the cache immediately, then push to the backend.
  Future<void> save(UserProfile profile) async {
    final list = await _readCache();
    final idx = list.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      list[idx] = profile;
    } else {
      list.add(profile);
    }
    await _writeCache(list);
    await _api.postJson('/api/profiles', profile.toJson());
  }

  Future<void> delete(String profileId) async {
    final list = await _readCache()
      ..removeWhere((p) => p.id == profileId);
    await _writeCache(list);
    await _api.delete('/api/profiles/$profileId');
  }

  Future<List<UserProfile>> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((j) => UserProfile.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeCache(List<UserProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
  }
}

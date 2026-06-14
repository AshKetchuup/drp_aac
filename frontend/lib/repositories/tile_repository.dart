import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_client.dart';

/// Custom tiles for a single child profile, persisted remotely with a local
/// SharedPreferences cache (keyed per profile).
class TileRepository {
  TileRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;
  String _cacheKey(String profileId) => 'tiles_cache_$profileId';

  Future<List<Symbol>> load(String profileId) async {
    try {
      final data =
          await _api.getJson('/api/profiles/$profileId/tiles') as List? ?? [];
      final tiles = data
          .map((j) => Symbol.fromTileJson(j as Map<String, dynamic>))
          .toList();
      await _writeCache(profileId, tiles);
      return tiles;
    } catch (_) {
      return _readCache(profileId);
    }
  }

  Future<void> save(String profileId, Symbol tile) async {
    final list = await _readCache(profileId);
    final idx = list.indexWhere((s) => s.id == tile.id);
    if (idx >= 0) {
      list[idx] = tile;
    } else {
      list.add(tile);
    }
    await _writeCache(profileId, list);
    await _api.postJson('/api/profiles/$profileId/tiles', tile.toTileJson());
  }

  Future<void> delete(String profileId, String tileId) async {
    final list = await _readCache(profileId)
      ..removeWhere((s) => s.id == tileId);
    await _writeCache(profileId, list);
    await _api.delete('/api/profiles/$profileId/tiles/$tileId');
  }

  Future<List<Symbol>> _readCache(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(profileId));
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((j) => Symbol.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeCache(String profileId, List<Symbol> tiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey(profileId),
      jsonEncode(tiles.map((s) => s.toJson()).toList()),
    );
  }
}

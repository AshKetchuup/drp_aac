import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../widgets/scheduler.dart';
import '../services/api_client.dart';
import 'schedule_repository.dart';

/// Per-profile schedule backed by the remote API with a local SharedPreferences
/// cache. The active profile is supplied via [profileId]; the AAC provider
/// updates it whenever the teacher switches child. With no profile selected the
/// repository is a no-op (returns an empty schedule).
///
/// Serialisation mirrors [LocalScheduleRepository]: the whole schedule is one
/// `{"<dayIndex>_<slotIndex>": [symbolJson, ...]}` map.
class SyncedScheduleRepository implements ScheduleRepository {
  SyncedScheduleRepository({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;
  String? profileId;

  String get _cacheKey => 'schedule_${profileId ?? 'none'}';

  @override
  Future<Map<SlotKey, List<Symbol>>> load() async {
    if (profileId == null) return _empty();
    try {
      final resp = await _api.getJson('/api/profiles/$profileId/schedule');
      final data =
          (resp?['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      await _writeCacheRaw(data);
      return _decode(data);
    } catch (_) {
      return _decode(await _readCacheRaw());
    }
  }

  @override
  Future<void> save(Map<SlotKey, List<Symbol>> schedule) async {
    if (profileId == null) return;
    final data = _encode(schedule);
    // Cache first so the change survives locally, then sync best-effort: a
    // failed push (offline / demo / expired token) must not break editing.
    await _writeCacheRaw(data);
    try {
      await _api.putJson('/api/profiles/$profileId/schedule', {'data': data});
    } catch (e) {
      debugPrint('Schedule sync failed (kept locally): $e');
    }
  }

  @override
  Future<void> clear() async => save(_empty());

  // ── (de)serialisation ──────────────────────────────────────────────────
  Map<String, dynamic> _encode(Map<SlotKey, List<Symbol>> schedule) {
    final encoded = <String, dynamic>{};
    for (final entry in schedule.entries) {
      final key = '${entry.key.$1}_${entry.key.$2.index}';
      encoded[key] = entry.value.map((s) => s.toJson()).toList();
    }
    return encoded;
  }

  Map<SlotKey, List<Symbol>> _decode(Map<String, dynamic> data) {
    final result = _empty();
    for (final entry in data.entries) {
      final parts = entry.key.split('_');
      final dayIndex = int.parse(parts[0]);
      final slot = TimeSlot.values[int.parse(parts[1])];
      result[(dayIndex, slot)] = (entry.value as List)
          .map((s) => Symbol.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    return result;
  }

  // ── cache helpers ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _readCacheRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map).cast<String, dynamic>();
  }

  Future<void> _writeCacheRaw(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(data));
  }

  Map<SlotKey, List<Symbol>> _empty() => {
    for (var d = 0; d < 7; d++)
      for (final slot in TimeSlot.values) (d, slot): [],
  };
}

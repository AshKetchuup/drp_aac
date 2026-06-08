import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../widgets/scheduler.dart';
import 'schedule_repository.dart';

class LocalScheduleRepository implements ScheduleRepository {
  static const _key = 'schedule_data';

  @override
  Future<Map<SlotKey, List<Symbol>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return _emptySchedule();

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final result = _emptySchedule();

    for (final entry in decoded.entries) {
      final parts = entry.key.split('_');
      final dayIndex = int.parse(parts[0]);
      final slot = TimeSlot.values[int.parse(parts[1])];
      final symbols = (entry.value as List)
          .map((s) => Symbol.fromJson(s as Map<String, dynamic>))
          .toList();
      result[(dayIndex, slot)] = symbols;
    }

    return result;
  }

  @override
  Future<void> save(Map<SlotKey, List<Symbol>> schedule) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};

    for (final entry in schedule.entries) {
      final key = '${entry.key.$1}_${entry.key.$2.index}';
      encoded[key] = entry.value.map((s) => s.toJson()).toList();
    }

    await prefs.setString(_key, jsonEncode(encoded));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Map<SlotKey, List<Symbol>> _emptySchedule() => {
    for (var d = 0; d < 7; d++)
      for (final slot in TimeSlot.values) (d, slot): [],
  };
}
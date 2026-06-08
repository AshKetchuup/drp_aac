import '../models/models.dart';
import '../widgets/scheduler.dart';

abstract interface class ScheduleRepository {
  Future<Map<SlotKey, List<Symbol>>> load();
  Future<void> save(Map<SlotKey, List<Symbol>> schedule);
  Future<void> clear();
}
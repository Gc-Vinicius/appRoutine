import '../domain/routine_model.dart';
import '../../../core/services/alarm_scheduler_service.dart';
import '../../../core/services/local_storage_service.dart';

abstract class RoutineRepository {
  Future<List<RoutineModel>> getRoutines();
  Future<RoutineModel> saveRoutine(RoutineModel routine);
  Future<void> deleteRoutine(int id);
  Future<void> toggleRoutineActive(int id, bool isActive);
}

class LocalRoutineRepository implements RoutineRepository {
  final AlarmSchedulerService _alarmScheduler = AlarmSchedulerService();

  List<RoutineModel> _cachedRoutines = [];
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    final persisted = await LocalStorageService.loadRoutines();
    if (persisted != null) {
      _cachedRoutines = List.from(persisted);
    } else {
      _loadInitialRoutines();
      await LocalStorageService.saveRoutines(_cachedRoutines);
    }
    _isInitialized = true;
  }

  void _loadInitialRoutines() {
    // Rotinas padrão demonstrativas baseadas nos protótipos
    _cachedRoutines = [
      RoutineModel(
        id: 1,
        title: 'Tomar Creatina & Água',
        body: 'Tomar 5g creatina + 500ml água',
        type: RoutineType.recurring,
        hour: 7,
        minute: 0,
        weekdays: [1, 2, 3, 4, 5], // Seg a Sex
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      RoutineModel(
        id: 2,
        title: 'Beber Água (Meta 2.5L)',
        body: "Hora do copo d'água! 300ml",
        type: RoutineType.periodic,
        hour: 8,
        minute: 0,
        intervalMinutes: 120, // A cada 2 horas
        windowStartHour: 8,
        windowEndHour: 20,
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      RoutineModel(
        id: 3,
        title: 'Consulta Odontológica',
        body: 'Consulta com Dr. Eduardo no Centro',
        type: RoutineType.punctual,
        hour: 14,
        minute: 30,
        punctualDate: DateTime.now().add(const Duration(days: 7)),
        isActive: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Future<List<RoutineModel>> getRoutines() async {
    await _ensureInitialized();
    return List.unmodifiable(_cachedRoutines);
  }

  @override
  Future<RoutineModel> saveRoutine(RoutineModel routine) async {
    await _ensureInitialized();

    final RoutineModel savedRoutine;
    if (routine.id != null) {
      savedRoutine = routine;
      final index = _cachedRoutines.indexWhere((r) => r.id == routine.id);
      if (index >= 0) {
        _cachedRoutines[index] = savedRoutine;
      } else {
        _cachedRoutines.add(savedRoutine);
      }
    } else {
      final nextId = (DateTime.now().millisecondsSinceEpoch % 1000000);
      savedRoutine = routine.copyWith(id: nextId);
      _cachedRoutines.add(savedRoutine);
    }

    // Se estiver ativa, agenda no AlarmManager com exactAllowWhileIdle
    if (savedRoutine.isActive) {
      _scheduleRoutineAlarm(savedRoutine);
    } else if (savedRoutine.id != null) {
      await _alarmScheduler.cancelAlarm(savedRoutine.id!);
    }

    // Persistência em disco imediata
    await LocalStorageService.saveRoutines(_cachedRoutines);

    return savedRoutine;
  }

  @override
  Future<void> deleteRoutine(int id) async {
    await _ensureInitialized();
    _cachedRoutines.removeWhere((r) => r.id == id);
    await _alarmScheduler.cancelAlarm(id);
    await LocalStorageService.saveRoutines(_cachedRoutines);
  }

  @override
  Future<void> toggleRoutineActive(int id, bool isActive) async {
    await _ensureInitialized();
    final index = _cachedRoutines.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final updated = _cachedRoutines[index].copyWith(isActive: isActive);
      _cachedRoutines[index] = updated;

      if (isActive) {
        _scheduleRoutineAlarm(updated);
      } else {
        await _alarmScheduler.cancelAlarm(id);
      }

      await LocalStorageService.saveRoutines(_cachedRoutines);
    }
  }

  void _scheduleRoutineAlarm(RoutineModel routine) {
    if (routine.id == null) return;

    DateTime targetTime;
    final now = DateTime.now();

    if (routine.type == RoutineType.punctual && routine.punctualDate != null) {
      targetTime = DateTime(
        routine.punctualDate!.year,
        routine.punctualDate!.month,
        routine.punctualDate!.day,
        routine.hour,
        routine.minute,
      );
    } else {
      targetTime = DateTime(now.year, now.month, now.day, routine.hour, routine.minute);
      if (targetTime.isBefore(now)) {
        targetTime = targetTime.add(const Duration(days: 1));
      }
    }

    _alarmScheduler.scheduleExactAlarm(
      routine: routine,
      targetTime: targetTime,
    );
  }
}

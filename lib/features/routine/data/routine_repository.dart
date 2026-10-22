import '../domain/routine_model.dart';
import '../../../core/services/alarm_scheduler_service.dart';
import '../../../core/services/local_storage_service.dart';

abstract class RoutineRepository {
  Future<List<RoutineModel>> getRoutines();
  Future<RoutineModel> saveRoutine(RoutineModel routine);
  Future<void> deleteRoutine(int id);
  Future<void> toggleRoutineActive(int id, bool isActive);
  Future<void> toggleSkipNext(int id);
  Future<void> reloadFromStorage();
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
      // Remove resquícios dos lembretes padrão antigos
      _cachedRoutines.removeWhere((r) =>
          (r.id == 1 && r.title == 'Tomar Creatina & Água') ||
          (r.id == 2 && r.title == 'Beber Água (Meta 2.5L)') ||
          (r.id == 3 && r.title == 'Consulta Odontológica'));
      await LocalStorageService.saveRoutines(_cachedRoutines);
    } else {
      _cachedRoutines = [];
      await LocalStorageService.saveRoutines(_cachedRoutines);
    }
    _isInitialized = true;

    // Garante que todas as rotinas ativas estejam agendadas no sistema operacional
    for (final routine in _cachedRoutines) {
      if (routine.isActive && !routine.isCurrentlySkipped) {
        _scheduleRoutineAlarm(routine);
      }
    }
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

  @override
  Future<void> toggleSkipNext(int id) async {
    await _ensureInitialized();
    final index = _cachedRoutines.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final routine = _cachedRoutines[index];
      final DateTime? newSkippedUntil;
      if (routine.isCurrentlySkipped) {
        newSkippedUntil = null; // Reativa o alarme normal
      } else {
        final next = routine.nextOccurrence;
        if (next != null) {
          // Pausa até 1 minuto após a ocorrência que seria disparada
          newSkippedUntil = next.add(const Duration(minutes: 1));
        } else {
          newSkippedUntil = DateTime.now().add(const Duration(days: 1));
        }
      }

      final updated = routine.copyWith(skippedUntil: newSkippedUntil);
      _cachedRoutines[index] = updated;

      if (updated.isActive && !updated.isCurrentlySkipped) {
        _scheduleRoutineAlarm(updated);
      }

      await LocalStorageService.saveRoutines(_cachedRoutines);
    }
  }

  @override
  Future<void> reloadFromStorage() async {
    final persisted = await LocalStorageService.loadRoutines();
    if (persisted != null) {
      _cachedRoutines = List.from(persisted);
      _cachedRoutines.removeWhere((r) =>
          (r.id == 1 && r.title == 'Tomar Creatina & Água') ||
          (r.id == 2 && r.title == 'Beber Água (Meta 2.5L)') ||
          (r.id == 3 && r.title == 'Consulta Odontológica'));
      // Re-agenda alarmes para todas as rotinas ativas
      for (final routine in _cachedRoutines) {
        if (routine.isActive && !routine.isCurrentlySkipped) {
          _scheduleRoutineAlarm(routine);
        } else if (routine.id != null) {
          await _alarmScheduler.cancelAlarm(routine.id!);
        }
      }
    }
  }

  void _scheduleRoutineAlarm(RoutineModel routine) {
    if (routine.id == null) return;

    DateTime? targetTime = routine.nextOccurrence;
    if (targetTime == null) {
      final now = DateTime.now();
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

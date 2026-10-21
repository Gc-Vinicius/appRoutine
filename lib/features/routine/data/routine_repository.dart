import '../domain/routine_model.dart';
import '../../../core/services/alarm_scheduler_service.dart';

abstract class RoutineRepository {
  Future<List<RoutineModel>> getRoutines();
  Future<RoutineModel> saveRoutine(RoutineModel routine);
  Future<void> deleteRoutine(int id);
  Future<void> toggleRoutineActive(int id, bool isActive);
}

class LocalRoutineRepository implements RoutineRepository {
  final AlarmSchedulerService _alarmScheduler = AlarmSchedulerService();

  // Memória cache local para reatividade imediata
  List<RoutineModel> _cachedRoutines = [];

  LocalRoutineRepository() {
    _loadInitialRoutines();
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
        isActive: false, // Desativado após disparo ou inicial
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Future<List<RoutineModel>> getRoutines() async {
    return List.unmodifiable(_cachedRoutines);
  }

  @override
  Future<RoutineModel> saveRoutine(RoutineModel routine) async {
    final nextId = routine.id ?? (DateTime.now().millisecondsSinceEpoch % 100000);
    final savedRoutine = routine.copyWith(id: nextId);

    final index = _cachedRoutines.indexWhere((r) => r.id == nextId);
    if (index >= 0) {
      _cachedRoutines[index] = savedRoutine;
    } else {
      _cachedRoutines.add(savedRoutine);
    }

    // Se estiver ativa, agenda no AlarmManager
    if (savedRoutine.isActive) {
      _scheduleRoutineAlarm(savedRoutine);
    } else {
      await _alarmScheduler.cancelAlarm(savedRoutine.id!);
    }

    return savedRoutine;
  }

  @override
  Future<void> deleteRoutine(int id) async {
    _cachedRoutines.removeWhere((r) => r.id == id);
    await _alarmScheduler.cancelAlarm(id);
  }

  @override
  Future<void> toggleRoutineActive(int id, bool isActive) async {
    final index = _cachedRoutines.indexWhere((r) => r.id == id);
    if (index >= 0) {
      final updated = _cachedRoutines[index].copyWith(isActive: isActive);
      _cachedRoutines[index] = updated;

      if (isActive) {
        _scheduleRoutineAlarm(updated);
      } else {
        await _alarmScheduler.cancelAlarm(id);
      }
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
      // Próximo horário correspondente
      targetTime = DateTime(now.year, now.month, now.day, routine.hour, routine.minute);
      if (targetTime.isBefore(now)) {
        targetTime = targetTime.add(const Duration(days: 1));
      }
    }

    _alarmScheduler.scheduleExactAlarm(
      id: routine.id!,
      targetTime: targetTime,
    );
  }
}

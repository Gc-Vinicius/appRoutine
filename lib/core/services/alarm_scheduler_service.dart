import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';
import '../../features/routine/domain/routine_model.dart';

/// Top-level callback executado pelo AlarmManager quando o celular acorda do Doze Mode
@pragma('vm:entry-point')
void alarmDispatchCallback(int id) async {
  debugPrint('[AlarmManager] Callback disparado para o ID: $id');
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final notifService = NotificationService();
    await notifService.initialize();

    final routines = await LocalStorageService.loadRoutines();
    RoutineModel? routine;
    if (routines != null) {
      try {
        routine = routines.firstWhere((r) => r.id == id);
      } catch (_) {}
    }

    final title = routine?.title ?? 'Hora da Rotina!';
    final body = routine?.body ?? 'Alarme disparado no seu horário programado.';
    final isAlarm = routine?.isAlarm ?? true;

    await notifService.showNotification(
      id: id,
      title: title,
      body: body,
      isAlarm: isAlarm,
    );
  } catch (e) {
    debugPrint('[AlarmManager] Erro no callback de background: $e');
  }
}

/// Serviço de agendamento com redundância nativa (RNF02)
class AlarmSchedulerService {
  static final AlarmSchedulerService _instance = AlarmSchedulerService._internal();
  factory AlarmSchedulerService() => _instance;
  AlarmSchedulerService._internal();

  Future<void> initialize() async {
    try {
      await AndroidAlarmManager.initialize();
      debugPrint('[AlarmManager] Inicializado com sucesso.');
    } catch (e) {
      debugPrint('[AlarmManager] Erro ao inicializar: $e');
    }
  }

  /// Agenda alarme exato com redundância dupla (LocalNotification + AlarmManager)
  Future<bool> scheduleExactAlarm({
    required RoutineModel routine,
    required DateTime targetTime,
  }) async {
    try {
      if (routine.id == null) return false;

      // 1. Agendamento nativo via flutter_local_notifications (AlarmManager nativo com exactAllowWhileIdle/inexact)
      await NotificationService().scheduleRoutineNotification(routine);

      // 2. Agendamento redundante via android_alarm_manager_plus
      final canExact = await NotificationService().canScheduleExact();
      try {
        await AndroidAlarmManager.oneShotAt(
          targetTime,
          routine.id!,
          alarmDispatchCallback,
          exact: canExact,
          wakeup: true,
          allowWhileIdle: true,
          rescheduleOnReboot: true,
        );
      } catch (e) {
        debugPrint('[AlarmManager] oneShotAt ignorado ou com erro: $e');
      }

      return true;
    } catch (e) {
      debugPrint('[AlarmManager] Falha ao agendar alarme: $e');
      return false;
    }
  }

  /// Cancela alarme agendado no sistema operacional em ambos os subsistemas
  Future<bool> cancelAlarm(int id) async {
    try {
      await NotificationService().cancelRoutine(id);
      return await AndroidAlarmManager.cancel(id);
    } catch (e) {
      debugPrint('[AlarmManager] Falha ao cancelar alarme $id: $e');
      return false;
    }
  }
}

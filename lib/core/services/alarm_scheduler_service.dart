import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'notification_service.dart';
import 'local_storage_service.dart';
import '../../features/routine/domain/routine_model.dart';

/// Top-level callback executado pelo AlarmManager quando o celular acorda do Doze Mode
@pragma('vm:entry-point')
void alarmDispatchCallback(int id) async {
  debugPrint('[AlarmManager] Callback disparado para o ID: $id');
  WidgetsFlutterBinding.ensureInitialized();

  // Buscar dados reais da rotina persistida
  final routines = await LocalStorageService.loadRoutines();
  RoutineModel? matched;
  if (routines != null) {
    try {
      matched = routines.firstWhere((r) => r.id == id);
    } catch (_) {}
  }

  final notifService = NotificationService();
  await notifService.initialize();
  await notifService.showNotification(
    id: id,
    title: matched?.title ?? 'Hora da Rotina!',
    body: matched?.body ?? 'Alarme pontual disparado no segundo exato.',
  );
}

/// Serviço de agendamento exato utilizando o android_alarm_manager_plus (RNF02)
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

      // 1. Agendamento nativo via flutter_local_notifications (AlarmManager nativo com exactAllowWhileIdle)
      await NotificationService().scheduleRoutineNotification(routine);

      // 2. Agendamento redundante via android_alarm_manager_plus
      return await AndroidAlarmManager.oneShotAt(
        targetTime,
        routine.id!,
        alarmDispatchCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
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

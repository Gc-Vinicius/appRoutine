import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Top-level callback executado pelo AlarmManager quando o celular acorda do Doze Mode
@pragma('vm:entry-point')
void alarmDispatchCallback(int id) async {
  debugPrint('[AlarmManager] Callback de alarme disparado para o ID: $id');
  final notifService = NotificationService();
  await notifService.initialize();
  await notifService.showNotification(
    id: id,
    title: 'Hora da Rotina!',
    body: 'Alarme pontual disparado no segundo exato.',
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

  /// Agenda alarme exato furando o Doze Mode da bateria
  Future<bool> scheduleExactAlarm({
    required int id,
    required DateTime targetTime,
  }) async {
    try {
      return await AndroidAlarmManager.oneShotAt(
        targetTime,
        id,
        alarmDispatchCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true, // Garante que fure o modo de hibernação profunda (Doze Mode)
        rescheduleOnReboot: true,
      );
    } catch (e) {
      debugPrint('[AlarmManager] Falha ao agendar alarme $id: $e');
      return false;
    }
  }

  /// Cancela alarme agendado no sistema operacional
  Future<bool> cancelAlarm(int id) async {
    try {
      return await AndroidAlarmManager.cancel(id);
    } catch (e) {
      debugPrint('[AlarmManager] Falha ao cancelar alarme $id: $e');
      return false;
    }
  }
}

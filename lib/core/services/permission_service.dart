import 'dart:io' show Platform;
import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';

class SystemPermissionStatus {
  final bool hasNotification;
  final bool hasExactAlarm;
  final bool hasBatteryOptimizationExemption;

  const SystemPermissionStatus({
    required this.hasNotification,
    required this.hasExactAlarm,
    required this.hasBatteryOptimizationExemption,
  });

  bool get isAllGranted =>
      hasNotification && hasExactAlarm && hasBatteryOptimizationExemption;

  int get grantedCount {
    int count = 0;
    if (hasNotification) count++;
    if (hasExactAlarm) count++;
    if (hasBatteryOptimizationExemption) count++;
    return count;
  }
}

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Verifica o status real das permissões críticas do Android
  Future<SystemPermissionStatus> checkAllPermissions() async {
    final notifStatus = await Permission.notification.status;
    final exactCan = await NotificationService().canScheduleExact();
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

    return SystemPermissionStatus(
      hasNotification: notifStatus.isGranted,
      hasExactAlarm: exactCan,
      hasBatteryOptimizationExemption: batteryStatus.isGranted,
    );
  }

  /// Solicita permissão de notificações (Android 13+)
  Future<bool> requestNotificationPermission() async {
    final granted = await NotificationService().requestNotificationPermission();
    if (!granted) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return granted;
  }

  /// Solicita permissão para abrir em tela cheia sobre a tela de bloqueio (Android 14+)
  Future<bool> requestFullScreenIntentPermission() async {
    return await NotificationService().requestFullScreenIntentPermission();
  }

  /// Redireciona o usuário para ativar 'Alarmes e Lembretes' no Android 12/13/14/15
  Future<void> requestExactAlarmPermission() async {
    await NotificationService().requestExactAlarmPermission();

    if (Platform.isAndroid) {
      try {
        const intent = AndroidIntent(
          action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
          data: 'package:com.example.app_routine',
        );
        await intent.launch();
      } catch (_) {
        try {
          const generalIntent = AndroidIntent(
            action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
            data: 'package:com.example.app_routine',
          );
          await generalIntent.launch();
        } catch (_) {}
      }
    }
  }

  /// Solicita isenção de otimização de bateria (Doze Mode / OEMs)
  Future<bool> requestBatteryOptimizationExemption() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  /// Abre as configurações do sistema do aplicativo
  Future<bool> openSystemSettings() async {
    return await openAppSettings();
  }
}

import 'package:permission_handler/permission_handler.dart';

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

  /// Verifica o status atual das permissões críticas do Android
  Future<SystemPermissionStatus> checkAllPermissions() async {
    final notifStatus = await Permission.notification.status;
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;

    return SystemPermissionStatus(
      hasNotification: notifStatus.isGranted,
      hasExactAlarm: exactAlarmStatus.isGranted,
      hasBatteryOptimizationExemption: batteryStatus.isGranted,
    );
  }

  /// Solicita permissão de notificações (Android 13+)
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Solicita permissão de alarme exato (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
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

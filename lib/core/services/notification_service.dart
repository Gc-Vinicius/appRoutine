import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';
import '../../features/routine/domain/routine_model.dart';

/// Serviço responsável por emitir notificações locais nativas com canal de alta prioridade.
/// O app ponte do smartwatch (Haylou Fun) intercepta estas notificações e as repassa ao pulso via BLE.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  AndroidFlutterLocalNotificationsPlugin? get androidPlugin =>
      _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final now = DateTime.now();
      final locationName = now.timeZoneName;
      try {
        tz.setLocalLocation(tz.getLocation(locationName));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
      }
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        if (response.actionId == 'action_snooze_10') {
          final id = response.id ?? 9999;
          final title = response.payload ?? 'Lembrete em Soneca';
          await snoozeRoutine(
            id: id,
            title: title,
            body: 'Soneca ativada (+10 minutos)',
            minutes: 10,
          );
        }
      },
    );

    await _createHighPriorityChannel();
    _isInitialized = true;
  }

  /// Checa se o sistema operacional autorizou agendamento de alarmes exatos
  Future<bool> canScheduleExact() async {
    try {
      final plugin = androidPlugin;
      if (plugin == null) return false;
      return await plugin.canScheduleExactNotifications() ?? false;
    } catch (e) {
      debugPrint('[NotificationService] canScheduleExact: $e');
      return false;
    }
  }

  /// Redireciona para o painel nativo do Android para ativar 'Alarmes e Lembretes'
  Future<void> requestExactAlarmPermission() async {
    try {
      final plugin = androidPlugin;
      if (plugin != null) {
        await plugin.requestExactAlarmsPermission();
      }
    } catch (e) {
      debugPrint('[NotificationService] requestExactAlarmPermission: $e');
    }
  }

  /// Solicita permissão de notificações nativas (Android 13+)
  Future<bool> requestNotificationPermission() async {
    try {
      final plugin = androidPlugin;
      if (plugin != null) {
        final granted = await plugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[NotificationService] requestNotificationPermission: $e');
    }
    return false;
  }

  /// Cria o canal nativo de Alta Prioridade com som e vibração habilitados (RNF06)
  Future<void> _createHighPriorityChannel() async {
    const androidChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  NotificationDetails _buildNotificationDetails(String title, {bool allowSnooze = true}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        ticker: title,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
        actions: allowSnooze
            ? <AndroidNotificationAction>[
                const AndroidNotificationAction(
                  'action_snooze_10',
                  'Soneca (+10m)',
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
              ]
            : null,
      ),
    );
  }

  /// Dispara um alarme de soneca (+X minutos)
  Future<void> snoozeRoutine({
    required int id,
    required String title,
    required String body,
    int minutes = 10,
  }) async {
    await initialize();
    final canExact = await canScheduleExact();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final snoozeTime = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
    await _notificationsPlugin.zonedSchedule(
      id + 500000,
      '[Soneca] $title',
      body,
      snoozeTime,
      _buildNotificationDetails(title, allowSnooze: false),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Dispara notificação local nativa imediata
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    await _notificationsPlugin.show(
      id,
      title,
      body,
      _buildNotificationDetails(title),
    );
  }

  /// Agenda alarme nativo com exactAllowWhileIdle (ou fallback inexactAllowWhileIdle)
  Future<void> scheduleRoutineNotification(RoutineModel routine) async {
    if (routine.id == null || !routine.isActive) return;
    await initialize();

    final now = DateTime.now();
    final details = _buildNotificationDetails(routine.title);

    final canExact = await canScheduleExact();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    // Limpar agendamentos anteriores do mesmo ID
    await cancelRoutine(routine.id!);

    try {
      if (routine.type == RoutineType.punctual) {
        DateTime target = routine.punctualDate ?? DateTime(now.year, now.month, now.day, routine.hour, routine.minute);
        target = DateTime(target.year, target.month, target.day, routine.hour, routine.minute);

        if (target.isAfter(now)) {
          final tzTarget = tz.TZDateTime.from(target, tz.local);
          await _notificationsPlugin.zonedSchedule(
            routine.id!,
            routine.title,
            routine.body,
            tzTarget,
            details,
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      } else if (routine.type == RoutineType.recurring) {
        if (routine.weekdays.isEmpty) return;

        for (final weekday in routine.weekdays) {
          final subId = (routine.id! * 10) + weekday;
          final target = _nextInstanceOfDay(weekday, routine.hour, routine.minute);
          final tzTarget = tz.TZDateTime.from(target, tz.local);

          await _notificationsPlugin.zonedSchedule(
            subId,
            routine.title,
            routine.body,
            tzTarget,
            details,
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      } else if (routine.type == RoutineType.periodic) {
        final interval = routine.intervalMinutes ?? 120;
        final startH = routine.windowStartHour ?? 8;
        final endH = routine.windowEndHour ?? 20;
        final stepHours = (interval ~/ 60).clamp(1, 24);

        int slot = 0;
        for (int h = startH; h <= endH; h += stepHours) {
          final subId = (routine.id! * 100) + slot;
          slot++;

          DateTime target = DateTime(now.year, now.month, now.day, h, routine.minute);
          if (target.isBefore(now)) {
            target = target.add(const Duration(days: 1));
          }

          final tzTarget = tz.TZDateTime.from(target, tz.local);
          await _notificationsPlugin.zonedSchedule(
            subId,
            routine.title,
            routine.body,
            tzTarget,
            details,
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Falha no agendamento: $e. Tentando fallback...');
      if (canExact) {
        try {
          if (routine.type == RoutineType.punctual) {
            final target = routine.punctualDate ?? DateTime(now.year, now.month, now.day, routine.hour, routine.minute);
            if (target.isAfter(now)) {
              await _notificationsPlugin.zonedSchedule(
                routine.id!,
                routine.title,
                routine.body,
                tz.TZDateTime.from(target, tz.local),
                details,
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              );
            }
          } else if (routine.type == RoutineType.recurring) {
            for (final weekday in routine.weekdays) {
              final subId = (routine.id! * 10) + weekday;
              final target = _nextInstanceOfDay(weekday, routine.hour, routine.minute);
              await _notificationsPlugin.zonedSchedule(
                subId,
                routine.title,
                routine.body,
                tz.TZDateTime.from(target, tz.local),
                details,
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
                matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              );
            }
          }
        } catch (_) {}
      }
    }
  }

  DateTime _nextInstanceOfDay(int targetWeekday, int hour, int minute) {
    final now = DateTime.now();
    DateTime scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    while (scheduledDate.weekday != targetWeekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Cancela a rotina e todas as instâncias associadas
  Future<void> cancelRoutine(int id) async {
    await _notificationsPlugin.cancel(id);
    for (int day = 1; day <= 7; day++) {
      await _notificationsPlugin.cancel((id * 10) + day);
    }
    for (int slot = 0; slot < 24; slot++) {
      await _notificationsPlugin.cancel((id * 100) + slot);
    }
  }

  /// Dispara alarme de teste agendado (ex: daqui a 10 segundos) com tela bloqueada
  Future<void> testScheduledNotificationInSeconds({int seconds = 10}) async {
    await initialize();
    final canExact = await canScheduleExact();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final targetTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

    await _notificationsPlugin.zonedSchedule(
      888888,
      '⏰ Teste Agendado (10s)!',
      'O sistema operacional acordou e disparou no seu pulso!',
      targetTime,
      _buildNotificationDetails('Teste Agendado', allowSnooze: false),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Dispara notificação de teste imediato para validar no smartwatch Haylou Solar Neo
  Future<void> testWatchNotification() async {
    await showNotification(
      id: 99999,
      title: 'Teste: Haylou Solar Neo',
      body: 'Seu relógio está conectado e pronto para vibrar nos alarmes!',
    );
  }

  Future<void> cancelNotification(int id) async {
    await cancelRoutine(id);
  }
}

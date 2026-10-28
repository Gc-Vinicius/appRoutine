import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';
import 'local_storage_service.dart';
import '../../main.dart';
import '../../features/routine/domain/routine_model.dart';
import '../../features/routine/presentation/screens/alarm_ringing_screen.dart';
import '../../features/routine/data/routine_repository.dart';

/// Serviço responsável por emitir notificações locais nativas com canal de alta prioridade.
/// O app ponte do smartwatch (Haylou Fun) intercepta estas notificações e as repassa ao pulso via BLE.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  static bool isAlarmScreenOpen = false;

  AndroidFlutterLocalNotificationsPlugin? get androidPlugin =>
      _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('[NotificationService] Falha ao obter fuso horário real: $e');
      try {
        tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
      } catch (_) {}
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    await _createHighPriorityChannel();
    _isInitialized = true;

    // Trata inicialização via cold start (quando app é acordado fechado pela notificação/fullScreenIntent)
    _checkLaunchNotificationDetails();
  }

  Future<void> _checkLaunchNotificationDetails() async {
    try {
      final launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse != null) {
        // Aguarda a montagem do appNavigatorKey na árvore de widgets
        for (int i = 0; i < 15; i++) {
          if (appNavigatorKey.currentState != null) {
            await _handleNotificationResponse(launchDetails.notificationResponse!);
            break;
          }
          await Future.delayed(const Duration(milliseconds: 150));
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] _checkLaunchNotificationDetails: $e');
    }
  }

  Future<void> _handleNotificationResponse(NotificationResponse response) async {
    if (response.actionId == 'action_done') {
      final routines = await LocalStorageService.loadRoutines();
      final respId = response.id;
      if (routines != null && respId != null) {
        final target = routines.cast<RoutineModel?>().firstWhere(
          (r) =>
              r?.id == respId ||
              (r != null &&
                  (respId ~/ 10 == r.id ||
                      respId ~/ 100 == r.id)),
          orElse: () => null,
        );
        final targetId = target?.id;
        if (targetId != null) {
          await LocalStorageService.toggleCheckinToday(targetId);
          if (target != null && target.isOneShot) {
            await LocalRoutineRepository().deleteRoutine(targetId);
          }
        }
      }
    } else if (response.actionId == 'action_snooze' || response.actionId == 'action_snooze_10') {
      final id = response.id ?? 9999;
      final title = response.payload ?? 'Lembrete em Soneca';
      final settings = await LocalStorageService.loadAlarmSettings();
      await snoozeRoutine(
        id: id,
        title: title,
        body: 'Soneca ativada (+${settings.snoozeDurationMinutes} minutos)',
        minutes: settings.snoozeDurationMinutes,
      );
    } else {
      // Usuário tocou na notificação principal ou SO disparou o fullScreenIntent
      if (response.id != null) {
        final routines = await LocalStorageService.loadRoutines();
        if (routines != null) {
          final target = routines.cast<RoutineModel?>().firstWhere(
            (r) =>
                r?.id == response.id ||
                (r != null &&
                    (response.id! ~/ 10 == r.id ||
                        response.id! ~/ 100 == r.id)),
            orElse: () => null,
          );
          if (target != null && target.isOneShot && target.id != null) {
            await LocalRoutineRepository().deleteRoutine(target.id!);
          }
        }
      }
      await openAlarmScreenForId(response.id, payload: response.payload);
    }
  }

  /// Abre a tela imersiva de alarme tocando caso seja um alarme e ainda não esteja aberta
  Future<void> openAlarmScreenForId(
    int? notificationId, {
    String? payload,
    RoutineModel? explicitRoutine,
  }) async {
    if (isAlarmScreenOpen) return;

    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    RoutineModel? target = explicitRoutine;
    if (target == null) {
      final routines = await LocalStorageService.loadRoutines();
      if (routines != null && notificationId != null) {
        try {
          target = routines.firstWhere(
            (r) =>
                r.id == notificationId ||
                (r.id != null &&
                    (notificationId ~/ 10 == r.id ||
                        notificationId ~/ 100 == r.id)),
          );
        } catch (_) {}
      }
      target ??= RoutineModel(
        id: notificationId ?? 9999,
        title: payload ?? 'Hora da Rotina!',
        body: 'Alarme disparado no seu celular e relógio.',
        type: RoutineType.recurring,
        category: RoutineCategory.general,
        hour: DateTime.now().hour,
        minute: DateTime.now().minute,
        isAlarm: true,
        isActive: true,
        createdAt: DateTime.now(),
      );
    }

    // Somente alarmes abrem a tela cheia de despertar. Lembretes apenas abrem o app.
    if (target.isAlarm) {
      isAlarmScreenOpen = true;
      nav.push(
        MaterialPageRoute(
          builder: (_) => AlarmRingingScreen(routine: target!),
        ),
      ).then((_) {
        isAlarmScreenOpen = false;
      });
    }
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

  /// Solicita permissão nativa de tela cheia / sobreposição ao bloquear (Android 14+)
  Future<bool> requestFullScreenIntentPermission() async {
    try {
      final plugin = androidPlugin;
      if (plugin != null) {
        final granted = await plugin.requestFullScreenIntentPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[NotificationService] requestFullScreenIntentPermission: $e');
    }
    return false;
  }

  /// Cria os canais nativos: Alarmes (máxima prioridade com tela cheia) e Lembretes (discreto para smartwatch)
  Future<void> _createHighPriorityChannel() async {
    const alarmChannel = AndroidNotificationChannel(
      AppConstants.alarmChannelId,
      AppConstants.alarmChannelName,
      description: AppConstants.alarmChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const reminderChannel = AndroidNotificationChannel(
      AppConstants.reminderChannelId,
      AppConstants.reminderChannelName,
      description: AppConstants.reminderChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const legacyChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await androidPlugin?.createNotificationChannel(alarmChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(legacyChannel);
  }

  NotificationDetails _buildNotificationDetails(
    String title, {
    bool isAlarm = true,
    bool allowSnooze = true,
    int snoozeMinutes = 10,
  }) {
    if (isAlarm) {
      return NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.alarmChannelId,
          AppConstants.alarmChannelName,
          channelDescription: AppConstants.alarmChannelDescription,
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
                    'action_done',
                    'Concluir ✓',
                    showsUserInterface: false,
                    cancelNotification: true,
                  ),
                  AndroidNotificationAction(
                    'action_snooze',
                    'Soneca (+${snoozeMinutes}m)',
                    showsUserInterface: true,
                    cancelNotification: true,
                  ),
                ]
              : null,
        ),
      );
    } else {
      // Lembrete: formato otimizado para o relógio BLE e notificação heads-up limpa
      return NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.reminderChannelId,
          AppConstants.reminderChannelName,
          channelDescription: AppConstants.reminderChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: title,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          fullScreenIntent: false,
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              'action_done',
              'Concluir ✓',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      );
    }
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
      _buildNotificationDetails(title, allowSnooze: false, snoozeMinutes: minutes),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: title,
    );
  }

  /// Dispara notificação local nativa imediata
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    bool isAlarm = true,
  }) async {
    await initialize();
    final settings = await LocalStorageService.loadAlarmSettings();
    await _notificationsPlugin.show(
      id,
      title,
      body,
      _buildNotificationDetails(
        title,
        isAlarm: isAlarm,
        snoozeMinutes: settings.snoozeDurationMinutes,
      ),
      payload: title,
    );
  }

  /// Agenda alarme nativo com exactAllowWhileIdle (ou fallback inexactAllowWhileIdle)
  Future<void> scheduleRoutineNotification(RoutineModel routine) async {
    if (routine.id == null || !routine.isActive) return;
    await initialize();

    final now = DateTime.now();
    final tzNow = tz.TZDateTime.now(tz.local);
    final settings = await LocalStorageService.loadAlarmSettings();
    final details = _buildNotificationDetails(
      routine.title,
      isAlarm: routine.isAlarm,
      allowSnooze: routine.isAlarm,
      snoozeMinutes: settings.snoozeDurationMinutes,
    );

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
          final tzTarget = tz.TZDateTime(
            tz.local,
            target.year,
            target.month,
            target.day,
            routine.hour,
            routine.minute,
          );
          await _notificationsPlugin.zonedSchedule(
            routine.id!,
            routine.title,
            routine.body,
            tzTarget,
            details,
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: routine.title,
          );
        }
      } else if (routine.type == RoutineType.recurring) {
        if (routine.weekdays.isEmpty) return;

        for (final weekday in routine.weekdays) {
          final subId = (routine.id! * 10) + weekday;
          final tzTarget = _nextInstanceOfDay(weekday, routine.hour, routine.minute);

          await _notificationsPlugin.zonedSchedule(
            subId,
            routine.title,
            routine.body,
            tzTarget,
            details,
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: routine.title,
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

          tz.TZDateTime target = tz.TZDateTime(
            tz.local,
            tzNow.year,
            tzNow.month,
            tzNow.day,
            h,
            routine.minute,
          );
          if (target.isBefore(tzNow)) {
            target = target.add(const Duration(days: 1));
          }

          await _notificationsPlugin.zonedSchedule(
            subId,
            routine.title,
            routine.body,
            target,
            details,
            androidScheduleMode: scheduleMode,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: routine.title,
          );
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Falha no agendamento: $e. Tentando fallback inexato...');
      if (canExact) {
        try {
          if (routine.type == RoutineType.punctual) {
            final target = routine.punctualDate ?? DateTime(now.year, now.month, now.day, routine.hour, routine.minute);
            if (target.isAfter(now)) {
              await _notificationsPlugin.zonedSchedule(
                routine.id!,
                routine.title,
                routine.body,
                tz.TZDateTime(tz.local, target.year, target.month, target.day, routine.hour, routine.minute),
                details,
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
                payload: routine.title,
              );
            }
          } else if (routine.type == RoutineType.recurring) {
            for (final weekday in routine.weekdays) {
              final subId = (routine.id! * 10) + weekday;
              final tzTarget = _nextInstanceOfDay(weekday, routine.hour, routine.minute);
              await _notificationsPlugin.zonedSchedule(
                subId,
                routine.title,
                routine.body,
                tzTarget,
                details,
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
                matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
                payload: routine.title,
              );
            }
          }
        } catch (_) {}
      }
    }
  }

  tz.TZDateTime _nextInstanceOfDay(int targetWeekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

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
      _buildNotificationDetails(
        'Teste Agendado',
        isAlarm: true,
        allowSnooze: false,
      ),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: '⏰ Teste Agendado (10s)!',
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

  /// Retorna lista de agendamentos pendentes ativos no sistema operacional
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await initialize();
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  Future<void> cancelNotification(int id) async {
    await cancelRoutine(id);
  }
}

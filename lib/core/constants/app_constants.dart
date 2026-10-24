/// Constantes globais da aplicação e limites ergonômicos para o Haylou Solar Neo
class AppConstants {
  // Limites Rígidos de Caracteres para o Smartwatch Haylou Solar Neo (RF02)
  static const int maxTitleLength = 30;
  static const int maxBodyLength = 70;

  // Canais de Notificação Nativa do Android
  static const String notificationChannelId = 'app_routine_high_priority_channel';
  static const String notificationChannelName = 'Alarmes de Alta Prioridade';
  static const String notificationChannelDescription =
      'Canal de notificação de máxima importância com som e vibração para espelhamento BLE no smartwatch.';

  static const String alarmChannelId = 'app_routine_alarm_channel';
  static const String alarmChannelName = 'Alarmes do Celular';
  static const String alarmChannelDescription =
      'Canal de alarme com som alto e tela cheia dedicado a despertar no celular.';

  static const String reminderChannelId = 'app_routine_reminder_channel';
  static const String reminderChannelName = 'Lembretes & Smartwatch';
  static const String reminderChannelDescription =
      'Canal de notificações pontuais e vibração discreta para espelhamento no smartwatch.';

  // Chaves de Preferência
  static const String prefSelectedTheme = 'selected_app_theme';

  // Smartwatch Especificações
  static const String watchModelName = 'Haylou Solar Neo';
  static const String bridgeAppHaylouFun = 'Haylou Fun';
}

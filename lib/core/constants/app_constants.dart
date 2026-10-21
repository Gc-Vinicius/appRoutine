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

  // Chaves de Preferência
  static const String prefSelectedTheme = 'selected_app_theme';

  // Smartwatch Especificações
  static const String watchModelName = 'Haylou Solar Neo';
  static const String bridgeAppHaylouFun = 'Haylou Fun';
}

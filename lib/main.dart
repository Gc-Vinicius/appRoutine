import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/alarm_scheduler_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/routine/presentation/screens/home_screen.dart';

/// Chave de navegação global para permitir transição à tela cheia de alarme a partir de notificações nativas
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização dos serviços essenciais de background e wearable
  final notificationService = NotificationService();
  await notificationService.initialize();

  final alarmScheduler = AlarmSchedulerService();
  await alarmScheduler.initialize();

  // Carrega a preferência de tema salva em disco
  final savedPalette = await LocalStorageService.loadSavedTheme();

  runApp(
    ProviderScope(
      overrides: [
        initialThemePaletteProvider.overrideWithValue(savedPalette),
      ],
      child: const AppRoutine(),
    ),
  );
}

class AppRoutine extends ConsumerWidget {
  const AppRoutine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPalette = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Alarmes & Rotinas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(currentPalette),
      home: const HomeScreen(),
    );
  }
}

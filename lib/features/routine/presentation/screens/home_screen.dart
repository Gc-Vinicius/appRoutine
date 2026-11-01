import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/routine_provider.dart';
import '../../domain/routine_model.dart';
import '../widgets/routine_card.dart';
import '../widgets/live_clock_widget.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/home_metrics_dashboard.dart';
import '../widgets/today_timeline_list.dart';
import '../widgets/floating_nav_dock.dart';
import 'create_routine_screen.dart';
import 'diagnostic_screen.dart';
import 'sleep_calculator_screen.dart';
import 'theme_selector_screen.dart';
import 'timer_stopwatch_screen.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  int _currentNavIndex = 0;
  Timer? _foregroundAlarmTimer;
  int? _lastFiredMinuteKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final perms = await PermissionService().checkAllPermissions();
      if (!perms.hasNotification) {
        await PermissionService().requestNotificationPermission();
      }
      final deleted = await ref.read(routineListProvider.notifier).cleanExpiredOneShotRoutines();
      if (deleted.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleted.length == 1
                  ? 'Lembrete de visualização única "${deleted.first.title}" foi removido.'
                  : '${deleted.length} lembretes de visualização única foram removidos.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      ref.invalidate(permissionsProvider);
    });
    _startForegroundAlarmWatcher();
  }

  void _startForegroundAlarmWatcher() {
    _foregroundAlarmTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkForegroundAlarms();
    });
  }

  void _checkForegroundAlarms() {
    if (NotificationService.isAlarmScreenOpen) return;

    final now = DateTime.now();
    final minuteKey = now.year * 100000000 + now.month * 1000000 + now.day * 10000 + now.hour * 100 + now.minute;
    if (_lastFiredMinuteKey == minuteKey) return;

    final routines = ref.read(routineListProvider);
    for (final routine in routines) {
      if (!routine.isActive || routine.isCurrentlySkipped) continue;
      if (!routine.isAlarm && !routine.isOneShot) continue;

      bool shouldRing = false;
      if (routine.type == RoutineType.punctual) {
        final pDate = routine.punctualDate ?? DateTime(now.year, now.month, now.day);
        if (pDate.year == now.year &&
            pDate.month == now.month &&
            pDate.day == now.day &&
            routine.hour == now.hour &&
            routine.minute == now.minute) {
          shouldRing = true;
        }
      } else if (routine.type == RoutineType.recurring) {
        if (routine.weekdays.contains(now.weekday) &&
            routine.hour == now.hour &&
            routine.minute == now.minute) {
          shouldRing = true;
        }
      } else if (routine.type == RoutineType.periodic) {
        final interval = routine.intervalMinutes ?? 120;
        final startH = routine.windowStartHour ?? 8;
        final endH = routine.windowEndHour ?? 20;
        final stepHours = (interval ~/ 60).clamp(1, 24);
        if (now.hour >= startH &&
            now.hour <= endH &&
            (now.hour - startH) % stepHours == 0 &&
            routine.minute == now.minute) {
          shouldRing = true;
        }
      }

      if (shouldRing) {
        _lastFiredMinuteKey = minuteKey;
        if (routine.isAlarm) {
          NotificationService().openAlarmScreenForId(
            routine.id,
            payload: routine.title,
            explicitRoutine: routine,
          );
        } else if (routine.isOneShot) {
          NotificationService().showNotification(
            id: routine.id ?? 9999,
            title: routine.title,
            body: routine.body,
            isAlarm: false,
          );
          ref.read(routineListProvider.notifier).deleteRoutine(routine.id!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lembrete de visualização única "${routine.title}" foi concluído e removido.'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
        break;
      }
    }
  }

  @override
  void dispose() {
    _foregroundAlarmTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(permissionsProvider);
      ref.read(routineListProvider.notifier).cleanExpiredOneShotRoutines();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final allRoutines = ref.watch(routineListProvider);
    final filteredRoutines = ref.watch(filteredRoutinesProvider);
    final activeFilter = ref.watch(routineFilterProvider);

    return Scaffold(
      backgroundColor: palette.background,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentNavIndex,
            children: [
              // Aba 0: Nova Home Page (Dashboard Proativo)
              _buildHomeDashboard(palette, allRoutines),
              // Aba 1: Lista Completa de Rotinas (com relógio e filtros)
              _buildRoutinesTab(palette, filteredRoutines, activeFilter),
              // Aba 2: Timer & Cronômetro
              const TimerStopwatchScreen(),
              // Aba 3: Calculadora de Sono
              const SleepCalculatorScreen(),
              // Aba 4: Seletor de Temas
              const ThemeSelectorScreen(isEmbedded: true),
              // Aba 5: Ajustes & Diagnóstico
              const DiagnosticScreen(isEmbedded: true),
            ],
          ),

          // Dock de Navegação Flutuante
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavDock(
              currentIndex: _currentNavIndex,
              onIndexChanged: (index) => setState(() => _currentNavIndex = index),
              onAddPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRoutineScreen()),
                );
              },
              palette: palette,
            ),
          ),
        ],
      ),
    );
  }

  /// Dashboard Proativo da Nova Home Page
  Widget _buildHomeDashboard(AppPaletteData palette, List<RoutineModel> allRoutines) {
    final now = DateTime.now();
    final todayRoutines = _getTodayRoutines(allRoutines);
    final nextRoutine = _getNextRoutine(allRoutines);

    final checkinNotifier = ref.watch(habitCheckinProvider.notifier);
    final completedCount = todayRoutines.where((r) => checkinNotifier.isCompletedToday(r.id ?? 0)).length;
    final totalCount = todayRoutines.length;

    final profile = ref.watch(userProfileProvider).value;
    final rawName = profile?.nome;
    final userName = (rawName != null && rawName.isNotEmpty) ? rawName : 'Vinicius';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'V';

    final streak = _calculateOverallStreak(ref, allRoutines);
    final recordStreak = (streak > 18) ? streak : 18;

    final permAsync = ref.watch(permissionsProvider);
    final hasWarning = permAsync.value != null &&
        (!permAsync.value!.hasNotification || !permAsync.value!.hasExactAlarm);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          // 1. Header Contextual
          _buildHeader(
            palette: palette,
            userName: userName,
            userInitial: userInitial,
            dateFormatted: _formatCurrentDate(now),
            completedToday: completedCount,
            totalToday: totalCount,
            streakDays: streak,
            hasPermissionWarning: hasWarning,
          ),

          // Banner de Alerta de Permissões (se necessário)
          if (hasWarning)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alarm_off, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Permissões de alarme pendentes. Toque no sino para ativar.',
                      style: TextStyle(fontSize: 11, color: palette.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

          // 2. Hero Card Dinâmico ("A Seguir")
          HomeHeroCard(
            routine: nextRoutine,
            palette: palette,
          ),

          // 3. Micro-Dashboard de Métricas
          HomeMetricsDashboard(
            palette: palette,
            completedToday: completedCount,
            totalToday: totalCount,
            currentStreak: streak,
            recordStreak: recordStreak,
          ),

          // 4. Linha do Tempo ("Rotinas de Hoje")
          TodayTimelineList(
            todayRoutines: todayRoutines,
            nextRoutine: nextRoutine,
            palette: palette,
          ),
        ],
      ),
    );
  }

  /// Header Contextual com Saudação, Notificações e Avatar com Ofensiva
  Widget _buildHeader({
    required AppPaletteData palette,
    required String userName,
    required String userInitial,
    required String dateFormatted,
    required int completedToday,
    required int totalToday,
    required int streakDays,
    required bool hasPermissionWarning,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saudação e Resumo do Dia
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $userName',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateFormatted • $completedToday/$totalToday rotinas feitas',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Botão de Notificações
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border.withValues(alpha: 0.6)),
                ),
                child: IconButton(
                  icon: Icon(Icons.notifications_outlined, color: palette.textMuted, size: 20),
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _currentNavIndex = 5), // Ajustes/Diagnóstico
                ),
              ),
              if (hasPermissionWarning)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),

          // Avatar com Chip de Ofensiva (Streak)
          GestureKey(
            onTap: () => setState(() => _currentNavIndex = 4), // Temas
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userInitial,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: palette.onPrimary,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${streakDays}d',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.local_fire_department_rounded, size: 10, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Lista de Rotinas para Hoje
  List<RoutineModel> _getTodayRoutines(List<RoutineModel> allRoutines) {
    final now = DateTime.now();
    final todayWeekday = now.weekday;

    final list = allRoutines.where((r) {
      if (!r.isActive) return false;
      if (r.type == RoutineType.punctual) {
        final pDate = r.punctualDate ?? DateTime(now.year, now.month, now.day);
        return pDate.year == now.year && pDate.month == now.month && pDate.day == now.day;
      } else if (r.type == RoutineType.recurring) {
        return r.weekdays.contains(todayWeekday);
      } else if (r.type == RoutineType.periodic) {
        return true;
      }
      return false;
    }).toList();

    list.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return list;
  }

  /// Encontra a Próxima Rotina Ativa
  RoutineModel? _getNextRoutine(List<RoutineModel> allRoutines) {
    final now = DateTime.now();
    RoutineModel? closest;
    DateTime? closestTime;

    for (final r in allRoutines) {
      if (!r.isActive || r.isCurrentlySkipped) continue;
      final next = r.nextOccurrence;
      if (next != null && next.isAfter(now)) {
        if (closestTime == null || next.isBefore(closestTime)) {
          closestTime = next;
          closest = r;
        }
      }
    }

    if (closest == null) {
      final active = allRoutines.where((r) => r.isActive).toList();
      if (active.isNotEmpty) {
        active.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
        closest = active.first;
      }
    }

    return closest;
  }

  /// Cálculo da Maior Ofensiva
  int _calculateOverallStreak(WidgetRef ref, List<RoutineModel> allRoutines) {
    final notifier = ref.watch(habitCheckinProvider.notifier);
    int maxStreak = 0;
    for (final r in allRoutines) {
      if (r.id != null) {
        final summary = notifier.getSummary(r.id!);
        if (summary.currentStreak > maxStreak) {
          maxStreak = summary.currentStreak;
        }
      }
    }
    return maxStreak > 0 ? maxStreak : 12;
  }

  /// Formatação de Data em Português
  String _formatCurrentDate(DateTime now) {
    const weekdays = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo'
    ];
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '$weekday, ${now.day} de $month';
  }

  /// Aba Completa de Rotinas (Filtros + Lista Antiga)
  Widget _buildRoutinesTab(
    AppPaletteData palette,
    List<dynamic> routines,
    String activeFilter,
  ) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const LiveClockWidget(),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterTab(palette, 'all', 'Todos', activeFilter),
                _buildFilterTab(palette, 'recurring', 'Recorrentes', activeFilter),
                _buildFilterTab(palette, 'periodic', 'Periódicos', activeFilter),
                _buildFilterTab(palette, 'punctual', 'Pontuais', activeFilter),
              ],
            ),
          ),

          Expanded(
            child: routines.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum alarme encontrado nesta categoria.',
                      style: TextStyle(color: palette.textMuted, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: routines.length,
                    padding: const EdgeInsets.only(bottom: 96),
                    itemBuilder: (context, index) {
                      return RoutineCard(routine: routines[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    AppPaletteData palette,
    String filterKey,
    String label,
    String activeKey,
  ) {
    final isSelected = activeKey == filterKey;
    return GestureDetector(
      onTap: () {
        ref.read(routineFilterProvider.notifier).state = filterKey;
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? palette.primary : palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: palette.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? palette.onPrimary : palette.textMuted,
          ),
        ),
      ),
    );
  }
}

class GestureKey extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const GestureKey({super.key, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

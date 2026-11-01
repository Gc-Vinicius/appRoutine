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
import 'calendar_screen.dart';
import 'auth_screen.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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

    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider).value;
    final rawName = profile?.nome;
    final userName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (user?.userMetadata?['name'] as String? ?? user?.email?.split('@').first ?? 'Vinicius');
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'V';
    final photoUrl = profile?.fotoUrl ?? user?.userMetadata?['avatar_url'] as String?;
    final userEmail = user?.email;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.background,
      drawer: _buildAppDrawer(
        palette: palette,
        userName: userName,
        photoUrl: photoUrl,
        userInitial: userInitial,
        userEmail: userEmail,
      ),
      body: Stack(
        children: [
          FadeIndexedStack(
            index: _currentNavIndex,
            children: [
              // Aba 0: Home (Dashboard Proativo)
              _buildHomeDashboard(palette, allRoutines, photoUrl),
              // Aba 1: Lista Completa de Rotinas (com relógio e filtros)
              _buildRoutinesTab(palette, filteredRoutines, activeFilter),
              // Aba 2: Calendário (Roadmap • Em Breve)
              CalendarScreen(
                onNavigateToHome: () => setState(() => _currentNavIndex = 0),
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              // Aba 3: Ajustes & Configurações
              DiagnosticScreen(
                isEmbedded: true,
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
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
  Widget _buildHomeDashboard(AppPaletteData palette, List<RoutineModel> allRoutines, String? photoUrl) {
    final now = DateTime.now();
    final todayRoutines = _getTodayRoutines(allRoutines);
    final nextRoutine = _getNextRoutine(allRoutines);

    final checkinNotifier = ref.watch(habitCheckinProvider.notifier);
    final completedCount = todayRoutines.where((r) => checkinNotifier.isCompletedToday(r.id ?? 0)).length;
    final totalCount = todayRoutines.length;

    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider).value;
    final rawName = profile?.nome;
    final userName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (user?.userMetadata?['name'] as String? ?? user?.email?.split('@').first ?? 'Vinicius');
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'V';

    final streak = checkinNotifier.getOverallCurrentStreak();
    final recordStreak = checkinNotifier.getOverallRecordStreak();

    final focusSeconds = ref.watch(focusTimeTodayProvider);
    final focusFormatted = _formatFocusDuration(focusSeconds);
    final focusMeta = focusSeconds == 0 ? 'Meta: 2h/dia' : '${((focusSeconds / 7200) * 100).round()}% da meta';

    final permAsync = ref.watch(permissionsProvider);
    final hasWarning = permAsync.value != null &&
        (!permAsync.value!.hasNotification || !permAsync.value!.hasExactAlarm);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          // 1. Header Contextual (com botão Hambúrguer e Foto real)
          _buildHeader(
            palette: palette,
            userName: userName,
            userInitial: userInitial,
            photoUrl: photoUrl,
            dateFormatted: _formatCurrentDate(now),
            completedToday: completedCount,
            totalToday: totalCount,
            streakDays: streak,
            hasPermissionWarning: hasWarning,
            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
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
            focusTimeFormatted: focusFormatted,
            focusMetaFormatted: focusMeta,
            onTapFocus: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TimerStopwatchScreen()),
              );
            },
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

  /// Header Contextual com Botão Hambúrguer, Saudação, Notificações e Avatar com Foto Real
  Widget _buildHeader({
    required AppPaletteData palette,
    required String userName,
    required String userInitial,
    required String? photoUrl,
    required String dateFormatted,
    required int completedToday,
    required int totalToday,
    required int streakDays,
    required bool hasPermissionWarning,
    required VoidCallback onOpenDrawer,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Botão Hambúrguer
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: palette.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border.withValues(alpha: 0.6)),
            ),
            child: IconButton(
              icon: Icon(Icons.menu_rounded, color: palette.textPrimary, size: 22),
              padding: EdgeInsets.zero,
              tooltip: 'Menu',
              onPressed: onOpenDrawer,
            ),
          ),
          const SizedBox(width: 12),

          // Saudação e Resumo do Dia
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $userName',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateFormatted • $completedToday/$totalToday feitas',
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  onPressed: () => setState(() => _currentNavIndex = 3), // Ajustes/Diagnóstico
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeSelectorScreen()),
              );
            },
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant,
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.border.withValues(alpha: 0.6)),
                  ),
                  child: ClipOval(
                    child: (photoUrl != null && photoUrl.isNotEmpty)
                        ? Image.network(
                            photoUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                userInitial,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: palette.primary,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              userInitial,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: palette.primary,
                              ),
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


  /// Formatação de Tempo de Foco
  String _formatFocusDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0m';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } else {
      return '${minutes}m';
    }
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
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
                    icon: Icon(Icons.menu_rounded, color: palette.textPrimary, size: 22),
                    padding: EdgeInsets.zero,
                    tooltip: 'Menu',
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rotinas & Alarmes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
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

// ==========================================
  // MENU HAMBÚRGUER (DRAWER LATERAL AMOLED)
  // ==========================================

  Widget _buildAppDrawer({
    required AppPaletteData palette,
    required String userName,
    required String? photoUrl,
    required String userInitial,
    required String? userEmail,
  }) {
    return Drawer(
      backgroundColor: palette.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header do Drawer com Foto real e dados do usuário
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.border)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: palette.surfaceVariant,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(
                            userInitial,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: palette.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail ?? 'Modo Local Offline',
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Itens de Menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                children: [
                  // Seção: Ferramentas (movidas do menu inferior)
                  _buildDrawerSectionTitle(palette, 'FERRAMENTAS'),
                  _buildDrawerItem(
                    palette: palette,
                    icon: Icons.timer_rounded,
                    iconColor: palette.primary,
                    title: 'Timer & Cronômetro',
                    subtitle: 'Foco Pomodoro e voltas',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TimerStopwatchScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    palette: palette,
                    icon: Icons.nightlight_round,
                    iconColor: const Color(0xFF818CF8),
                    title: 'Calculadora de Sono',
                    subtitle: 'Ciclos REM de 90 min',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SleepCalculatorScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Seção: Navegação Principal
                  _buildDrawerSectionTitle(palette, 'NAVEGAÇÃO'),
                  _buildDrawerItem(
                    palette: palette,
                    icon: Icons.home_rounded,
                    title: 'Início',
                    isSelected: _currentNavIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentNavIndex = 0);
                    },
                  ),
                  _buildDrawerItem(
                    palette: palette,
                    icon: Icons.alarm_rounded,
                    title: 'Rotinas & Alarmes',
                    isSelected: _currentNavIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentNavIndex = 1);
                    },
                  ),
                  _buildDrawerItem(
                    palette: palette,
                    icon: Icons.calendar_month_rounded,
                    title: 'Calendário (Roadmap)',
                    isSelected: _currentNavIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentNavIndex = 2);
                    },
                  ),
                  _buildDrawerItem(
                    palette: palette,
                    icon: Icons.settings_rounded,
                    title: 'Configurações & Diagnóstico',
                    isSelected: _currentNavIndex == 3,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentNavIndex = 3);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Seção: Preferências
                  _buildDrawerSectionTitle(palette, 'PREFERÊNCIAS'),
                  _buildDrawerItem(
                    palette: palette,
                    icon: Icons.palette_outlined,
                    title: 'Aparência & Temas',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ThemeSelectorScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    palette: palette,
                    icon: Icons.cloud_outlined,
                    title: 'Backup & Conta Nuvem',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Rodapé do Drawer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 14, color: palette.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'appRoutine • AMOLED Edition',
                      style: TextStyle(
                        fontSize: 11,
                        color: palette.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSectionTitle(AppPaletteData palette, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: palette.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required AppPaletteData palette,
    required IconData icon,
    Color? iconColor,
    required String title,
    String? subtitle,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? palette.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: Icon(
          icon,
          color: isSelected ? palette.primary : (iconColor ?? palette.textPrimary),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? palette.primary : palette.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 10.5, color: palette.textMuted),
              )
            : null,
        onTap: onTap,
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

/// Pilha Indexada com Transição Animada Fluida (Fade + Slide Suave)


class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 240),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: IndexedStack(
          index: widget.index,
          children: widget.children,
        ),
      ),
    );
  }
}

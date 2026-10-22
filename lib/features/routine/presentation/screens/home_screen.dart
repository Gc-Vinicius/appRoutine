import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/routine_provider.dart';
import '../widgets/routine_card.dart';
import '../widgets/live_clock_widget.dart';
import 'create_routine_screen.dart';
import 'diagnostic_screen.dart';
import 'sleep_calculator_screen.dart';
import 'theme_selector_screen.dart';
import 'timer_stopwatch_screen.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final perms = await PermissionService().checkAllPermissions();
      if (!perms.hasNotification) {
        await PermissionService().requestNotificationPermission();
      }
      ref.invalidate(permissionsProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(permissionsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final routines = ref.watch(filteredRoutinesProvider);
    final activeFilter = ref.watch(routineFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.surface,
                border: Border.all(color: palette.border, width: 1.2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icon/app_logo_512.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.alarm, size: 18, color: palette.primary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _currentNavIndex == 0
                  ? 'Rotinas & Hábitos'
                  : (_currentNavIndex == 1 ? 'Ferramentas de Tempo' : 'Ciclos de Sono (REM)'),
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.palette_outlined, color: palette.primary),
            tooltip: 'Temas & Aparência',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeSelectorScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: palette.primary),
            tooltip: 'Configurações',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiagnosticScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildRoutinesTab(palette, routines, activeFilter),
          const TimerStopwatchScreen(),
          const SleepCalculatorScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        backgroundColor: palette.surface,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.textMuted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10.5),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Rotinas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_bottom),
            label: 'Timer / Cronômetro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.nightlight_round),
            label: 'Ciclos de Sono',
          ),
        ],
      ),
      floatingActionButton: _currentNavIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRoutineScreen()),
                );
              },
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  Widget _buildRoutinesTab(
    AppPaletteData palette,
    List<dynamic> routines,
    String activeFilter,
  ) {
    final permAsync = ref.watch(permissionsProvider);
    final needsAttention = permAsync.value != null &&
        (!permAsync.value!.hasNotification || !permAsync.value!.hasExactAlarm);

    return Column(
      children: [
        if (needsAttention)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.alarm_off, color: Colors.amber, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permissões de Alarme Necessárias',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ative para garantir que os alarmes toquem no horário exato.',
                        style: TextStyle(fontSize: 10.5, color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DiagnosticScreen()),
                    ).then((_) => ref.invalidate(permissionsProvider));
                  },
                  child: Text(
                    'Ativar',
                    style: TextStyle(
                      color: palette.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Widget de Relógio Ao Vivo (Analógico + Digital)
        const LiveClockWidget(),

        // Filtros Rápidos (Tabs)
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

        // Lista de Alarmes
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
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    return RoutineCard(routine: routines[index]);
                  },
                ),
        ),
      ],
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
            color: isSelected
                ? (palette.id == 'carmim_pergaminho' ? palette.textPrimary : Colors.white)
                : palette.textMuted,
          ),
        ),
      ),
    );
  }
}

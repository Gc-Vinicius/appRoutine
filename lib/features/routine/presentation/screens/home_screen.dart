import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/routine_provider.dart';
import '../widgets/routine_card.dart';
import '../widgets/live_clock_widget.dart';
import 'create_routine_screen.dart';
import 'diagnostic_screen.dart';
import 'theme_selector_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              'Rotinas & Hábitos',
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
      body: Column(
        children: [
          // Widget de Relógio Ao Vivo (Analógico + Digital) solicitado na Imagem 2
          const LiveClockWidget(),

          // Filtros Rápidos (Tabs)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterTab(ref, palette, 'all', 'Todos', activeFilter),
                _buildFilterTab(ref, palette, 'recurring', 'Recorrentes', activeFilter),
                _buildFilterTab(ref, palette, 'periodic', 'Periódicos', activeFilter),
                _buildFilterTab(ref, palette, 'punctual', 'Pontuais', activeFilter),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateRoutineScreen()),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildFilterTab(
    WidgetRef ref,
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

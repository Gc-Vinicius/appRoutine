import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/routine_provider.dart';
import '../widgets/routine_card.dart';
import 'create_routine_screen.dart';
import 'diagnostic_screen.dart';
import 'theme_selector_screen.dart';
import '../../../../core/theme/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themeProvider.notifier).currentPaletteData;
    final routines = ref.watch(filteredRoutinesProvider);
    final activeFilter = ref.watch(routineFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alarmes & Hábitos',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Sincronização Ativa Haylou Solar Neo',
              style: TextStyle(color: palette.textMuted, fontSize: 11),
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
            icon: Icon(Icons.shield_outlined, color: palette.primary),
            tooltip: 'Diagnóstico & Bateria',
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
          // Badge Haylou Conectado + Banner Doze Mode
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.watch_outlined, size: 14, color: palette.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Haylou Solar Neo Conectado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: palette.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Banner Otimização Doze Mode
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, color: palette.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alarmes com Exatidão Máxima (Doze Mode)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                            ),
                            Text(
                              'Isenção de bateria ativa • Disparo no segundo exato',
                              style: TextStyle(fontSize: 10.5, color: palette.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filtros Rápidos (Tabs)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterTab(ref, palette, 'all', 'Todos (${ref.watch(routineListProvider).length})', activeFilter),
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
    dynamic palette,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? palette.primary : palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: palette.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (palette.isDark ? palette.textPrimary : Colors.white)
                : palette.textMuted,
          ),
        ),
      ),
    );
  }
}

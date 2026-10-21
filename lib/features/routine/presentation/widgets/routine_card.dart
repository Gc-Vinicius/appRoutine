import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/routine_model.dart';
import '../providers/routine_provider.dart';
import '../../../../core/theme/theme_provider.dart';

class RoutineCard extends ConsumerWidget {
  final RoutineModel routine;

  const RoutineCard({super.key, required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themeProvider.notifier).currentPaletteData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha Superior: Badge de Tipo + Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    routine.typeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: palette.badgeText,
                    ),
                  ),
                ),
                Switch(
                  value: routine.isActive,
                  onChanged: (val) {
                    ref.read(routineListProvider.notifier).toggleActive(routine.id!, val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Horário em Destaque + Título
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  routine.formattedTime,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: routine.isActive ? palette.textPrimary : palette.textMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    routine.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Chip de Espelhamento no Smartwatch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: palette.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.border, width: 0.8),
              ),
              child: Row(
                children: [
                  Icon(Icons.watch_outlined, size: 16, color: palette.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No relógio: "${routine.body}"',
                      style: TextStyle(fontSize: 11, color: palette.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Subtítulo e Dias da Semana / Barra de Progresso
            if (routine.type == RoutineType.recurring) ...[
              _buildWeekdaysRow(palette),
            ] else ...[
              Text(
                routine.recurrenceSubtitle,
                style: TextStyle(fontSize: 11, color: palette.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdaysRow(dynamic palette) {
    const days = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    return Row(
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isSelected = routine.weekdays.contains(dayNum);
        return Container(
          margin: const EdgeInsets.only(right: 6),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? palette.primary : palette.surfaceVariant,
          ),
          alignment: Alignment.center,
          child: Text(
            days[index],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? (palette.isDark ? palette.textPrimary : Colors.white)
                  : palette.textMuted,
            ),
          ),
        );
      }),
    );
  }
}

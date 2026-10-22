import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/routine_model.dart';
import '../providers/routine_provider.dart';
import '../screens/create_routine_screen.dart';
import '../../../../core/theme/theme_provider.dart';

class RoutineCard extends ConsumerWidget {
  final RoutineModel routine;

  const RoutineCard({super.key, required this.routine});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final palette = ref.read(currentPaletteProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Rotina?'),
        content: Text('Tem certeza que deseja excluir "${routine.title}"? O alarme associado será cancelado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: palette.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(routineListProvider.notifier).deleteRoutine(routine.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rotina "${routine.title}" excluída.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(currentPaletteProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateRoutineScreen(routineToEdit: routine),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha 1: Título da Rotina (Esquerda) + Ações: Excluir, Editar, Switch (Direita)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      routine.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: routine.isActive ? palette.textPrimary : palette.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botão Excluir Direto no Card (Feature da Imagem 2)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        tooltip: 'Excluir Rotina',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => _confirmDelete(context, ref),
                      ),
                      const SizedBox(width: 4),
                      // Botão Editar (Pencil)
                      IconButton(
                        icon: Icon(Icons.edit_outlined, size: 20, color: palette.textSecondary),
                        tooltip: 'Editar Rotina',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateRoutineScreen(routineToEdit: routine),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Switch Ativo/Inativo
                      Switch(
                        value: routine.isActive,
                        onChanged: (val) {
                          ref.read(routineListProvider.notifier).toggleActive(routine.id!, val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Linha 2: Horário em Destaque + Badge de Tipo (Recorrente/Pontual/Periódico) lado a lado
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
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
                ],
              ),
              const SizedBox(height: 10),

              // Linha 3: Chip de Espelhamento no Smartwatch
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

              // Linha 4: Subtítulo ou Dias da Semana
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
      ),
    );
  }

  Widget _buildWeekdaysRow(dynamic palette) {
    // 1=Seg, 2=Ter, 3=Qua, 4=Qui, 5=Sex, 6=Sáb, 7=Dom
    const days = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    return Row(
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isSelected = routine.weekdays.contains(dayNum);
        return Container(
          margin: const EdgeInsets.only(right: 6),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? palette.primary : palette.surfaceVariant,
            border: Border.all(
              color: isSelected ? palette.primary : palette.border,
              width: 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            days[index],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? (palette.id == 'carmim_pergaminho' ? palette.textPrimary : Colors.white)
                  : palette.textMuted,
            ),
          ),
        );
      }),
    );
  }
}

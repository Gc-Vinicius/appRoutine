import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/routine_model.dart';
import '../providers/routine_provider.dart';
import '../screens/create_routine_screen.dart';
import 'habit_history_sheet.dart';
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
    ref.watch(habitCheckinProvider);
    final isDoneToday = ref.read(habitCheckinProvider.notifier).isCompletedToday(routine.id ?? 0);
    final summary = ref.read(habitCheckinProvider.notifier).getSummary(routine.id ?? 0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Opção 2 solicitada: abrir modal detalhado de histórico ao tocar no card
          HabitHistorySheet.show(context, routine: routine);
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
                    child: Row(
                      children: [
                        Flexible(
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
                        if (summary.currentStreak > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orangeAccent, width: 0.7),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔥', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 2),
                                Text(
                                  '${summary.currentStreak}d',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botão Excluir Direto no Card
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
                          if (val && context.mounted) {
                            final info = routine.timeUntilNextFormatted;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Alarme "${routine.title}" ativado! $info.'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Linha 2: Horário de Disparo + Chip de Categoria
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${routine.hour.toString().padLeft(2, '0')}:${routine.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                      color: routine.isActive ? palette.primary : palette.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Badge: Alarme vs Lembrete
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: routine.isAlarm
                          ? Colors.deepOrange.withValues(alpha: 0.15)
                          : Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: routine.isAlarm
                            ? Colors.deepOrangeAccent.withValues(alpha: 0.4)
                            : Colors.blueAccent.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          routine.isAlarm ? Icons.alarm : Icons.watch_outlined,
                          size: 12,
                          color: routine.isAlarm ? Colors.deepOrangeAccent : Colors.lightBlueAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          routine.alertTypeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: routine.isAlarm ? Colors.deepOrangeAccent : Colors.lightBlueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Tag de Categoria com Emoji
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: routine.isActive
                          ? palette.primary.withValues(alpha: 0.15)
                          : palette.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: routine.isActive
                            ? palette.primary.withValues(alpha: 0.3)
                            : palette.border,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          routine.displayCategoryEmoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          routine.displayCategoryName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: routine.isActive ? palette.primary : palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Linha: Indicador de Tempo Restante + Ação Rápida de Check-in + Pular Próximo
              Row(
                children: [
                  Icon(
                    routine.isCurrentlySkipped ? Icons.pause_circle_outline : Icons.schedule,
                    size: 13,
                    color: routine.isCurrentlySkipped ? Colors.orangeAccent : palette.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    routine.timeUntilNextFormatted,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: routine.isCurrentlySkipped ? FontWeight.bold : FontWeight.w500,
                      color: routine.isCurrentlySkipped ? Colors.orangeAccent : palette.textMuted,
                    ),
                  ),
                  const Spacer(),

                  // AÇÃO RÁPIDA: Check-in de Hábito (Feito Hoje)
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final isDone = await ref
                          .read(habitCheckinProvider.notifier)
                          .toggleCheckinToday(routine.id ?? 0);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isDone
                                  ? 'Rotina "${routine.title}" marcada como feita hoje! 🎉'
                                  : 'Check-in desmarcado.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDoneToday
                            ? Colors.green.withValues(alpha: 0.18)
                            : palette.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDoneToday ? Colors.greenAccent : palette.border,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDoneToday ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                            size: 12,
                            color: isDoneToday ? Colors.greenAccent : palette.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDoneToday ? 'Feito hoje ✓' : 'Marcar feito',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDoneToday ? Colors.greenAccent : palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (routine.isActive) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        ref.read(routineListProvider.notifier).toggleSkipNext(routine.id!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: routine.isCurrentlySkipped
                              ? Colors.orange.withValues(alpha: 0.15)
                              : palette.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: routine.isCurrentlySkipped
                                ? Colors.orangeAccent
                                : palette.border,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          routine.isCurrentlySkipped ? 'Reativar alarme' : 'Pular próximo',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: routine.isCurrentlySkipped
                                ? Colors.orangeAccent
                                : palette.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
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

              // Linha 4: Subtítulo ou Dias da Semana + Dica de Histórico
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (routine.type == RoutineType.recurring)
                    _buildWeekdaysRow(palette)
                  else
                    Text(
                      routine.recurrenceSubtitle,
                      style: TextStyle(fontSize: 11, color: palette.textMuted),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 13, color: palette.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        'Histórico',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
              color: isSelected ? palette.onPrimary : palette.textMuted,
            ),
          ),
        );
      }),
    );
  }
}

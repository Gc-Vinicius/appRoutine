import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/routine_model.dart';
import '../providers/routine_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../screens/create_routine_screen.dart';

class HomeHeroCard extends ConsumerWidget {
  final RoutineModel? routine;
  final AppPaletteData palette;

  const HomeHeroCard({
    super.key,
    required this.routine,
    required this.palette,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (routine == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: palette.surfaceVariant,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          children: [
            Icon(Icons.alarm_add_rounded, color: palette.primary, size: 36),
            const SizedBox(height: 10),
            Text(
              'Nenhuma rotina agendada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crie um alarme ou lembrete para começar.',
              style: TextStyle(fontSize: 12, color: palette.textMuted),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateRoutineScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Criar Rotina'),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                foregroundColor: palette.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    final item = routine!;
    final isDoneToday = ref.watch(habitCheckinProvider.notifier).isCompletedToday(item.id ?? 0);
    final timeFormatted = item.formattedTime;
    final countdown = _getCountdownPill(item);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Barra de acento vertical à esquerda
          Positioned(
            left: 0,
            top: 4,
            bottom: 4,
            width: 4,
            child: Container(
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título da Rotina
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Linha de Horário + Tipo + Pill de Contagem Regressiva
                Row(
                  children: [
                    Text(
                      '$timeFormatted • ${item.alertTypeLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F243A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        countdown,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF38BDF8),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Botões de Ação Rápida
                Row(
                  children: [
                    // Botão Primário: Concluir Hoje
                    Expanded(
                      flex: 5,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (item.id != null) {
                            final done = await ref
                                .read(habitCheckinProvider.notifier)
                                .toggleCheckinToday(item.id!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    done
                                        ? 'Rotina "${item.title}" concluída por hoje!'
                                        : 'Check-in de "${item.title}" desmarcado.',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(
                          isDoneToday ? Icons.check_circle_rounded : Icons.check_rounded,
                          size: 16,
                          color: palette.onPrimary,
                        ),
                        label: Text(
                          isDoneToday ? 'Concluído' : 'Concluir Hoje',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: palette.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDoneToday ? const Color(0xFF10B981) : palette.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botão Secundário: Adiar 10m
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: () {
                          if (item.id != null) {
                            NotificationService().snoozeRoutine(
                              id: item.id!,
                              title: item.title,
                              body: item.body,
                              minutes: 10,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${item.title}" adiada por 10 minutos.'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: palette.surface,
                          side: BorderSide(color: palette.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Adiar 10m',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botão de Opções Rápidas: •••
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.border),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.more_horiz_rounded, color: palette.textMuted, size: 20),
                        padding: EdgeInsets.zero,
                        onPressed: () => _showHeroOptionsModal(context, ref, item),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCountdownPill(RoutineModel routine) {
    if (routine.isCurrentlySkipped) return 'PAUSADO';
    final next = routine.nextOccurrence;
    if (next == null) return 'AGENDADO';

    final diff = next.difference(DateTime.now());
    if (diff.isNegative) return 'AGORA';

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours == 0) {
      return 'EM ${minutes <= 1 ? "1" : minutes} MIN';
    } else if (hours < 24) {
      return 'EM ${hours}H ${minutes > 0 ? "$minutes M" : ""}';
    } else {
      return 'EM ${diff.inDays}D';
    }
  }

  void _showHeroOptionsModal(BuildContext context, WidgetRef ref, RoutineModel routine) {
    showModalBottomSheet(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: palette.textPrimary),
                  title: Text('Editar Rotina', style: TextStyle(color: palette.textPrimary)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateRoutineScreen(routineToEdit: routine),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    routine.isCurrentlySkipped ? Icons.play_arrow_outlined : Icons.skip_next_outlined,
                    color: palette.textPrimary,
                  ),
                  title: Text(
                    routine.isCurrentlySkipped ? 'Reativar Próximo Disparo' : 'Pular Próximo Disparo',
                    style: TextStyle(color: palette.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (routine.id != null) {
                      ref.read(routineListProvider.notifier).toggleSkipNext(routine.id!);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alarm_off_outlined, color: Colors.redAccent),
                  title: const Text('Desativar Rotina', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (routine.id != null) {
                      ref.read(routineListProvider.notifier).toggleActive(routine.id!, false);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

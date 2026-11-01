import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/routine_model.dart';
import '../providers/routine_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/create_routine_screen.dart';

class TodayTimelineList extends ConsumerWidget {
  final List<RoutineModel> todayRoutines;
  final RoutineModel? nextRoutine;
  final AppPaletteData palette;

  const TodayTimelineList({
    super.key,
    required this.todayRoutines,
    required this.nextRoutine,
    required this.palette,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rotinas de Hoje',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          if (todayRoutines.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: palette.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border.withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text(
                  'Nenhuma rotina para hoje.',
                  style: TextStyle(color: palette.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayRoutines.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final routine = todayRoutines[index];
                final isDone = ref
                    .watch(habitCheckinProvider.notifier)
                    .isCompletedToday(routine.id ?? 0);
                final isNext = nextRoutine?.id != null && nextRoutine!.id == routine.id;

                return _buildTimelineItem(context, ref, routine, isDone, isNext);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    WidgetRef ref,
    RoutineModel routine,
    bool isDone,
    bool isNext,
  ) {
    Color cardBg = palette.surfaceVariant;
    Border? border = Border.all(color: palette.border.withValues(alpha: 0.6));

    if (isNext && !isDone) {
      cardBg = palette.surface;
      border = Border.all(color: palette.primary, width: 1.2);
    } else if (isDone) {
      cardBg = palette.surfaceVariant.withValues(alpha: 0.5);
    }

    return InkWell(
      onTap: () {
        if (routine.id != null) {
          ref.read(habitCheckinProvider.notifier).toggleCheckinToday(routine.id!);
        }
      },
      onLongPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateRoutineScreen(routineToEdit: routine),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: border,
        ),
        child: Row(
          children: [
            // Indicador Esquerdo
            _buildStatusIndicator(isDone, isNext),
            const SizedBox(width: 12),

            // Título e Subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${routine.formattedTime} • ${routine.title}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                      color: isDone
                          ? palette.textMuted
                          : (isNext ? palette.textPrimary : palette.textSecondary),
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: palette.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _getSubtext(routine, isDone, isNext),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: palette.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Badge Direita
            _buildBadge(isDone, isNext),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isDone, bool isNext) {
    if (isDone) {
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFF064E3B),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 14,
          color: Color(0xFF34D399),
        ),
      );
    } else if (isNext) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: palette.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: palette.primary, width: 1.5),
        ),
        child: Icon(
          Icons.play_arrow_rounded,
          size: 15,
          color: palette.primary,
        ),
      );
    } else {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: palette.border.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: palette.textMuted,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
  }

  String _getSubtext(RoutineModel routine, bool isDone, bool isNext) {
    if (isDone) {
      return 'Concluído hoje';
    } else if (isNext) {
      return routine.timeUntilNextFormatted;
    } else {
      return routine.alertTypeLabel;
    }
  }

  Widget _buildBadge(bool isDone, bool isNext) {
    if (isDone) {
      return const Text(
        'Feito',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF10B981),
        ),
      );
    } else if (isNext) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: palette.primary.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'A Seguir',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: palette.primary,
          ),
        ),
      );
    } else {
      return Text(
        'Agendado',
        style: TextStyle(
          fontSize: 10.5,
          color: palette.textMuted,
        ),
      );
    }
  }
}

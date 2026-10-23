import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/routine_provider.dart';
import '../screens/create_routine_screen.dart';
import '../../domain/routine_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';

/// Modal BottomSheet interativo que exibe o Histórico de Hábitos & Check-ins da rotina
class HabitHistorySheet extends ConsumerWidget {
  final RoutineModel routine;

  const HabitHistorySheet({
    super.key,
    required this.routine,
  });

  static Future<void> show(BuildContext context, {required RoutineModel routine}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitHistorySheet(routine: routine),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(currentPaletteProvider);
    // Observa mudanças nos check-ins em tempo real
    ref.watch(habitCheckinProvider);
    final notifier = ref.read(habitCheckinProvider.notifier);

    final summary = notifier.getSummary(routine.id ?? 0);
    final isDoneToday = summary.isCompletedToday;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: palette.border, width: 1.2),
          left: BorderSide(color: palette.border, width: 1.2),
          right: BorderSide(color: palette.border, width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Puxador visual (Drag handle)
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Cabeçalho: Categoria, Título e Horário
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: palette.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      routine.displayCategoryEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${routine.hour.toString().padLeft(2, '0')}:${routine.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: palette.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• ${routine.displayCategoryName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: palette.textMuted),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Conteúdo Rolável
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Resumo de Desempenho e Consistência Semanal
                    _buildConsistencyCard(palette, summary),
                    const SizedBox(height: 18),

                    // Card 2: Grade dos Últimos 7 Dias
                    Text(
                      'ÚLTIMOS 7 DIAS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildWeeklyDaysRow(palette, summary),
                    const SizedBox(height: 24),

                    // Botão Principal: Check-in Hoje
                    _buildCheckinActionButton(context, ref, palette, isDoneToday),
                    const SizedBox(height: 24),

                    // Histórico Recente de Conclusões
                    Text(
                      'HISTÓRICO RECENTE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.bold,
                        color: palette.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRecentHistoryList(ref, palette),
                    const SizedBox(height: 16),

                    // Ação Secundária: Editar Rotina
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateRoutineScreen(routineToEdit: routine),
                            ),
                          );
                        },
                        icon: Icon(Icons.edit_outlined, size: 16, color: palette.textSecondary),
                        label: Text(
                          'Editar parâmetros da rotina',
                          style: TextStyle(fontSize: 12, color: palette.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsistencyCard(AppPaletteData palette, dynamic summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          // Indicador Circular de Progresso com Porcentagem
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: CircularProgressIndicator(
                  value: summary.complianceRate,
                  strokeWidth: 6,
                  backgroundColor: palette.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    summary.complianceRate >= 0.7 ? Colors.greenAccent : palette.primary,
                  ),
                ),
              ),
              Text(
                summary.formattedPercentage,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Taxa de Cumprimento Semanal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Você concluiu ${summary.formattedRatio}.',
                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: summary.currentStreak > 0
                        ? Colors.orange.withValues(alpha: 0.15)
                        : palette.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: summary.currentStreak > 0 ? Colors.orangeAccent : palette.border,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        summary.currentStreak > 0 ? '🔥 ' : '⏳ ',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        summary.currentStreak > 0
                            ? '${summary.currentStreak} dias seguidos de consistência!'
                            : 'Nenhuma sequência ativa no momento',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: summary.currentStreak > 0 ? Colors.orangeAccent : palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyDaysRow(AppPaletteData palette, dynamic summary) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = summary.last7Days as List<DateTime>;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) {
        final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
        final dayKey = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final isCompleted = summary.completionMap[dayKey] == true;

        final weekdayLetter = _getWeekdayShort(day.weekday);

        return Column(
          children: [
            Text(
              weekdayLetter,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: isToday ? palette.primary : palette.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 38,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withValues(alpha: 0.2)
                    : (isToday ? palette.surfaceVariant : palette.surface),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCompleted
                      ? Colors.greenAccent
                      : (isToday ? palette.primary : palette.border),
                  width: isToday || isCompleted ? 1.5 : 0.8,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? palette.primary : palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    isCompleted ? Icons.check_circle_rounded : (isToday ? Icons.radio_button_unchecked : Icons.remove),
                    size: 14,
                    color: isCompleted
                        ? Colors.greenAccent
                        : (isToday ? palette.primary : palette.textMuted.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCheckinActionButton(
    BuildContext context,
    WidgetRef ref,
    AppPaletteData palette,
    bool isDoneToday,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () async {
          HapticFeedback.lightImpact();
          final isDone = await ref
              .read(habitCheckinProvider.notifier)
              .toggleCheckinToday(routine.id ?? 0);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isDone
                      ? 'Parabéns! Rotina "${routine.title}" marcada como feita hoje! 🎉'
                      : 'Check-in de hoje desmarcado.',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isDoneToday ? Colors.green.shade800 : palette.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(
          isDoneToday ? Icons.check_circle : Icons.done_all_rounded,
          size: 20,
        ),
        label: Text(
          isDoneToday ? 'Hábito Concluído Hoje ✓ (Toque para desfazer)' : 'Marcar como Concluído Hoje ✓',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildRecentHistoryList(WidgetRef ref, AppPaletteData palette) {
    final checkins = ref
        .watch(habitCheckinProvider)
        .where((c) => c.routineId == routine.id && c.isCompleted)
        .toList();

    checkins.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    if (checkins.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: palette.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          children: [
            Icon(Icons.event_available_outlined, size: 28, color: palette.textMuted),
            const SizedBox(height: 8),
            Text(
              'Nenhum check-in registrado ainda.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              'Conclua a rotina hoje para inaugurar sua sequência de hábitos!',
              style: TextStyle(fontSize: 11, color: palette.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final topCheckins = checkins.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topCheckins.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: palette.border),
        itemBuilder: (ctx, idx) {
          final item = topCheckins[idx];
          final dateStr = DateFormat('dd/MM/yyyy').format(item.date);
          final timeStr = DateFormat('HH:mm').format(item.completedAt);
          final isToday = item.isToday;

          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
            title: Text(
              isToday ? 'Hoje' : dateStr,
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
                color: isToday ? palette.primary : palette.textPrimary,
              ),
            ),
            trailing: Text(
              'Concluído às $timeStr',
              style: TextStyle(fontSize: 11, color: palette.textSecondary),
            ),
          );
        },
      ),
    );
  }

  String _getWeekdayShort(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'SEG';
      case DateTime.tuesday:
        return 'TER';
      case DateTime.wednesday:
        return 'QUA';
      case DateTime.thursday:
        return 'QUI';
      case DateTime.friday:
        return 'SEX';
      case DateTime.saturday:
        return 'SÁB';
      case DateTime.sunday:
        return 'DOM';
      default:
        return '';
    }
  }
}

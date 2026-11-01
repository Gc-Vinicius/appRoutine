import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';

class CalendarScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onMenuPressed;

  const CalendarScreen({
    super.key,
    this.onNavigateToHome,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(currentPaletteProvider);
    final now = DateTime.now();

    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    final monthName = months[now.month - 1];

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // Header
            Row(
              children: [
                if (onMenuPressed != null) ...[
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
                      onPressed: onMenuPressed,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calendário',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$monthName ${now.year}',
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 13, color: palette.primary),
                      const SizedBox(width: 5),
                      Text(
                        'EM BREVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: palette.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card Ilustrativo de Visualização de Calendário
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  // Cabeçalho dos dias da semana
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _WeekHeader('S'),
                      _WeekHeader('T'),
                      _WeekHeader('Q'),
                      _WeekHeader('Q'),
                      _WeekHeader('S'),
                      _WeekHeader('S'),
                      _WeekHeader('D'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Miniatura visual da semana atual
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (index) {
                      final dayNum = (now.day - (now.weekday - 1) + index);
                      final isToday = index == (now.weekday - 1);
                      return Container(
                        width: 38,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isToday ? palette.primary : palette.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isToday ? palette.primary : palette.border.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayNum > 0 ? '$dayNum' : '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isToday ? palette.onPrimary : palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isToday
                                    ? palette.onPrimary
                                    : (index < now.weekday
                                        ? const Color(0xFF10B981)
                                        : palette.textMuted.withValues(alpha: 0.4)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Banner Informativo do Roadmap
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: palette.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.calendar_month_rounded, color: palette.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestão Visual no Calendário',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Próxima funcionalidade em desenvolvimento',
                              style: TextStyle(fontSize: 11, color: palette.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Em breve, você poderá visualizar todas as suas rotinas, hábitos e alarmes em um calendário mensal completo:',
                    style: TextStyle(fontSize: 12, color: palette.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  _buildFeatureBullet(palette, Icons.check_circle_outline, 'Heatmap de consistência diária e streaks'),
                  const SizedBox(height: 8),
                  _buildFeatureBullet(palette, Icons.date_range_outlined, 'Visão semanal e mensal de compromissos'),
                  const SizedBox(height: 8),
                  _buildFeatureBullet(palette, Icons.drag_indicator, 'Reagendamento rápido de rotinas por data'),
                  const SizedBox(height: 20),
                  if (onNavigateToHome != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.primary,
                          side: BorderSide(color: palette.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: onNavigateToHome,
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Voltar para o Início', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildFeatureBullet(AppPaletteData palette, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: palette.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: palette.textPrimary, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _WeekHeader extends StatelessWidget {
  final String label;
  const _WeekHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }
}

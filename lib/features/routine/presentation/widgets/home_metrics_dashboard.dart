import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class HomeMetricsDashboard extends StatelessWidget {
  final AppPaletteData palette;
  final int completedToday;
  final int totalToday;
  final int currentStreak;
  final int recordStreak;
  final String focusTimeFormatted;
  final String focusMetaFormatted;

  const HomeMetricsDashboard({
    super.key,
    required this.palette,
    required this.completedToday,
    required this.totalToday,
    required this.currentStreak,
    required this.recordStreak,
    this.focusTimeFormatted = '1h 45m',
    this.focusMetaFormatted = 'Meta: 2h/dia',
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = totalToday == 0 ? 0 : ((completedToday / totalToday) * 100).round();
    final progressFactor = totalToday == 0 ? 0.0 : (completedToday / totalToday).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Card 1: Progresso
          Expanded(
            child: _buildMetricCard(
              label: 'PROGRESSO',
              value: '$progressPercent%',
              valueColor: const Color(0xFF10B981),
              middleWidget: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                height: 5,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressFactor,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              subtitle: '$completedToday de $totalToday feitas',
            ),
          ),
          const SizedBox(width: 8),

          // Card 2: Ofensiva (Streak)
          Expanded(
            child: _buildMetricCard(
              label: 'OFENSIVA',
              value: '$currentStreak Dias',
              valueColor: const Color(0xFFF59E0B),
              middleWidget: const SizedBox(height: 5),
              subtitle: 'Recorde: ${recordStreak}d',
            ),
          ),
          const SizedBox(width: 8),

          // Card 3: Tempo Foco
          Expanded(
            child: _buildMetricCard(
              label: 'TEMPO FOCO',
              value: focusTimeFormatted,
              valueColor: palette.primary,
              middleWidget: const SizedBox(height: 5),
              subtitle: focusMetaFormatted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color valueColor,
    required Widget middleWidget,
    required String subtitle,
  }) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: palette.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          middleWidget,
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: palette.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

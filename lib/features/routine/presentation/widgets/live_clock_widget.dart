import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../screens/dedicated_clock_screen.dart';
import '../../../../core/theme/theme_provider.dart';

class LiveClockWidget extends ConsumerStatefulWidget {
  const LiveClockWidget({super.key});

  @override
  ConsumerState<LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends ConsumerState<LiveClockWidget> {
  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const weekDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final weekday = weekDays[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$weekday, ${dt.day} de $month';
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final timeStr = DateFormat('HH:mm:ss').format(_currentTime);
    final dateStr = _formatDate(_currentTime);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DedicatedClockScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone discreto indicando interatividade
                Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tela cheia',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: palette.textMuted.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.fullscreen_rounded,
                        size: 15,
                        color: palette.textMuted.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Mostrador de Relógio Analógico Estilizado
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _AnalogClockPainter(
                      time: _currentTime,
                      dialColor: palette.surfaceVariant,
                      borderColor: palette.border,
                      hourHandColor: palette.textPrimary,
                      minuteHandColor: palette.textSecondary,
                      secondHandColor: palette.primary,
                      centerDotColor: palette.primary,
                      textColor: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Horário Digital com Segundos
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: palette.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),

                // Data e Localidade
                Text(
                  'Horário local • $dateStr',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  final DateTime time;
  final Color dialColor;
  final Color borderColor;
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color secondHandColor;
  final Color centerDotColor;
  final Color textColor;

  _AnalogClockPainter({
    required this.time,
    required this.dialColor,
    required this.borderColor,
    required this.hourHandColor,
    required this.minuteHandColor,
    required this.secondHandColor,
    required this.centerDotColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Fundo do mostrador
    final dialPaint = Paint()
      ..color = dialColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dialPaint);

    // Borda do mostrador
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);

    // Marcadores de horas (12 risquinhos)
    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * pi / 180;
      final isMajor = i % 3 == 0;
      final startRadius = radius - (isMajor ? 10 : 6);
      final endRadius = radius - 3;

      final p1 = Offset(center.dx + startRadius * sin(angle), center.dy - startRadius * cos(angle));
      final p2 = Offset(center.dx + endRadius * sin(angle), center.dy - endRadius * cos(angle));

      final tickPaint = Paint()
        ..color = isMajor ? hourHandColor : textColor
        ..strokeWidth = isMajor ? 2.0 : 1.0;
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Ponteiro das Horas
    final hourAngle = ((time.hour % 12) + time.minute / 60) * 30 * pi / 180;
    final hourHandLength = radius * 0.52;
    final hourEnd = Offset(center.dx + hourHandLength * sin(hourAngle), center.dy - hourHandLength * cos(hourAngle));
    final hourPaint = Paint()
      ..color = hourHandColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, hourEnd, hourPaint);

    // Ponteiro dos Minutos
    final minuteAngle = (time.minute + time.second / 60) * 6 * pi / 180;
    final minuteHandLength = radius * 0.72;
    final minuteEnd = Offset(center.dx + minuteHandLength * sin(minuteAngle), center.dy - minuteHandLength * cos(minuteAngle));
    final minutePaint = Paint()
      ..color = minuteHandColor
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, minuteEnd, minutePaint);

    // Ponteiro dos Segundos
    final secondAngle = time.second * 6 * pi / 180;
    final secondHandLength = radius * 0.82;
    final secondEnd = Offset(center.dx + secondHandLength * sin(secondAngle), center.dy - secondHandLength * cos(secondAngle));
    final secondPaint = Paint()
      ..color = secondHandColor
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, secondEnd, secondPaint);

    // Ponto Central
    final centerDotPaint = Paint()
      ..color = centerDotColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) {
    return oldDelegate.time.second != time.second;
  }
}

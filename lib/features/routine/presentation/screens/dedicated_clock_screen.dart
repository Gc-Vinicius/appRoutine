import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/routine_provider.dart';
import '../../domain/routine_model.dart';
import '../../../../core/theme/theme_provider.dart';

/// Tela Dedicada ao Horário Local com mostrador analógico em alta definição e relógio digital com segundos
class DedicatedClockScreen extends ConsumerStatefulWidget {
  const DedicatedClockScreen({super.key});

  @override
  ConsumerState<DedicatedClockScreen> createState() => _DedicatedClockScreenState();
}

class _DedicatedClockScreenState extends ConsumerState<DedicatedClockScreen> {
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

  String _formatFullDate(DateTime dt) {
    const weekDays = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    final weekday = weekDays[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$weekday, ${dt.day} de $month de ${dt.year}';
  }

  RoutineModel? _getNextActiveRoutine(List<RoutineModel> routines) {
    RoutineModel? closest;
    DateTime? closestTime;

    for (final r in routines) {
      if (!r.isActive || r.isCurrentlySkipped) continue;
      final next = r.nextOccurrence;
      if (next != null) {
        if (closestTime == null || next.isBefore(closestTime)) {
          closestTime = next;
          closest = r;
        }
      }
    }
    return closest;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final routines = ref.watch(routineListProvider);
    final nextRoutine = _getNextActiveRoutine(routines);

    final hours = DateFormat('HH').format(_currentTime);
    final minutes = DateFormat('mm').format(_currentTime);
    final seconds = DateFormat('ss').format(_currentTime);
    final fullDate = _formatFullDate(_currentTime);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: palette.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Voltar',
        ),
        title: Text(
          'Horário Local',
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final clockSize = (constraints.maxWidth * 0.65).clamp(180.0, 300.0);

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mostrador Analógico Ampliado
                    Container(
                      width: clockSize,
                      height: clockSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.surface,
                        border: Border.all(color: palette.border, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: palette.isDark ? 0.4 : 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _BigAnalogClockPainter(
                          time: _currentTime,
                          dialColor: palette.surface,
                          borderColor: palette.border,
                          hourHandColor: palette.textPrimary,
                          minuteHandColor: palette.textSecondary,
                          secondHandColor: palette.primary,
                          centerDotColor: palette.primary,
                          textColor: palette.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Relógio Digital em Alta Definição com Segundos
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: palette.border, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$hours:$minutes',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1.5,
                              color: palette.textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            seconds,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: palette.primary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Data Completa
                    Text(
                      fullDate,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),

                    // Fuso Horário Local
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.public_rounded, size: 14, color: palette.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Fuso Local: ${DateTime.now().timeZoneName} (UTC${DateTime.now().timeZoneOffset.isNegative ? '' : '+'}${DateTime.now().timeZoneOffset.inHours})',
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),

                    if (nextRoutine != null) ...[
                      const SizedBox(height: 28),
                      // Card com o próximo alarme programado
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: palette.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: palette.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                nextRoutine.displayCategoryEmoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PRÓXIMO ALARME',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    nextRoutine.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: palette.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${nextRoutine.hour.toString().padLeft(2, '0')}:${nextRoutine.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: palette.primary,
                                  ),
                                ),
                                Text(
                                  nextRoutine.timeUntilNextFormatted,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BigAnalogClockPainter extends CustomPainter {
  final DateTime time;
  final Color dialColor;
  final Color borderColor;
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color secondHandColor;
  final Color centerDotColor;
  final Color textColor;

  _BigAnalogClockPainter({
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

    // Marcadores das 12 horas
    final markPaint = Paint()
      ..strokeCap = StrokeCap.round;

    final hourMarks = [12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    for (int i = 0; i < 12; i++) {
      final isMajor = i % 3 == 0;
      markPaint.strokeWidth = isMajor ? 3.0 : 1.5;
      markPaint.color = isMajor ? textColor : textColor.withValues(alpha: 0.35);

      final angle = (i * 30.0 - 90.0) * (pi / 180.0);
      final markLength = isMajor ? 12.0 : 6.0;
      final start = Offset(
        center.dx + (radius - markLength - 6) * cos(angle),
        center.dy + (radius - markLength - 6) * sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 6) * cos(angle),
        center.dy + (radius - 6) * sin(angle),
      );
      canvas.drawLine(start, end, markPaint);

      if (isMajor) {
        final textSpan = TextSpan(
          text: '${hourMarks[i]}',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        final numRadius = radius - 26;
        final tx = center.dx + numRadius * cos(angle) - tp.width / 2;
        final ty = center.dy + numRadius * sin(angle) - tp.height / 2;
        tp.paint(canvas, Offset(tx, ty));
      }
    }

    // Ponteiro de Horas
    final hourAngle = ((time.hour % 12 + time.minute / 60.0) * 30.0 - 90.0) * (pi / 180.0);
    final hourPaint = Paint()
      ..color = hourHandColor
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius * 0.48) * cos(hourAngle),
        center.dy + (radius * 0.48) * sin(hourAngle),
      ),
      hourPaint,
    );

    // Ponteiro de Minutos
    final minuteAngle = ((time.minute + time.second / 60.0) * 6.0 - 90.0) * (pi / 180.0);
    final minutePaint = Paint()
      ..color = minuteHandColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius * 0.70) * cos(minuteAngle),
        center.dy + (radius * 0.70) * sin(minuteAngle),
      ),
      minutePaint,
    );

    // Ponteiro de Segundos
    final secondAngle = (time.second * 6.0 - 90.0) * (pi / 180.0);
    final secondPaint = Paint()
      ..color = secondHandColor
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(
        center.dx - (radius * 0.15) * cos(secondAngle),
        center.dy - (radius * 0.15) * sin(secondAngle),
      ),
      Offset(
        center.dx + (radius * 0.82) * cos(secondAngle),
        center.dy + (radius * 0.82) * sin(secondAngle),
      ),
      secondPaint,
    );

    // Ponto Central
    final centerDotPaint = Paint()..color = centerDotColor;
    canvas.drawCircle(center, 5.0, centerDotPaint);
    final innerDotPaint = Paint()..color = dialColor;
    canvas.drawCircle(center, 2.0, innerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _BigAnalogClockPainter oldDelegate) {
    return oldDelegate.time.second != time.second;
  }
}

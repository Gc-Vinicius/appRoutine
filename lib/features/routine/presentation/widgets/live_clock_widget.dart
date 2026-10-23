import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../screens/dedicated_clock_screen.dart';
import '../../../../core/theme/theme_provider.dart';

/// Header Hero minimalista e tipográfico para a tela inicial
/// Exibe hora e segundos em tempo real de forma fluida sem moldura de card.
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
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];
    final weekday = weekDays[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$weekday, ${dt.day} de $month';
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final hoursAndMinutes = DateFormat('HH:mm').format(_currentTime);
    final secondsStr = DateFormat(':ss').format(_currentTime);
    final dateStr = _formatDate(_currentTime);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DedicatedClockScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Horário Digital Hero (HH:mm em destaque, :ss elegante em cor de destaque)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        hoursAndMinutes,
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: palette.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        secondsStr,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: palette.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Data e atalho para tela cheia
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: palette.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3.5,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: palette.textMuted.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tela cheia',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: palette.primary,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.fullscreen_rounded,
                            size: 15,
                            color: palette.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

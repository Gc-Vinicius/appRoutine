import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/routine_provider.dart';
import '../../domain/routine_model.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/theme_provider.dart';

/// Tela Cheia Imersiva de Alarme Tocando no Celular (Mobile First)
class AlarmRingingScreen extends ConsumerStatefulWidget {
  final RoutineModel routine;
  final int snoozeCount;

  const AlarmRingingScreen({
    super.key,
    required this.routine,
    this.snoozeCount = 0,
  });

  @override
  ConsumerState<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends ConsumerState<AlarmRingingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _clockTimer;
  Timer? _crescendoTimer;
  Timer? _soundVibrateTimer;

  DateTime _currentTime = DateTime.now();
  int _secondsElapsed = 0;
  double _currentVolumeLevel = 0.05; // Inicia em 5% no fade-in

  // Estado do botão deslizante (Slide to Dismiss)
  double _dragPosition = 0.0;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();

    // Animação de pulso do relógio
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Atualização do relógio a cada segundo
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    // Início do ciclo de som e volume crescente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAlarmCycle();
    });
  }

  void _startAlarmCycle() {
    final settings = ref.read(alarmSettingsProvider);

    // Pulso tátil e sonoro inicial
    _triggerSoundAndHaptic();

    if (settings.crescendoVolume) {
      _currentVolumeLevel = 0.05;
      _crescendoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _isDismissed) {
          timer.cancel();
          return;
        }
        setState(() {
          _secondsElapsed++;
          // Aumento gradual até 1.0 (100%) em 30 segundos
          final progress = (_secondsElapsed / settings.crescendoDurationSeconds).clamp(0.0, 1.0);
          _currentVolumeLevel = 0.05 + (0.95 * progress);
        });

        if (_secondsElapsed >= settings.crescendoDurationSeconds) {
          timer.cancel();
        }
      });
    } else {
      _currentVolumeLevel = 1.0;
    }

    // Repetição de padrão de toque / vibração a cada 2.5 segundos
    _soundVibrateTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted || _isDismissed) return;
      _triggerSoundAndHaptic();
    });
  }

  void _triggerSoundAndHaptic() {
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  void _stopAlarm() {
    _isDismissed = true;
    _clockTimer?.cancel();
    _crescendoTimer?.cancel();
    _soundVibrateTimer?.cancel();
    _pulseController.stop();
  }

  void _onDismissConfirmed() {
    if (_isDismissed) return;
    _stopAlarm();

    HapticFeedback.vibrate();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarme "${widget.routine.title}" desligado com sucesso!'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _onSnoozePressed() async {
    final settings = ref.read(alarmSettingsProvider);
    if (widget.snoozeCount >= settings.maxSnoozeCount) return;

    _stopAlarm();

    await NotificationService().snoozeRoutine(
      id: widget.routine.id ?? 9999,
      title: widget.routine.title,
      body: widget.routine.body,
      minutes: settings.snoozeDurationMinutes,
    );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Soneca ativada (+${settings.snoozeDurationMinutes} min). Próximo disparo em instantes.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopAlarm();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final settings = ref.watch(alarmSettingsProvider);

    final hourStr = _currentTime.hour.toString().padLeft(2, '0');
    final minuteStr = _currentTime.minute.toString().padLeft(2, '0');
    final secondStr = _currentTime.second.toString().padLeft(2, '0');

    final canSnooze = widget.snoozeCount < settings.maxSnoozeCount;

    return PopScope(
      canPop: false, // Força desligar via slider ou soneca
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Topo: Badges de Categoria e Soneca
                Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: palette.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: palette.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(widget.routine.displayCategoryEmoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                widget.routine.displayCategoryName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.snoozeCount > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              'Soneca ${widget.snoozeCount}/${settings.maxSnoozeCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amberAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Título e Mensagem do Alarme
                    Text(
                      widget.routine.title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.routine.body,
                      style: TextStyle(
                        fontSize: 15,
                        color: palette.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                // Centro: Relógio Digital Pulsante Animado
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: palette.primary.withValues(alpha: 0.35), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: palette.primary.withValues(alpha: 0.12),
                              blurRadius: 36,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$hourStr:$minuteStr',
                              style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              secondStr,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: palette.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Indicador de Volume Crescente
                    if (settings.crescendoVolume) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: palette.surfaceVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: palette.border, width: 0.8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.volume_up_rounded, size: 16, color: palette.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Volume Suave Crescente (${(_currentVolumeLevel * 100).toInt()}%)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 180,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _currentVolumeLevel,
                                  backgroundColor: palette.border,
                                  valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                // Base: Botão Deslizante ("Arraste para Desligar") e Botão Soneca
                Column(
                  children: [
                    // Botão Deslizante
                    _buildSlideToDismiss(palette),
                    const SizedBox(height: 16),

                    // Botão Soneca
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: canSnooze ? _onSnoozePressed : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.textPrimary,
                          side: BorderSide(
                            color: canSnooze ? palette.border : palette.border.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: palette.surface,
                        ),
                        icon: Icon(
                          Icons.snooze_rounded,
                          color: canSnooze ? palette.primary : palette.textMuted,
                        ),
                        label: Text(
                          canSnooze
                              ? 'Soneca (+${settings.snoozeDurationMinutes} minutos)'
                              : 'Limite de Sonecas Atingido (${settings.maxSnoozeCount}x)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: canSnooze ? palette.textPrimary : palette.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construtor do Slider Horizontal "Arraste para Desligar"
  Widget _buildSlideToDismiss(dynamic palette) {
    const double sliderHeight = 64.0;
    const double thumbSize = 54.0;
    const double padding = 5.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - thumbSize - (padding * 2);

        return Container(
          height: sliderHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(sliderHeight / 2),
            border: Border.all(color: palette.primary.withValues(alpha: 0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Texto central pulsante instruindo o arraste
              Center(
                child: Opacity(
                  opacity: (1.0 - (_dragPosition / (maxDrag > 0 ? maxDrag : 1))).clamp(0.2, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Arraste para Desligar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: palette.textMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.keyboard_double_arrow_right_rounded, size: 18, color: palette.primary),
                    ],
                  ),
                ),
              ),

              // Botão arrastável (Thumb)
              Positioned(
                left: padding + _dragPosition,
                top: padding,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragPosition >= maxDrag * 0.82) {
                      _onDismissConfirmed();
                    } else {
                      // Retorna suavemente para o início
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.primary,
                      boxShadow: [
                        BoxShadow(
                          color: palette.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.alarm_off_rounded,
                      color: palette.onPrimary,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

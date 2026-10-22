import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/theme_provider.dart';

class TimerStopwatchScreen extends ConsumerStatefulWidget {
  const TimerStopwatchScreen({super.key});

  @override
  ConsumerState<TimerStopwatchScreen> createState() => _TimerStopwatchScreenState();
}

class _TimerStopwatchScreenState extends ConsumerState<TimerStopwatchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ESTADO DO TEMPORIZADOR (TIMER)
  int _timerTotalSeconds = 300; // 5 minutos padrão
  int _timerRemainingSeconds = 300;
  bool _isTimerRunning = false;
  Timer? _timerCountdown;

  // ESTADO DO CRONÔMETRO (STOPWATCH)
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTimer;
  final List<int> _lapsMilliseconds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _timerCountdown?.cancel();
    _stopwatchTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // --- MÉTODOS DO TEMPORIZADOR ---

  void _setTimerDuration(int seconds) {
    if (_isTimerRunning) return;
    setState(() {
      _timerTotalSeconds = seconds;
      _timerRemainingSeconds = seconds;
    });
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timerCountdown?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      if (_timerRemainingSeconds <= 0) {
        _timerRemainingSeconds = _timerTotalSeconds;
      }
      setState(() => _isTimerRunning = true);
      _timerCountdown = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timerRemainingSeconds > 1) {
          setState(() => _timerRemainingSeconds--);
        } else {
          timer.cancel();
          setState(() {
            _timerRemainingSeconds = 0;
            _isTimerRunning = false;
          });
          _onTimerFinished();
        }
      });
    }
  }

  void _resetTimer() {
    _timerCountdown?.cancel();
    setState(() {
      _isTimerRunning = false;
      _timerRemainingSeconds = _timerTotalSeconds;
    });
  }

  Future<void> _onTimerFinished() async {
    await NotificationService().showNotification(
      id: 777777,
      title: 'Tempo Esgotado! ⏱️',
      body: 'O temporizador do appRoutine finalizou.',
    );
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Temporizador Finalizado! ⏱️'),
        content: const Text('O tempo configurado acabou com sucesso.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS DO CRONÔMETRO ---

  void _toggleStopwatch() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _stopwatchTimer?.cancel();
      setState(() {});
    } else {
      _stopwatch.start();
      _stopwatchTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
        setState(() {});
      });
    }
  }

  void _recordLap() {
    if (!_stopwatch.isRunning) return;
    setState(() {
      _lapsMilliseconds.insert(0, _stopwatch.elapsedMilliseconds);
    });
  }

  void _resetStopwatch() {
    _stopwatch.stop();
    _stopwatch.reset();
    _stopwatchTimer?.cancel();
    setState(() {
      _lapsMilliseconds.clear();
    });
  }

  String _formatMilliseconds(int ms) {
    final minutes = (ms ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
    final hundredths = ((ms % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$hundredths';
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ferramentas de Tempo'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: palette.primary,
          labelColor: palette.primary,
          unselectedLabelColor: palette.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.hourglass_bottom), text: 'Temporizador'),
            Tab(icon: Icon(Icons.timer_outlined), text: 'Cronômetro'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTimerView(palette),
          _buildStopwatchView(palette),
        ],
      ),
    );
  }

  // --- VIEW TEMPORIZADOR ---

  Widget _buildTimerView(dynamic palette) {
    final progress = _timerTotalSeconds > 0
        ? _timerRemainingSeconds / _timerTotalSeconds
        : 0.0;

    final minutes = (_timerRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timerRemainingSeconds % 60).toString().padLeft(2, '0');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Presets Rápidos
          Text(
            'PRESETS RÁPIDOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: palette.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildPresetChip(60, '1 min', palette),
              _buildPresetChip(300, '5 min', palette),
              _buildPresetChip(600, '10 min', palette),
              _buildPresetChip(900, '15 min', palette),
              _buildPresetChip(1500, '25m (Pomodoro)', palette),
              _buildPresetChip(2700, '45 min', palette),
            ],
          ),
          const SizedBox(height: 35),

          // Mostrador Circular com Progresso
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: palette.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(palette.primary),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$minutes:$seconds',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isTimerRunning ? 'EM CONTAGEM' : 'PAUSADO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _isTimerRunning ? palette.primary : palette.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Botões de Ação
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.refresh),
                tooltip: 'Reiniciar',
                onPressed: _resetTimer,
                color: palette.textSecondary,
              ),
              const SizedBox(width: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _toggleTimer,
                icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow, size: 26),
                label: Text(
                  _isTimerRunning ? 'PAUSAR' : 'INICIAR',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(int seconds, String label, dynamic palette) {
    final isSelected = _timerTotalSeconds == seconds;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: _isTimerRunning ? null : (_) => _setTimerDuration(seconds),
      selectedColor: palette.primary,
      backgroundColor: palette.surface,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? (palette.id == 'carmim_pergaminho' ? palette.textPrimary : Colors.white)
            : palette.textPrimary,
      ),
    );
  }

  // --- VIEW CRONÔMETRO ---

  Widget _buildStopwatchView(dynamic palette) {
    final formattedTime = _formatMilliseconds(_stopwatch.elapsedMilliseconds);

    // Identificar melhor e pior volta se houver pelo menos 2 voltas
    int? bestLapIndex;
    int? worstLapIndex;

    if (_lapsMilliseconds.length >= 2) {
      final lapDiffs = <int>[];
      for (int i = 0; i < _lapsMilliseconds.length; i++) {
        final current = _lapsMilliseconds[i];
        final next = (i == _lapsMilliseconds.length - 1) ? 0 : _lapsMilliseconds[i + 1];
        lapDiffs.add(current - next);
      }

      int minDiff = lapDiffs.first;
      int maxDiff = lapDiffs.first;
      bestLapIndex = 0;
      worstLapIndex = 0;

      for (int i = 0; i < lapDiffs.length; i++) {
        if (lapDiffs[i] < minDiff) {
          minDiff = lapDiffs[i];
          bestLapIndex = i;
        }
        if (lapDiffs[i] > maxDiff) {
          maxDiff = lapDiffs[i];
          worstLapIndex = i;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Display Digital Grande
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.border),
            ),
            alignment: Alignment.center,
            child: Text(
              formattedTime,
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 2,
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botões de Controle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: _stopwatch.isRunning ? _recordLap : null,
                icon: const Icon(Icons.flag_outlined, size: 20),
                label: const Text('Volta'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _toggleStopwatch,
                icon: Icon(_stopwatch.isRunning ? Icons.pause : Icons.play_arrow, size: 22),
                label: Text(_stopwatch.isRunning ? 'Pausar' : 'Iniciar'),
              ),
              OutlinedButton.icon(
                onPressed: _stopwatch.elapsedMilliseconds > 0 ? _resetStopwatch : null,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Zerar'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Lista de Voltas
          Expanded(
            child: _lapsMilliseconds.isEmpty
                ? Center(
                    child: Text(
                      'Pressione "Volta" durante a contagem para marcar parciais.',
                      style: TextStyle(fontSize: 12, color: palette.textMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: _lapsMilliseconds.length,
                    itemBuilder: (context, index) {
                      final lapNum = _lapsMilliseconds.length - index;
                      final totalMs = _lapsMilliseconds[index];
                      final prevMs = (index == _lapsMilliseconds.length - 1)
                          ? 0
                          : _lapsMilliseconds[index + 1];
                      final splitMs = totalMs - prevMs;

                      Color? highlightColor;
                      String? badgeText;

                      if (bestLapIndex == index) {
                        highlightColor = Colors.green;
                        badgeText = 'MELHOR';
                      } else if (worstLapIndex == index) {
                        highlightColor = Colors.redAccent;
                        badgeText = 'MAIS LENTA';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: highlightColor ?? palette.border,
                            width: highlightColor != null ? 1.2 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Volta $lapNum',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                if (badgeText != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: highlightColor!.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: highlightColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatMilliseconds(splitMs),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    color: highlightColor ?? palette.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Total: ${_formatMilliseconds(totalMs)}',
                                  style: TextStyle(fontSize: 10, color: palette.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

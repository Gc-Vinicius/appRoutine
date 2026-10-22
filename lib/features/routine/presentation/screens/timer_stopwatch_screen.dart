import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/timer_preset_item.dart';
import '../../../../core/services/local_storage_service.dart';
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
  List<TimerPresetItem> _presets = TimerPresetItem.defaultPresets;

  // ESTADO DO CRONÔMETRO (STOPWATCH)
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTimer;
  final List<int> _lapsMilliseconds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCustomPresets();
  }

  Future<void> _loadCustomPresets() async {
    final list = await LocalStorageService.loadTimerPresets();
    if (mounted) {
      setState(() => _presets = list);
    }
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

  Future<void> _showCustomDurationDialog(dynamic palette) async {
    if (_isTimerRunning) return;

    int selectedMin = _timerTotalSeconds ~/ 60;
    int selectedSec = _timerTotalSeconds % 60;
    final minController = TextEditingController(text: selectedMin.toString());
    final secController = TextEditingController(text: selectedSec.toString().padLeft(2, '0'));

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dContext, setDialogState) {
            return AlertDialog(
              backgroundColor: palette.surface,
              title: Text(
                'Definir Tempo',
                style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Escolha a duração exata do temporizador:',
                    style: TextStyle(fontSize: 12, color: palette.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minutos
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up),
                            onPressed: () {
                              setDialogState(() {
                                selectedMin = (selectedMin + 1).clamp(0, 360);
                                minController.text = selectedMin.toString();
                              });
                            },
                          ),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: minController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                              onChanged: (val) {
                                final n = int.tryParse(val) ?? 0;
                                selectedMin = n.clamp(0, 360);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down),
                            onPressed: () {
                              setDialogState(() {
                                selectedMin = (selectedMin - 1).clamp(0, 360);
                                minController.text = selectedMin.toString();
                              });
                            },
                          ),
                          Text('min', style: TextStyle(fontSize: 11, color: palette.textMuted)),
                        ],
                      ),
                      Text(
                        ' : ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: palette.primary,
                        ),
                      ),
                      // Segundos
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up),
                            onPressed: () {
                              setDialogState(() {
                                selectedSec = (selectedSec + 5) % 60;
                                secController.text = selectedSec.toString().padLeft(2, '0');
                              });
                            },
                          ),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: secController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                              onChanged: (val) {
                                final n = int.tryParse(val) ?? 0;
                                selectedSec = n.clamp(0, 59);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down),
                            onPressed: () {
                              setDialogState(() {
                                selectedSec = (selectedSec - 5 + 60) % 60;
                                secController.text = selectedSec.toString().padLeft(2, '0');
                              });
                            },
                          ),
                          Text('seg', style: TextStyle(fontSize: 11, color: palette.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick add chips inside dialog (+1m, +5m, +15m)
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('+1m'),
                        onPressed: () {
                          setDialogState(() {
                            selectedMin = (selectedMin + 1).clamp(0, 360);
                            minController.text = selectedMin.toString();
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('+5m'),
                        onPressed: () {
                          setDialogState(() {
                            selectedMin = (selectedMin + 5).clamp(0, 360);
                            minController.text = selectedMin.toString();
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('+15m'),
                        onPressed: () {
                          setDialogState(() {
                            selectedMin = (selectedMin + 15).clamp(0, 360);
                            minController.text = selectedMin.toString();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: TextStyle(color: palette.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final total = (selectedMin * 60) + selectedSec;
                    Navigator.pop(ctx, total > 0 ? total : 60);
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result > 0) {
      _setTimerDuration(result);
    }
  }

  Future<void> _showAddPresetDialog(dynamic palette) async {
    final nameController = TextEditingController();
    int min = 15;
    int sec = 0;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dContext, setDialogState) {
            return AlertDialog(
              backgroundColor: palette.surface,
              title: Text(
                'Criar Preset',
                style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Preset',
                      hintText: 'Ex: Foco 20m, Chá, Meditação...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minutos
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_drop_up),
                            onPressed: () => setDialogState(() => min = (min + 1).clamp(0, 360)),
                          ),
                          Text(
                            '${min}m',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: palette.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_drop_down),
                            onPressed: () => setDialogState(() => min = (min - 1).clamp(0, 360)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Segundos
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_drop_up),
                            onPressed: () => setDialogState(() => sec = (sec + 5) % 60),
                          ),
                          Text(
                            '${sec}s',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: palette.textPrimary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_drop_down),
                            onPressed: () => setDialogState(() => sec = (sec - 5 + 60) % 60),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar', style: TextStyle(color: palette.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final nav = Navigator.of(ctx);
                    final name = nameController.text.trim();
                    final total = (min * 60) + sec;
                    if (total <= 0) return;
                    final displayName = name.isNotEmpty ? name : '${min}m ${sec > 0 ? "${sec}s" : ""}';
                    final newPreset = TimerPresetItem(
                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      name: displayName,
                      totalSeconds: total,
                      isDefault: false,
                    );
                    final updated = List<TimerPresetItem>.from(_presets)..add(newPreset);
                    await LocalStorageService.saveTimerPresets(updated);
                    if (mounted) {
                      setState(() {
                        _presets = updated;
                        _setTimerDuration(total);
                      });
                      nav.pop();
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
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
    if (_stopwatch.elapsedMilliseconds <= 0) return;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRESETS DO TEMPORIZADOR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: palette.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddPresetDialog(palette),
                icon: Icon(Icons.add, size: 15, color: palette.primary),
                label: Text(
                  'Novo Preset',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final preset in _presets)
                _buildPresetChip(preset, palette),
            ],
          ),
          const SizedBox(height: 35),

          // Mostrador Circular com Progresso e Toque para Escolha de Tempo Arbitrário
          InkWell(
            onTap: _isTimerRunning ? null : () => _showCustomDurationDialog(palette),
            borderRadius: BorderRadius.circular(110),
            child: Tooltip(
              message: _isTimerRunning ? 'Pause para alterar o tempo' : 'Toque para escolher o tempo',
              child: Stack(
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
                      Row(
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
                          if (!_isTimerRunning) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.edit, size: 16, color: palette.textMuted),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isTimerRunning
                            ? 'EM CONTAGEM'
                            : 'TOQUE PARA DEFINIR TEMPO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _isTimerRunning ? palette.primary : palette.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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

  Widget _buildPresetChip(TimerPresetItem preset, dynamic palette) {
    final isSelected = _timerTotalSeconds == preset.totalSeconds;
    return GestureDetector(
      onLongPress: preset.isDefault
          ? null
          : () async {
              final del = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Excluir Preset?'),
                  content: Text('Deseja remover o preset "${preset.name}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancelar', style: TextStyle(color: palette.textMuted)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              );
              if (del == true && mounted) {
                final updated = _presets.where((p) => p.id != preset.id).toList();
                await LocalStorageService.saveTimerPresets(updated);
                setState(() => _presets = updated);
              }
            },
      child: ChoiceChip(
        label: Text(preset.name),
        selected: isSelected,
        onSelected: _isTimerRunning ? null : (_) => _setTimerDuration(preset.totalSeconds),
        selectedColor: palette.primary,
        backgroundColor: palette.surface,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? (palette.id == 'carmim_pergaminho' ? palette.textPrimary : Colors.white)
              : palette.textPrimary,
        ),
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
                // Permite clicar no botão "Volta" mesmo com o cronometro pausado
                onPressed: _stopwatch.elapsedMilliseconds > 0 ? _recordLap : null,
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
                      'Pressione "Volta" a qualquer momento para marcar parciais.',
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

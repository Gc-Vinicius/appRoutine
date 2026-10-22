import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/routine_model.dart';
import 'create_routine_screen.dart';
import '../widgets/time_wheel_picker_dialog.dart';
import '../../../../core/theme/theme_provider.dart';

class SleepCalculatorScreen extends ConsumerStatefulWidget {
  const SleepCalculatorScreen({super.key});

  @override
  ConsumerState<SleepCalculatorScreen> createState() => _SleepCalculatorScreenState();
}

class _SleepCalculatorScreenState extends ConsumerState<SleepCalculatorScreen> {
  // Modo 0: "Quero acordar às...", Modo 1: "Vou dormir agora"
  int _modeIndex = 0;
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 7, minute: 0);

  Future<void> _pickWakeUpTime() async {
    final palette = ref.read(currentPaletteProvider);
    final picked = await TimeWheelPickerDialog.show(
      context: context,
      initialTime: _wakeUpTime,
      palette: palette,
    );
    if (picked != null) {
      setState(() => _wakeUpTime = picked);
    }
  }

  List<Map<String, dynamic>> _calculateCycles() {
    final now = DateTime.now();
    const cycleMinutes = 90;
    const latencyMinutes = 15; // Média para adormecer

    // Ciclos: 6 (9h), 5 (7h30), 4 (6h), 3 (4h30)
    final cycleConfigs = [
      {'cycles': 6, 'duration': '9h de sono', 'label': 'Excelente 🌟', 'color': Colors.green},
      {'cycles': 5, 'duration': '7h 30min', 'label': 'Recomendado 👍', 'color': Colors.teal},
      {'cycles': 4, 'duration': '6h de sono', 'label': 'Razoável ⚡', 'color': Colors.orange},
      {'cycles': 3, 'duration': '4h 30min', 'label': 'Ciclo Mínimo 💤', 'color': Colors.deepOrangeAccent},
    ];

    final List<Map<String, dynamic>> results = [];

    if (_modeIndex == 0) {
      // "Quero acordar às X:XX" -> Calcular horários para ir para a cama
      final wakeDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _wakeUpTime.hour,
        _wakeUpTime.minute,
      );

      for (final config in cycleConfigs) {
        final cycles = config['cycles'] as int;
        final totalSleepMinutes = (cycles * cycleMinutes) + latencyMinutes;
        final bedDateTime = wakeDateTime.subtract(Duration(minutes: totalSleepMinutes));

        results.add({
          'time': TimeOfDay(hour: bedDateTime.hour, minute: bedDateTime.minute),
          'timeStr': '${bedDateTime.hour.toString().padLeft(2, '0')}:${bedDateTime.minute.toString().padLeft(2, '0')}',
          'cycles': cycles,
          'duration': config['duration'],
          'label': config['label'],
          'color': config['color'],
          'description': 'Durma às ${bedDateTime.hour.toString().padLeft(2, '0')}:${bedDateTime.minute.toString().padLeft(2, '0')} para acordar às ${_wakeUpTime.hour.toString().padLeft(2, '0')}:${_wakeUpTime.minute.toString().padLeft(2, '0')} revigorado.',
        });
      }
    } else {
      // "Vou dormir agora" -> Calcular horários para acordar
      final sleepStart = now.add(const Duration(minutes: latencyMinutes));

      for (final config in cycleConfigs) {
        final cycles = config['cycles'] as int;
        final wakeDateTime = sleepStart.add(Duration(minutes: cycles * cycleMinutes));

        results.add({
          'time': TimeOfDay(hour: wakeDateTime.hour, minute: wakeDateTime.minute),
          'timeStr': '${wakeDateTime.hour.toString().padLeft(2, '0')}:${wakeDateTime.minute.toString().padLeft(2, '0')}',
          'cycles': cycles,
          'duration': config['duration'],
          'label': config['label'],
          'color': config['color'],
          'description': 'Acorde às ${wakeDateTime.hour.toString().padLeft(2, '0')}:${wakeDateTime.minute.toString().padLeft(2, '0')} sem interromper o sono profundo.',
        });
      }
    }

    return results;
  }

  void _createAlarmFor(TimeOfDay targetTime, String label) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateRoutineScreen(
          routineToEdit: RoutineModel(
            title: 'Despertar Ciclo Sono',
            body: 'Despertar ideal ($label)',
            type: RoutineType.recurring,
            category: RoutineCategory.general,
            hour: targetTime.hour,
            minute: targetTime.minute,
            weekdays: const [1, 2, 3, 4, 5],
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(currentPaletteProvider);
    final cycles = _calculateCycles();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ciclos de Sono (REM)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Explicativo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.primary.withValues(alpha: 0.15),
                    ),
                    child: Icon(Icons.nightlight_round, color: palette.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A Regra de Ouro dos 90 Minutos',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Acordar no meio de um ciclo de sono causa cansaço. Acordar entre os ciclos garante disposição natural.',
                          style: TextStyle(fontSize: 11, color: palette.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Alternador de Modo
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _modeIndex = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _modeIndex == 0 ? palette.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Quero Acordar às...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _modeIndex == 0
                                ? (palette.id == 'carmim_pergaminho' ? palette.textPrimary : Colors.white)
                                : palette.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _modeIndex = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _modeIndex == 1 ? palette.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Vou Dormir Agora',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _modeIndex == 1
                                ? (palette.id == 'carmim_pergaminho' ? palette.textPrimary : Colors.white)
                                : palette.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Seletor de Horário se Modo == 0
            if (_modeIndex == 0) ...[
              InkWell(
                onTap: _pickWakeUpTime,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Horário Desejado para Despertar',
                              style: TextStyle(fontSize: 11, color: palette.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            '${_wakeUpTime.hour.toString().padLeft(2, '0')}:${_wakeUpTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: palette.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: palette.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Alterar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: palette.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              _modeIndex == 0 ? 'HORÁRIOS SUGERIDOS PARA DORMIR' : 'HORÁRIOS SUGERIDOS PARA DESPERTAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: palette.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Lista de Cartões de Ciclo
            ...cycles.map((item) {
              final color = item['color'] as Color;
              final timeStr = item['timeStr'] as String;
              final duration = item['duration'] as String;
              final label = item['label'] as String;
              final description = item['description'] as String;
              final targetTime = item['time'] as TimeOfDay;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$duration • $description',
                            style: TextStyle(fontSize: 10.5, color: palette.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.alarm_add_outlined, color: palette.primary),
                      tooltip: 'Criar Alarme',
                      onPressed: () => _createAlarmFor(targetTime, label),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

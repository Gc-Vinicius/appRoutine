import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Seletor de Horário no estilo Wheel / Spinner vertical com rolagem contínua cíclica (loop infinito)
class TimeWheelPickerDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final AppPaletteData palette;

  const TimeWheelPickerDialog({
    super.key,
    required this.initialTime,
    required this.palette,
  });

  static Future<TimeOfDay?> show({
    required BuildContext context,
    required TimeOfDay initialTime,
    required AppPaletteData palette,
  }) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TimeWheelPickerDialog(
        initialTime: initialTime,
        palette: palette,
      ),
    );
  }

  @override
  State<TimeWheelPickerDialog> createState() => _TimeWheelPickerDialogState();
}

class _TimeWheelPickerDialogState extends State<TimeWheelPickerDialog> {
  late int _selectedHour;
  late int _selectedMinute;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  static const double _itemExtent = 46.0;

  @override
  void initState() {
    super.initState();
    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: _selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _jumpToCurrentTime() {
    final now = TimeOfDay.now();
    setState(() {
      _selectedHour = now.hour;
      _selectedMinute = now.minute;
    });
    if (_hourController.hasClients) {
      _hourController.jumpToItem(now.hour);
    }
    if (_minuteController.hasClients) {
      _minuteController.jumpToItem(now.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: palette.border, width: 1),
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de Arraste Superior
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Título do Modal + Botão Atalho "Hora atual"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selecionar Horário',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: _jumpToCurrentTime,
                icon: Icon(Icons.access_time_rounded, size: 15, color: palette.primary),
                label: Text(
                  'Hora atual',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: palette.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  backgroundColor: palette.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cabeçalhos das Colunas: H e M
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 90,
                child: Center(
                  child: Text(
                    'H',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: palette.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
              SizedBox(
                width: 90,
                child: Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: palette.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Rodas Verticais de Horas e Minutos (Wheel Spinner Cíclico)
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Faixa de Destaque Centralizada
                Container(
                  height: _itemExtent,
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.primary.withValues(alpha: 0.3), width: 1.2),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Coluna de Horas (00 a 23 com Looping Cíclico)
                    SizedBox(
                      width: 90,
                      child: ListWheelScrollView.useDelegate(
                        controller: _hourController,
                        itemExtent: _itemExtent,
                        physics: const FixedExtentScrollPhysics(),
                        perspective: 0.003,
                        diameterRatio: 1.5,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedHour = (index % 24 + 24) % 24;
                          });
                        },
                        childDelegate: ListWheelChildLoopingListDelegate(
                          children: List.generate(24, (i) {
                            final isSelected = i == _selectedHour;
                            return Center(
                              child: Text(
                                i.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isSelected ? 28 : 20,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? palette.textPrimary : palette.textMuted,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    // Dois Pontos Separadores
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),

                    // Coluna de Minutos (00 a 59 com Looping Cíclico)
                    SizedBox(
                      width: 90,
                      child: ListWheelScrollView.useDelegate(
                        controller: _minuteController,
                        itemExtent: _itemExtent,
                        physics: const FixedExtentScrollPhysics(),
                        perspective: 0.003,
                        diameterRatio: 1.5,
                        onSelectedItemChanged: (index) {
                          setState(() {
                            _selectedMinute = (index % 60 + 60) % 60;
                          });
                        },
                        childDelegate: ListWheelChildLoopingListDelegate(
                          children: List.generate(60, (i) {
                            final isSelected = i == _selectedMinute;
                            return Center(
                              child: Text(
                                i.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: isSelected ? 28 : 20,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? palette.textPrimary : palette.textMuted,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botões de Ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.textSecondary,
                    side: BorderSide(color: palette.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

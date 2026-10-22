import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/routine_model.dart';
import '../providers/routine_provider.dart';
import '../widgets/smartwatch_preview_card.dart';
import '../widgets/time_wheel_picker_dialog.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme_provider.dart';

class CreateRoutineScreen extends ConsumerStatefulWidget {
  final RoutineModel? routineToEdit;

  const CreateRoutineScreen({super.key, this.routineToEdit});

  @override
  ConsumerState<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends ConsumerState<CreateRoutineScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  late RoutineType _selectedType;
  late TimeOfDay _selectedTime;
  late List<int> _selectedWeekdays;
  late DateTime _selectedPunctualDate;
  int _intervalMinutes = 120; // 2 horas

  bool get _isEditing => widget.routineToEdit != null;

  @override
  void initState() {
    super.initState();

    final toEdit = widget.routineToEdit;
    if (toEdit != null) {
      _titleController.text = toEdit.title;
      _bodyController.text = toEdit.body;
      _selectedType = toEdit.type;
      _selectedTime = TimeOfDay(hour: toEdit.hour, minute: toEdit.minute);
      _selectedWeekdays = List<int>.from(toEdit.weekdays);
      _selectedPunctualDate = toEdit.punctualDate ?? DateTime.now();
      _intervalMinutes = toEdit.intervalMinutes ?? 120;
    } else {
      _titleController.text = '';
      _bodyController.text = '';
      _selectedType = RoutineType.recurring;
      _selectedTime = const TimeOfDay(hour: 7, minute: 0);
      _selectedWeekdays = [1, 2, 3, 4, 5]; // Seg a Sex padrão
      _selectedPunctualDate = DateTime.now();
      _intervalMinutes = 120;
    }

    _titleController.addListener(() => setState(() {}));
    _bodyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final palette = ref.read(currentPaletteProvider);
    final picked = await TimeWheelPickerDialog.show(
      context: context,
      initialTime: _selectedTime,
      palette: palette,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedPunctualDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedPunctualDate = picked);
    }
  }

  Future<void> _confirmDelete() async {
    final palette = ref.read(currentPaletteProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Rotina?'),
        content: const Text(
          'Esta ação cancelará o alarme programado no relógio e removerá o item permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: palette.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(routineListProvider.notifier).deleteRoutine(widget.routineToEdit!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rotina excluída com sucesso.')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _saveRoutine() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe um título para a rotina.')),
      );
      return;
    }

    if (_selectedType == RoutineType.recurring && _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um dia da semana para a rotina recorrente.')),
      );
      return;
    }

    DateTime? punctualDate;
    if (_selectedType == RoutineType.punctual) {
      final now = DateTime.now();
      DateTime target = DateTime(
        _selectedPunctualDate.year,
        _selectedPunctualDate.month,
        _selectedPunctualDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      // Se selecionou para hoje mas o horário já passou, ajusta automaticamente para o dia seguinte
      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }
      punctualDate = target;
    }

    final newRoutine = RoutineModel(
      id: widget.routineToEdit?.id,
      title: title,
      body: body.isEmpty ? title : body,
      type: _selectedType,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      weekdays: _selectedType == RoutineType.recurring ? _selectedWeekdays : [],
      intervalMinutes: _selectedType == RoutineType.periodic ? _intervalMinutes : null,
      windowStartHour: _selectedType == RoutineType.periodic ? 8 : null,
      windowEndHour: _selectedType == RoutineType.periodic ? 20 : null,
      punctualDate: punctualDate,
      isActive: widget.routineToEdit?.isActive ?? true,
      createdAt: widget.routineToEdit?.createdAt ?? DateTime.now(),
    );

    await ref.read(routineListProvider.notifier).addOrUpdateRoutine(newRoutine);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Rotina atualizada com sucesso!'
              : 'Alarme salvo e agendado com sucesso!'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reatividade imediata de tema
    final palette = ref.watch(currentPaletteProvider);
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Alarme de Rotina' : 'Novo Alarme de Rotina'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Excluir Rotina',
              onPressed: _confirmDelete,
            ),
          TextButton(
            onPressed: _saveRoutine,
            child: Text(
              _isEditing ? 'Atualizar' : 'Salvar',
              style: TextStyle(
                color: palette.primary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seletor de Tipo (Segmented Control)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  _buildTypeOption(RoutineType.recurring, 'Recorrente', palette),
                  _buildTypeOption(RoutineType.periodic, 'Periódico', palette),
                  _buildTypeOption(RoutineType.punctual, 'Pontual', palette),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // INPUT 1: Título com Trava Rígida (RF02)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Título da Rotina',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_titleController.text.length} / ${AppConstants.maxTitleLength} chars',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: palette.badgeText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              maxLength: AppConstants.maxTitleLength,
              inputFormatters: [
                LengthLimitingTextInputFormatter(AppConstants.maxTitleLength),
              ],
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'Ex: Tomar Creatina',
              ),
            ),
            Text(
              'Limite rígido de 30 chars para visualização perfeita no relógio.',
              style: TextStyle(fontSize: 10.5, color: palette.textMuted),
            ),
            const SizedBox(height: 16),

            // INPUT 2: Mensagem com Trava Rígida (RF02)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mensagem do Alarme',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_bodyController.text.length} / ${AppConstants.maxBodyLength} chars',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: palette.badgeText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _bodyController,
              maxLength: AppConstants.maxBodyLength,
              inputFormatters: [
                LengthLimitingTextInputFormatter(AppConstants.maxBodyLength),
              ],
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'Ex: Tomar 5g creatina com 500ml de água',
              ),
            ),
            Text(
              'Limite de 70 chars. Sem emojis ou quebras que cortem no pulso.',
              style: TextStyle(fontSize: 10.5, color: palette.textMuted),
            ),
            const SizedBox(height: 20),

            // LIVE SMARTWATCH MIRROR PREVIEW
            SmartwatchPreviewCard(
              title: _titleController.text,
              body: _bodyController.text,
              time: timeStr,
            ),
            const SizedBox(height: 20),

            // Configuração de Horário / Dias
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horário',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: palette.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                              Icon(Icons.access_time, color: palette.primary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedType == RoutineType.punctual) ...[
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data do Disparo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: palette.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_selectedPunctualDate.day.toString().padLeft(2, '0')}/${_selectedPunctualDate.month.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                ),
                                Icon(Icons.calendar_today, color: palette.primary, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Dias da Semana (Para Recorrente)
            if (_selectedType == RoutineType.recurring) ...[
              Text(
                'Repetir nos Dias da Semana',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildWeekdaySelector(palette),
              const SizedBox(height: 16),
            ],

            // Botão Salvar / Atualizar
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saveRoutine,
              child: Text(_isEditing ? 'Atualizar Alarme de Rotina' : 'Salvar e Agendar Alarme'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(RoutineType type, String label, dynamic palette) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? palette.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (palette.id == 'carmim_pergaminho' ? palette.textPrimary : Colors.white)
                  : palette.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdaySelector(dynamic palette) {
    // 1=Seg, 2=Ter, 3=Qua, 4=Qui, 5=Sex, 6=Sáb, 7=Dom
    const days = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isSelected = _selectedWeekdays.contains(dayNum);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedWeekdays.remove(dayNum);
              } else {
                _selectedWeekdays.add(dayNum);
                _selectedWeekdays.sort();
              }
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? palette.primary : palette.surface,
              border: Border.all(
                color: isSelected ? palette.primary : palette.border,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              days[index],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (palette.id == 'carmim_pergaminho' ? palette.textPrimary : Colors.white)
                    : palette.textMuted,
              ),
            ),
          ),
        );
      }),
    );
  }
}

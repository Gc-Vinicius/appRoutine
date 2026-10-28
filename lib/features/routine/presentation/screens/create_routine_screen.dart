import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/category_item.dart';
import '../../domain/routine_model.dart';
import '../providers/routine_provider.dart';
import '../widgets/smartwatch_preview_card.dart';
import '../widgets/time_wheel_picker_dialog.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
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
  late RoutineCategory _selectedCategory;
  String? _customCategoryName;
  String? _customCategoryEmoji;
  late bool _isAlarm;
  late TimeOfDay _selectedTime;
  late List<int> _selectedWeekdays;
  late DateTime _selectedPunctualDate;
  int _intervalMinutes = 120; // 2 horas
  bool _isOneShot = false;

  bool get _isEditing => widget.routineToEdit != null;

  @override
  void initState() {
    super.initState();

    final toEdit = widget.routineToEdit;
    if (toEdit != null) {
      _titleController.text = toEdit.title;
      _bodyController.text = toEdit.body;
      _selectedType = toEdit.type;
      _selectedCategory = toEdit.category;
      _customCategoryName = toEdit.customCategoryName;
      _customCategoryEmoji = toEdit.customCategoryEmoji;
      _isAlarm = toEdit.isAlarm;
      _selectedTime = TimeOfDay(hour: toEdit.hour, minute: toEdit.minute);
      _selectedWeekdays = List<int>.from(toEdit.weekdays);
      _selectedPunctualDate = toEdit.punctualDate ?? DateTime.now();
      _intervalMinutes = toEdit.intervalMinutes ?? 120;
      _isOneShot = toEdit.isOneShot;
    } else {
      _titleController.text = '';
      _bodyController.text = '';
      _selectedType = RoutineType.recurring;
      _selectedCategory = RoutineCategory.general;
      _customCategoryName = null;
      _customCategoryEmoji = null;
      _isAlarm = true;
      _selectedTime = TimeOfDay.now();
      _selectedWeekdays = [1, 2, 3, 4, 5]; // Seg a Sex padrão
      _selectedPunctualDate = DateTime.now();
      _isOneShot = false;
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

  void _showCreateCategoryDialog(BuildContext context, AppPaletteData palette) {
    final nameController = TextEditingController();
    String selectedEmoji = '⭐';
    final popularEmojis = [
      '⭐', '🏃', '🏋️', '🚴', '🧘', '📚', '💼', '💻', '🎯', '🎨',
      '🎵', '🍳', '🍎', '☕', '💊', '💧', '🧹', '🛒', '🐶', '🚗',
      '💡', '🔔', '🛌', '⚽', '🌿', '✈️', '🎮', '👶', '🧴', '❤️'
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: palette.surface,
              title: Text(
                'Nova Categoria',
                style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nome da categoria:',
                      style: TextStyle(fontSize: 12, color: palette.textMuted),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Treino Noturno, Estudos...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Escolha um Emoji ($selectedEmoji):',
                      style: TextStyle(fontSize: 12, color: palette.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: popularEmojis.map((emoji) {
                        final isEmojiSelected = selectedEmoji == emoji;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedEmoji = emoji),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isEmojiSelected
                                  ? palette.primary.withValues(alpha: 0.25)
                                  : palette.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isEmojiSelected ? palette.primary : palette.border,
                                width: isEmojiSelected ? 2 : 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(emoji, style: const TextStyle(fontSize: 18)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
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
                    if (name.isEmpty) return;
                    await ref.read(categoryListProvider.notifier).addCustomCategory(name, selectedEmoji);
                    if (mounted) {
                      setState(() {
                        _selectedCategory = RoutineCategory.general;
                        _customCategoryName = name;
                        _customCategoryEmoji = selectedEmoji;
                      });
                      nav.pop();
                    }
                  },
                  child: const Text('Criar'),
                ),
              ],
            );
          },
        );
      },
    );
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
      category: _selectedCategory,
      customCategoryName: _customCategoryName,
      customCategoryEmoji: _customCategoryEmoji,
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      weekdays: _selectedType == RoutineType.recurring ? _selectedWeekdays : [],
      intervalMinutes: _selectedType == RoutineType.periodic ? _intervalMinutes : null,
      windowStartHour: _selectedType == RoutineType.periodic ? 8 : null,
      windowEndHour: _selectedType == RoutineType.periodic ? 20 : null,
      punctualDate: punctualDate,
      skippedUntil: widget.routineToEdit?.skippedUntil,
      isAlarm: _isAlarm,
      isOneShot: !_isAlarm && _selectedType == RoutineType.punctual ? _isOneShot : false,
      isActive: widget.routineToEdit?.isActive ?? true,
      createdAt: widget.routineToEdit?.createdAt ?? DateTime.now(),
    );

    await ref.read(routineListProvider.notifier).addOrUpdateRoutine(newRoutine);

    if (mounted) {
      final timeInfo = newRoutine.timeUntilNextFormatted;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Rotina atualizada! $timeInfo.'
              : '${_isAlarm ? "Alarme" : "Lembrete"} salvo com sucesso! $timeInfo.'),
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reatividade imediata de tema
    final palette = ref.watch(currentPaletteProvider);
    final List<CategoryItem> categories = ref.watch(categoryListProvider);
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? (_isAlarm ? 'Editar Alarme' : 'Editar Lembrete')
            : (_isAlarm ? 'Novo Alarme' : 'Novo Lembrete')),
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
            // SELETOR: ALARME (Mobile) vs LEMBRETE (Smartwatch)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isAlarm = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isAlarm ? palette.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.alarm,
                              size: 16,
                              color: _isAlarm ? palette.onPrimary : palette.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Alarme',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isAlarm ? palette.onPrimary : palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isAlarm = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isAlarm ? palette.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              size: 16,
                              color: !_isAlarm ? palette.onPrimary : palette.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Lembrete',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !_isAlarm ? palette.onPrimary : palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Card informativo contextual
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: palette.surfaceVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: palette.border, width: 0.6),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAlarm ? Icons.info_outline : Icons.watch_outlined,
                    size: 16,
                    color: palette.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isAlarm
                          ? 'Alarme: Toca som alto, fade-in e tela cheia de despertar no celular.'
                          : 'Lembrete: Notificação pontual e vibração discreta no relógio.',
                      style: TextStyle(fontSize: 11, color: palette.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            // SELETOR DE CATEGORIA (Tags / Ícones)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categoria da Rotina',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showCreateCategoryDialog(context, palette),
                  icon: Icon(Icons.add, size: 16, color: palette.primary),
                  label: Text(
                    'Nova Categoria',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: palette.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...categories.map((cat) {
                    final bool isSelected;
                    if (_customCategoryName != null) {
                      isSelected = !cat.isDefault && cat.name == _customCategoryName;
                    } else {
                      isSelected = cat.isDefault && cat.id == _selectedCategory.name;
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (cat.isDefault) {
                            _selectedCategory = RoutineCategory.values.firstWhere(
                              (c) => c.name == cat.id,
                              orElse: () => RoutineCategory.general,
                            );
                            _customCategoryName = null;
                            _customCategoryEmoji = null;
                          } else {
                            _selectedCategory = RoutineCategory.general;
                            _customCategoryName = cat.name;
                            _customCategoryEmoji = cat.emoji;
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? palette.primary : palette.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? palette.primary : palette.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? palette.onPrimary
                                    : palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 18),

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

            // LIVE SMARTWATCH MIRROR PREVIEW (Centralizado)
            Center(
              child: SmartwatchPreviewCard(
                title: _titleController.text,
                body: _bodyController.text,
                time: timeStr,
              ),
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
            if (!_isAlarm && _selectedType == RoutineType.punctual) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _isOneShot
                      ? palette.primary.withValues(alpha: 0.12)
                      : palette.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isOneShot
                        ? palette.primary.withValues(alpha: 0.6)
                        : palette.border,
                    width: _isOneShot ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isOneShot
                            ? palette.primary
                            : palette.surfaceVariant,
                        border: Border.all(
                          color: _isOneShot ? palette.primary : palette.textMuted,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '1',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _isOneShot ? Colors.white : palette.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Visualização Única',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                              if (_isOneShot) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: palette.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Autodeleção',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: palette.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'O lembrete é excluído automaticamente após você visualizar ou tocar na notificação.',
                            style: TextStyle(
                              fontSize: 12,
                              color: palette.textMuted,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isOneShot,
                      activeTrackColor: palette.primary,
                      onChanged: (val) {
                        setState(() {
                          _isOneShot = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
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
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveRoutine,
                child: Text(_isEditing ? 'Atualizar Alarme de Rotina' : 'Salvar e Agendar Alarme'),
              ),
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
              color: isSelected ? palette.onPrimary : palette.textMuted,
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
                color: isSelected ? palette.onPrimary : palette.textMuted,
              ),
            ),
          ),
        );
      }),
    );
  }
}

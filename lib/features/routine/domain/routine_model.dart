enum RoutineType {
  recurring, // Recorrente por dias da semana
  periodic,  // Periódico por intervalos dentro de janela
  punctual,  // Pontual único (desativa após disparar)
}

enum RoutineCategory {
  general,  // Geral / Alarme padrão
  health,   // Medicamentos & Saúde
  water,    // Hidratação & Alimentação
  workout,  // Exercícios & Treino
  work,     // Trabalho & Produtividade
  study,    // Estudos & Leitura
}

extension RoutineCategoryExtension on RoutineCategory {
  String get label {
    switch (this) {
      case RoutineCategory.health:
        return 'Saúde / Remédio';
      case RoutineCategory.water:
        return 'Hidratação';
      case RoutineCategory.workout:
        return 'Treino';
      case RoutineCategory.work:
        return 'Trabalho';
      case RoutineCategory.study:
        return 'Estudos';
      case RoutineCategory.general:
        return 'Geral';
    }
  }

  String get emoji {
    switch (this) {
      case RoutineCategory.health:
        return '💊';
      case RoutineCategory.water:
        return '💧';
      case RoutineCategory.workout:
        return '🏋️';
      case RoutineCategory.work:
        return '💼';
      case RoutineCategory.study:
        return '📚';
      case RoutineCategory.general:
        return '⏰';
    }
  }
}

class RoutineModel {
  final int? id;
  final String title;
  final String body;
  final RoutineType type;
  final RoutineCategory category;
  final String? customCategoryName;
  final String? customCategoryEmoji;
  final int hour;
  final int minute;
  final List<int> weekdays; // 1 = Seg, 2 = Ter ... 7 = Dom
  final int? intervalMinutes;
  final int? windowStartHour;
  final int? windowEndHour;
  final DateTime? punctualDate;
  final DateTime? skippedUntil; // Data/hora até quando o próximo alarme foi pulado
  final bool isAlarm; // true = Alarme (celular, som, tela cheia), false = Lembrete (smartwatch, notificação limpa)
  final bool isOneShot; // true = Lembrete de visualização única (autodeleta após visualização/disparo)
  final bool isActive;
  final DateTime createdAt;

  const RoutineModel({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    this.category = RoutineCategory.general,
    this.customCategoryName,
    this.customCategoryEmoji,
    required this.hour,
    required this.minute,
    this.weekdays = const [],
    this.intervalMinutes,
    this.windowStartHour,
    this.windowEndHour,
    this.punctualDate,
    this.skippedUntil,
    this.isAlarm = true,
    this.isOneShot = false,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isReminder => !isAlarm;
  bool get isOneShotReminder => isReminder && isOneShot;
  String get alertTypeLabel => isAlarm ? 'Alarme' : 'Lembrete';

  String get displayCategoryName => customCategoryName ?? category.label;
  String get displayCategoryEmoji => customCategoryEmoji ?? category.emoji;

  RoutineModel copyWith({
    int? id,
    String? title,
    String? body,
    RoutineType? type,
    RoutineCategory? category,
    String? customCategoryName,
    String? customCategoryEmoji,
    bool clearCustomCategory = false,
    int? hour,
    int? minute,
    List<int>? weekdays,
    int? intervalMinutes,
    int? windowStartHour,
    int? windowEndHour,
    DateTime? punctualDate,
    DateTime? skippedUntil,
    bool? isAlarm,
    bool? isOneShot,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RoutineModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      category: category ?? this.category,
      customCategoryName: clearCustomCategory
          ? null
          : (customCategoryName ?? this.customCategoryName),
      customCategoryEmoji: clearCustomCategory
          ? null
          : (customCategoryEmoji ?? this.customCategoryEmoji),
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      windowStartHour: windowStartHour ?? this.windowStartHour,
      windowEndHour: windowEndHour ?? this.windowEndHour,
      punctualDate: punctualDate ?? this.punctualDate,
      skippedUntil: skippedUntil ?? this.skippedUntil,
      isAlarm: isAlarm ?? this.isAlarm,
      isOneShot: isOneShot ?? this.isOneShot,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'category': category.name,
      'customCategoryName': customCategoryName,
      'customCategoryEmoji': customCategoryEmoji,
      'hour': hour,
      'minute': minute,
      'weekdays': weekdays,
      'intervalMinutes': intervalMinutes,
      'windowStartHour': windowStartHour,
      'windowEndHour': windowEndHour,
      'punctualDate': punctualDate?.toIso8601String(),
      'skippedUntil': skippedUntil?.toIso8601String(),
      'isAlarm': isAlarm,
      'isOneShot': isOneShot,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      body: json['body'] as String,
      type: RoutineType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => RoutineType.recurring,
      ),
      category: RoutineCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => RoutineCategory.general,
      ),
      customCategoryName: json['customCategoryName'] as String?,
      customCategoryEmoji: json['customCategoryEmoji'] as String?,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      weekdays: (json['weekdays'] as List<dynamic>?)?.map((e) => e as int).toList() ?? const [],
      intervalMinutes: json['intervalMinutes'] as int?,
      windowStartHour: json['windowStartHour'] as int?,
      windowEndHour: json['windowEndHour'] as int?,
      punctualDate: json['punctualDate'] != null
          ? DateTime.tryParse(json['punctualDate'] as String)
          : null,
      skippedUntil: json['skippedUntil'] != null
          ? DateTime.tryParse(json['skippedUntil'] as String)
          : null,
      isAlarm: (json['isAlarm'] as bool?) ?? (json['is_alarm'] as bool?) ?? true,
      isOneShot: (json['isOneShot'] as bool?) ?? (json['is_one_shot'] as bool?) ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get hasPassed {
    if (type != RoutineType.punctual) return false;
    final now = DateTime.now();
    final target = punctualDate ?? DateTime(now.year, now.month, now.day, hour, minute);
    return now.isAfter(target);
  }

  bool get isCurrentlySkipped {
    if (skippedUntil == null) return false;
    return DateTime.now().isBefore(skippedUntil!);
  }

  DateTime? get nextOccurrence {
    if (!isActive) return null;
    final now = DateTime.now();

    switch (type) {
      case RoutineType.punctual:
        if (punctualDate == null) return null;
        if (punctualDate!.isAfter(now)) {
          if (isCurrentlySkipped && !punctualDate!.isAfter(skippedUntil!)) return null;
          return punctualDate;
        }
        return null;

      case RoutineType.recurring:
        if (weekdays.isEmpty) return null;
        for (int i = 0; i <= 7; i++) {
          final candidateDate = now.add(Duration(days: i));
          final candidateWeekday = candidateDate.weekday;
          if (weekdays.contains(candidateWeekday)) {
            final candidate = DateTime(
              candidateDate.year,
              candidateDate.month,
              candidateDate.day,
              hour,
              minute,
            );
            if (candidate.isAfter(now)) {
              if (isCurrentlySkipped && !candidate.isAfter(skippedUntil!)) {
                continue;
              }
              return candidate;
            }
          }
        }
        return null;

      case RoutineType.periodic:
        final interval = intervalMinutes ?? 120;
        final startH = windowStartHour ?? 8;
        final endH = windowEndHour ?? 20;

        DateTime slot = DateTime(now.year, now.month, now.day, startH, 0);
        final endSlot = DateTime(now.year, now.month, now.day, endH, 0);

        while (slot.isBefore(endSlot) || slot.isAtSameMomentAs(endSlot)) {
          if (slot.isAfter(now)) {
            if (isCurrentlySkipped && !slot.isAfter(skippedUntil!)) {
              slot = slot.add(Duration(minutes: interval));
              continue;
            }
            return slot;
          }
          slot = slot.add(Duration(minutes: interval));
        }

        final tomorrow = now.add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, startH, 0);
    }
  }

  String get timeUntilNextFormatted {
    if (!isActive) return isAlarm ? 'Alarme desativado' : 'Lembrete desativado';
    if (isCurrentlySkipped) return 'Próximo disparo pausado';

    final next = nextOccurrence;
    if (next == null) return 'Sem agendamentos futuros';

    final diff = next.difference(DateTime.now());
    if (diff.isNegative) return 'Disparando agora';

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final verb = isAlarm ? 'Toca' : 'Notifica';

    if (hours == 0) {
      return '$verb em ${minutes == 0 ? "menos de 1" : minutes} min';
    } else if (hours < 24) {
      if (minutes == 0) {
        return '$verb em ${hours}h';
      }
      return '$verb em ${hours}h e ${minutes}min';
    } else {
      final days = diff.inDays;
      return '$verb em ${days}d e ${hours % 24}h';
    }
  }

  String get formattedTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get typeLabel {
    switch (type) {
      case RoutineType.recurring:
        return 'RECORRENTE';
      case RoutineType.periodic:
        return 'PERIÓDICO';
      case RoutineType.punctual:
        return isOneShotReminder ? 'PONTUAL • USO ÚNICO' : 'PONTUAL';
    }
  }

  String get recurrenceSubtitle {
    switch (type) {
      case RoutineType.recurring:
        if (weekdays.isEmpty) return 'Nenhum dia selecionado';
        if (weekdays.length == 7) return 'Todos os dias';
        if (weekdays.length == 5 && !weekdays.contains(6) && !weekdays.contains(7)) {
          return 'Segunda a Sexta';
        }
        const dayNames = {1: 'Seg', 2: 'Ter', 3: 'Qua', 4: 'Qui', 5: 'Sex', 6: 'Sáb', 7: 'Dom'};
        final sorted = List<int>.from(weekdays)..sort();
        return sorted.map((d) => dayNames[d] ?? '').join(', ');

      case RoutineType.periodic:
        final hours = (intervalMinutes ?? 120) ~/ 60;
        final start = windowStartHour?.toString().padLeft(2, '0') ?? '08';
        final end = windowEndHour?.toString().padLeft(2, '0') ?? '20';
        return 'A cada ${hours}h • Das $start:00 às $end:00';

      case RoutineType.punctual:
        if (punctualDate == null) return 'Data não definida';
        final d = punctualDate!.day.toString().padLeft(2, '0');
        final m = punctualDate!.month.toString().padLeft(2, '0');
        return isOneShotReminder ? '$d/$m às $formattedTime (Uso único)' : '$d/$m às $formattedTime';
    }
  }
}

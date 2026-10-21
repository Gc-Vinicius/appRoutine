import 'package:flutter/material.dart';

enum RoutineType {
  recurring, // Recorrente por dias da semana
  periodic,  // Periódico por intervalos dentro de janela
  punctual,  // Pontual único (desativa após disparar)
}

class RoutineModel {
  final int? id;
  final String title;
  final String body;
  final RoutineType type;
  final int hour;
  final int minute;
  final List<int> weekdays; // 1 = Seg, 2 = Ter ... 7 = Dom
  final int? intervalMinutes;
  final int? windowStartHour;
  final int? windowEndHour;
  final DateTime? punctualDate;
  final bool isActive;
  final DateTime createdAt;

  const RoutineModel({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.hour,
    required this.minute,
    this.weekdays = const [],
    this.intervalMinutes,
    this.windowStartHour,
    this.windowEndHour,
    this.punctualDate,
    this.isActive = true,
    required this.createdAt,
  });

  RoutineModel copyWith({
    int? id,
    String? title,
    String? body,
    RoutineType? type,
    int? hour,
    int? minute,
    List<int>? weekdays,
    int? intervalMinutes,
    int? windowStartHour,
    int? windowEndHour,
    DateTime? punctualDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RoutineModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      windowStartHour: windowStartHour ?? this.windowStartHour,
      windowEndHour: windowEndHour ?? this.windowEndHour,
      punctualDate: punctualDate ?? this.punctualDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
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
        return 'PONTUAL';
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
        return weekdays.map((d) => dayNames[d] ?? '').join(', ');

      case RoutineType.periodic:
        final hours = (intervalMinutes ?? 120) ~/ 60;
        final start = windowStartHour?.toString().padLeft(2, '0') ?? '08';
        final end = windowEndHour?.toString().padLeft(2, '0') ?? '20';
        return 'A cada ${hours}h • Das $start:00 às $end:00';

      case RoutineType.punctual:
        if (punctualDate == null) return 'Data não definida';
        final d = punctualDate!.day.toString().padLeft(2, '0');
        final m = punctualDate!.month.toString().padLeft(2, '0');
        return '$d/$m às $formattedTime';
    }
  }
}

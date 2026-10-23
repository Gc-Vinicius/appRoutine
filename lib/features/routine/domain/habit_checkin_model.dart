/// Modelo que representa um registro de conclusão (check-in) de um hábito ou rotina
class HabitCheckinModel {
  final int routineId;
  final DateTime date; // Data normalizada do dia (ano, mês, dia)
  final DateTime completedAt; // Data e hora exata do registro
  final bool isCompleted;

  const HabitCheckinModel({
    required this.routineId,
    required this.date,
    required this.completedAt,
    this.isCompleted = true,
  });

  /// Chave única do dia no formato YYYY-MM-DD
  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Verifica se o check-in é referente ao dia de hoje
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Verifica se o check-in é do mesmo dia de outra data fornecida
  bool isSameDay(DateTime other) {
    return date.year == other.year && date.month == other.month && date.day == other.day;
  }

  HabitCheckinModel copyWith({
    int? routineId,
    DateTime? date,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return HabitCheckinModel(
      routineId: routineId ?? this.routineId,
      date: date ?? this.date,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routineId': routineId,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory HabitCheckinModel.fromJson(Map<String, dynamic> json) {
    final rawDate = DateTime.parse(json['date'] as String);
    return HabitCheckinModel(
      routineId: json['routineId'] as int,
      date: DateTime(rawDate.year, rawDate.month, rawDate.day),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : rawDate,
      isCompleted: json['isCompleted'] as bool? ?? true,
    );
  }
}

/// Sumário estatístico de cumprimento de hábitos para os últimos 7 dias
class HabitComplianceSummary {
  final int routineId;
  final int completedDaysLast7;
  final int totalDaysLast7;
  final double complianceRate;
  final int currentStreak;
  final bool isCompletedToday;
  final List<DateTime> last7Days;
  final Map<String, bool> completionMap;

  const HabitComplianceSummary({
    required this.routineId,
    required this.completedDaysLast7,
    this.totalDaysLast7 = 7,
    required this.complianceRate,
    required this.currentStreak,
    required this.isCompletedToday,
    required this.last7Days,
    required this.completionMap,
  });

  /// Taxa de cumprimento formatada (ex: "5 de 7 dias")
  String get formattedRatio => '$completedDaysLast7 de $totalDaysLast7 dias';

  /// Porcentagem formatada (ex: "71%")
  String get formattedPercentage => '${(complianceRate * 100).round()}%';

  /// Calcula o sumário a partir de uma lista de check-ins de uma rotina
  factory HabitComplianceSummary.fromCheckins({
    required int routineId,
    required List<HabitCheckinModel> checkins,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Mapeamento de YYYY-MM-DD -> concluído
    final Map<String, bool> map = {};
    for (final c in checkins) {
      if (c.routineId == routineId && c.isCompleted) {
        map[c.dateKey] = true;
      }
    }

    // Últimos 7 dias (do 6º dia atrás até hoje)
    final List<DateTime> days = [];
    int completedCount = 0;
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      days.add(day);
      final key = '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      if (map[key] == true) {
        completedCount++;
      }
    }

    final todayKey = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final completedToday = map[todayKey] == true;

    // Cálculo da sequência (streak) ininterrupta
    int streak = 0;
    // Se hoje foi concluído, começa de hoje; se não, checa a partir de ontem
    DateTime checkDate = completedToday ? today : today.subtract(const Duration(days: 1));
    while (true) {
      final key = '${checkDate.year.toString().padLeft(4, '0')}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (map[key] == true) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    final rate = completedCount / 7.0;

    return HabitComplianceSummary(
      routineId: routineId,
      completedDaysLast7: completedCount,
      totalDaysLast7: 7,
      complianceRate: rate,
      currentStreak: streak,
      isCompletedToday: completedToday,
      last7Days: days,
      completionMap: map,
    );
  }
}

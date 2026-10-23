class AlarmSettingsModel {
  final int snoozeDurationMinutes; // 5, 10, 15 (padrão: 10)
  final int maxSnoozeCount; // limite máximo de repetições (padrão: 3)
  final bool crescendoVolume; // volume crescente (fade-in ao longo de 30s)
  final int crescendoDurationSeconds; // duração do aumento gradual (padrão: 30s)

  const AlarmSettingsModel({
    this.snoozeDurationMinutes = 10,
    this.maxSnoozeCount = 3,
    this.crescendoVolume = true,
    this.crescendoDurationSeconds = 30,
  });

  AlarmSettingsModel copyWith({
    int? snoozeDurationMinutes,
    int? maxSnoozeCount,
    bool? crescendoVolume,
    int? crescendoDurationSeconds,
  }) {
    return AlarmSettingsModel(
      snoozeDurationMinutes: snoozeDurationMinutes ?? this.snoozeDurationMinutes,
      maxSnoozeCount: maxSnoozeCount ?? this.maxSnoozeCount,
      crescendoVolume: crescendoVolume ?? this.crescendoVolume,
      crescendoDurationSeconds: crescendoDurationSeconds ?? this.crescendoDurationSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'snoozeDurationMinutes': snoozeDurationMinutes,
      'maxSnoozeCount': maxSnoozeCount,
      'crescendoVolume': crescendoVolume,
      'crescendoDurationSeconds': crescendoDurationSeconds,
    };
  }

  factory AlarmSettingsModel.fromJson(Map<String, dynamic> json) {
    return AlarmSettingsModel(
      snoozeDurationMinutes: json['snoozeDurationMinutes'] as int? ?? 10,
      maxSnoozeCount: json['maxSnoozeCount'] as int? ?? 3,
      crescendoVolume: json['crescendoVolume'] as bool? ?? true,
      crescendoDurationSeconds: json['crescendoDurationSeconds'] as int? ?? 30,
    );
  }
}

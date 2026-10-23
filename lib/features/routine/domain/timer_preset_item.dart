class TimerPresetItem {
  final String id;
  final String name;
  final int totalSeconds;
  final bool isDefault;

  const TimerPresetItem({
    required this.id,
    required this.name,
    required this.totalSeconds,
    this.isDefault = false,
  });

  static List<TimerPresetItem> get defaultPresets => const [
    TimerPresetItem(id: 'p_300', name: '5 min', totalSeconds: 300, isDefault: true),
    TimerPresetItem(id: 'p_600', name: '10 min', totalSeconds: 600, isDefault: true),
    TimerPresetItem(id: 'p_1500', name: '25m (Pomodoro)', totalSeconds: 1500, isDefault: true),
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'totalSeconds': totalSeconds,
    'isDefault': isDefault,
  };

  factory TimerPresetItem.fromJson(Map<String, dynamic> json) => TimerPresetItem(
    id: json['id'] as String,
    name: json['name'] as String,
    totalSeconds: json['totalSeconds'] as int,
    isDefault: json['isDefault'] as bool? ?? false,
  );
}

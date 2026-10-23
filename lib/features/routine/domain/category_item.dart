class CategoryItem {
  final String id;
  final String name;
  final String emoji;
  final bool isDefault;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.emoji,
    this.isDefault = false,
  });

  static List<CategoryItem> get defaultCategories => const [
    CategoryItem(id: 'general', name: 'Geral', emoji: '⏰', isDefault: true),
    CategoryItem(id: 'health', name: 'Saúde / Remédio', emoji: '💊', isDefault: true),
    CategoryItem(id: 'water', name: 'Hidratação', emoji: '💧', isDefault: true),
    CategoryItem(id: 'workout', name: 'Treino', emoji: '🏋️', isDefault: true),
    CategoryItem(id: 'work', name: 'Trabalho', emoji: '💼', isDefault: true),
    CategoryItem(id: 'study', name: 'Estudos', emoji: '📚', isDefault: true),
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'isDefault': isDefault,
  };

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    isDefault: json['isDefault'] as bool? ?? false,
  );
}

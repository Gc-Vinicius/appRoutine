import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/routine_repository.dart';
import '../../domain/alarm_settings_model.dart';
import '../../domain/category_item.dart';
import '../../domain/routine_model.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../../core/services/permission_service.dart';

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return LocalRoutineRepository();
});

class RoutineListNotifier extends StateNotifier<List<RoutineModel>> {
  final RoutineRepository _repository;

  RoutineListNotifier(this._repository) : super([]) {
    loadRoutines();
  }

  Future<void> loadRoutines() async {
    final routines = await _repository.getRoutines();
    state = routines;
  }

  Future<void> addOrUpdateRoutine(RoutineModel routine) async {
    await _repository.saveRoutine(routine);
    await loadRoutines();
  }

  Future<void> deleteRoutine(int id) async {
    await _repository.deleteRoutine(id);
    await loadRoutines();
  }

  Future<void> toggleActive(int id, bool isActive) async {
    await _repository.toggleRoutineActive(id, isActive);
    await loadRoutines();
  }

  Future<void> toggleSkipNext(int id) async {
    await _repository.toggleSkipNext(id);
    await loadRoutines();
  }

  Future<void> reloadFromStorage() async {
    await _repository.reloadFromStorage();
    await loadRoutines();
  }
}

final routineListProvider = StateNotifierProvider<RoutineListNotifier, List<RoutineModel>>((ref) {
  final repo = ref.watch(routineRepositoryProvider);
  return RoutineListNotifier(repo);
});

// Provedor de Categorias Customizadas com Emojis
class CategoryListNotifier extends StateNotifier<List<CategoryItem>> {
  CategoryListNotifier() : super(CategoryItem.defaultCategories) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    final list = await LocalStorageService.loadCategories();
    state = list;
  }

  Future<void> addCategory(String name, String emoji) async {
    final newCat = CategoryItem(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      emoji: emoji.trim().isEmpty ? '🏷️' : emoji.trim(),
      isDefault: false,
    );
    final updated = [...state, newCat];
    state = updated;
    await LocalStorageService.saveCategories(updated);
  }

  Future<void> addCustomCategory(String name, String emoji) => addCategory(name, emoji);

  Future<void> deleteCategory(String id) async {
    final updated = state.where((c) => c.id != id || c.isDefault).toList();
    state = updated;
    await LocalStorageService.saveCategories(updated);
  }
}

final categoryListProvider = StateNotifierProvider<CategoryListNotifier, List<CategoryItem>>((ref) {
  return CategoryListNotifier();
});

// Provedor de Configurações de Despertar e Soneca
class AlarmSettingsNotifier extends StateNotifier<AlarmSettingsModel> {
  AlarmSettingsNotifier() : super(const AlarmSettingsModel()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final settings = await LocalStorageService.loadAlarmSettings();
    state = settings;
  }

  Future<void> updateSnoozeDuration(int minutes) async {
    final updated = state.copyWith(snoozeDurationMinutes: minutes);
    state = updated;
    await LocalStorageService.saveAlarmSettings(updated);
  }

  Future<void> updateMaxSnoozeCount(int count) async {
    final updated = state.copyWith(maxSnoozeCount: count);
    state = updated;
    await LocalStorageService.saveAlarmSettings(updated);
  }

  Future<void> toggleCrescendoVolume(bool enabled) async {
    final updated = state.copyWith(crescendoVolume: enabled);
    state = updated;
    await LocalStorageService.saveAlarmSettings(updated);
  }

  Future<void> updateSettings(AlarmSettingsModel settings) async {
    state = settings;
    await LocalStorageService.saveAlarmSettings(settings);
  }
}

final alarmSettingsProvider = StateNotifierProvider<AlarmSettingsNotifier, AlarmSettingsModel>((ref) {
  return AlarmSettingsNotifier();
});

// Filtro de Tabs na Home
final routineFilterProvider = StateProvider<String>((ref) => 'all');

final filteredRoutinesProvider = Provider<List<RoutineModel>>((ref) {
  final filter = ref.watch(routineFilterProvider);
  final routines = ref.watch(routineListProvider);

  switch (filter) {
    case 'recurring':
      return routines.where((r) => r.type == RoutineType.recurring).toList();
    case 'periodic':
      return routines.where((r) => r.type == RoutineType.periodic).toList();
    case 'punctual':
      return routines.where((r) => r.type == RoutineType.punctual).toList();
    default:
      return routines;
  }
});

// Provedor de Permissões
final permissionsProvider = FutureProvider<SystemPermissionStatus>((ref) async {
  return await PermissionService().checkAllPermissions();
});

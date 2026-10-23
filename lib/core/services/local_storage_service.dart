import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../../features/routine/domain/alarm_settings_model.dart';
import '../../features/routine/domain/category_item.dart';
import '../../features/routine/domain/habit_checkin_model.dart';
import '../../features/routine/domain/routine_model.dart';
import '../../features/routine/domain/timer_preset_item.dart';

/// Serviço 100% offline para persistência atômica de dados locais
class LocalStorageService {
  static const String _routinesFileName = 'routines.json';
  static const String _themeFileName = 'theme_preference.json';
  static const String _categoriesFileName = 'custom_categories.json';
  static const String _timerPresetsFileName = 'timer_presets.json';
  static const String _alarmSettingsFileName = 'alarm_settings.json';
  static const String _habitCheckinsFileName = 'habit_checkins.json';

  static Future<File> _getFile(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  /// Carrega as rotinas gravadas em disco (retorna null se for a primeira inicialização)
  static Future<List<RoutineModel>?> loadRoutines() async {
    try {
      final file = await _getFile(_routinesFileName);
      if (!await file.exists()) {
        return null;
      }
      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) {
        return null;
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => RoutineModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao ler rotinas: $e');
      return null;
    }
  }

  /// Salva todas as rotinas em disco de forma atômica
  static Future<void> saveRoutines(List<RoutineModel> routines) async {
    try {
      final file = await _getFile(_routinesFileName);
      final jsonList = routines.map((r) => r.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList), flush: true);
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao persistir rotinas: $e');
    }
  }

  /// Carrega as categorias (padrões + customizadas pelo usuário)
  static Future<List<CategoryItem>> loadCategories() async {
    try {
      final file = await _getFile(_categoriesFileName);
      if (!await file.exists()) {
        return CategoryItem.defaultCategories;
      }
      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) {
        return CategoryItem.defaultCategories;
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final loaded = jsonList
          .map((item) => CategoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
      if (loaded.isEmpty) {
        return CategoryItem.defaultCategories;
      }
      return loaded;
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao ler categorias: $e');
      return CategoryItem.defaultCategories;
    }
  }

  /// Salva as categorias no disco
  static Future<void> saveCategories(List<CategoryItem> categories) async {
    try {
      final file = await _getFile(_categoriesFileName);
      final jsonList = categories.map((c) => c.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList), flush: true);
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao salvar categorias: $e');
    }
  }

  /// Carrega os presets de temporizador configurados
  static Future<List<TimerPresetItem>> loadTimerPresets() async {
    try {
      final file = await _getFile(_timerPresetsFileName);
      if (!await file.exists()) {
        return TimerPresetItem.defaultPresets;
      }
      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) {
        return TimerPresetItem.defaultPresets;
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final loaded = jsonList
          .map((item) => TimerPresetItem.fromJson(item as Map<String, dynamic>))
          .toList();
      if (loaded.isEmpty) {
        return TimerPresetItem.defaultPresets;
      }
      return loaded;
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao ler presets de timer: $e');
      return TimerPresetItem.defaultPresets;
    }
  }

  /// Salva os presets de temporizador
  static Future<void> saveTimerPresets(List<TimerPresetItem> presets) async {
    try {
      final file = await _getFile(_timerPresetsFileName);
      final jsonList = presets.map((p) => p.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList), flush: true);
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao salvar presets de timer: $e');
    }
  }

  /// Carrega as configurações de alarme (soneca, volume crescente, repetições)
  static Future<AlarmSettingsModel> loadAlarmSettings() async {
    try {
      final file = await _getFile(_alarmSettingsFileName);
      if (!await file.exists()) {
        return const AlarmSettingsModel();
      }
      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) {
        return const AlarmSettingsModel();
      }
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return AlarmSettingsModel.fromJson(data);
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao ler configurações de alarme: $e');
      return const AlarmSettingsModel();
    }
  }

  /// Salva as configurações de alarme
  static Future<void> saveAlarmSettings(AlarmSettingsModel settings) async {
    try {
      final file = await _getFile(_alarmSettingsFileName);
      await file.writeAsString(jsonEncode(settings.toJson()), flush: true);
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao salvar configurações de alarme: $e');
    }
  }

  /// Carrega o tema selecionado pelo usuário
  static Future<AppThemePalette> loadSavedTheme() async {
    try {
      final file = await _getFile(_themeFileName);
      if (!await file.exists()) {
        return AppThemePalette.amoledMonocromatico;
      }
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final themeId = data['themeId'] as String?;

      switch (themeId) {
        case 'carmim_pergaminho':
          return AppThemePalette.carmimPergaminho;
        case 'taiga_nordica':
          return AppThemePalette.taigaNordica;
        case 'brisa_costeira':
          return AppThemePalette.brisaCosteira;
        case 'crepusculo_rose':
          return AppThemePalette.crepusculoRose;
        case 'amoled_monocromatico':
          return AppThemePalette.amoledMonocromatico;
        case 'abismo_botanico':
          return AppThemePalette.abismoBotanico;
        case 'tundra_ardosia':
          return AppThemePalette.tundraArdosia;
        case 'brasa_ebano':
          return AppThemePalette.brasaEbano;
        case 'lava_grafite':
          return AppThemePalette.lavaGrafite;
        case 'nevoa_glacial':
          return AppThemePalette.nevoaGlacial;
        default:
          return AppThemePalette.amoledMonocromatico;
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao carregar tema: $e');
      return AppThemePalette.amoledMonocromatico;
    }
  }

  /// Persiste a escolha do tema do usuário
  static Future<void> saveTheme(AppThemePalette palette) async {
    try {
      final file = await _getFile(_themeFileName);
      final themeId = AppPalettes.getPalette(palette).id;
      await file.writeAsString(jsonEncode({'themeId': themeId}), flush: true);
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao salvar tema: $e');
    }
  }

  // ==========================================
  // HISTÓRICO DE HÁBITOS & CHECK-INS (OFFLINE)
  // ==========================================

  /// Carrega todos os registros de check-in salvos
  static Future<List<HabitCheckinModel>> loadCheckins() async {
    try {
      final file = await _getFile(_habitCheckinsFileName);
      if (!await file.exists()) {
        return [];
      }
      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => HabitCheckinModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao ler check-ins: $e');
      return [];
    }
  }

  /// Salva a lista de check-ins
  static Future<void> saveCheckins(List<HabitCheckinModel> checkins) async {
    try {
      final file = await _getFile(_habitCheckinsFileName);
      final jsonList = checkins.map((c) => c.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList), flush: true);
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao salvar check-ins: $e');
    }
  }

  /// Retorna os check-ins de uma rotina específica ordenados do mais recente para o mais antigo
  static Future<List<HabitCheckinModel>> getCheckinsForRoutine(int routineId) async {
    final all = await loadCheckins();
    final filtered = all.where((c) => c.routineId == routineId).toList();
    filtered.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return filtered;
  }

  /// Alterna o estado de conclusão do hábito hoje para a rotina informada.
  /// Retorna `true` se foi marcado como concluído, ou `false` se foi desmarcado.
  static Future<bool> toggleCheckinToday(int routineId) async {
    final all = await loadCheckins();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final existingIndex = all.indexWhere(
      (c) => c.routineId == routineId && c.dateKey == todayKey,
    );

    bool isNowCompleted = true;
    if (existingIndex >= 0) {
      final current = all[existingIndex];
      if (current.isCompleted) {
        // Desmarca
        all[existingIndex] = current.copyWith(
          isCompleted: false,
          completedAt: now,
        );
        isNowCompleted = false;
      } else {
        // Marca novamente
        all[existingIndex] = current.copyWith(
          isCompleted: true,
          completedAt: now,
        );
        isNowCompleted = true;
      }
    } else {
      // Cria novo registro concluído
      all.add(HabitCheckinModel(
        routineId: routineId,
        date: today,
        completedAt: now,
        isCompleted: true,
      ));
      isNowCompleted = true;
    }

    await saveCheckins(all);
    return isNowCompleted;
  }

  /// Obtém o sumário estatístico dos últimos 7 dias para a rotina
  static Future<HabitComplianceSummary> getComplianceSummary(int routineId) async {
    final checkins = await getCheckinsForRoutine(routineId);
    return HabitComplianceSummary.fromCheckins(
      routineId: routineId,
      checkins: checkins,
    );
  }
}

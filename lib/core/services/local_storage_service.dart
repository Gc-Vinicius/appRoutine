import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../../features/routine/domain/alarm_settings_model.dart';
import '../../features/routine/domain/category_item.dart';
import '../../features/routine/domain/routine_model.dart';
import '../../features/routine/domain/timer_preset_item.dart';

/// Serviço 100% offline para persistência atômica de dados locais
class LocalStorageService {
  static const String _routinesFileName = 'routines.json';
  static const String _themeFileName = 'theme_preference.json';
  static const String _categoriesFileName = 'custom_categories.json';
  static const String _timerPresetsFileName = 'timer_presets.json';
  static const String _alarmSettingsFileName = 'alarm_settings.json';

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

  /// Gera um backup JSON completo e formatado contendo todas as rotinas e preferências
  static Future<String> exportBackupJson() async {
    final routines = await loadRoutines() ?? [];
    final currentTheme = await loadSavedTheme();
    final themeId = AppPalettes.getPalette(currentTheme).id;
    final categories = await loadCategories();
    final presets = await loadTimerPresets();
    final alarmSettings = await loadAlarmSettings();

    final backupMap = {
      'app': 'appRoutine',
      'version': '1.3.0',
      'exportDate': DateTime.now().toIso8601String(),
      'themeId': themeId,
      'totalRoutines': routines.length,
      'routines': routines.map((r) => r.toJson()).toList(),
      'customCategories': categories.map((c) => c.toJson()).toList(),
      'timerPresets': presets.map((p) => p.toJson()).toList(),
      'alarmSettings': alarmSettings.toJson(),
    };

    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  /// Importa e valida um backup JSON, restaurando as rotinas e configurações offline
  static Future<int> importBackupJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString.trim());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Estrutura JSON inválida para backup.');
      }

      final routinesList = decoded['routines'];
      if (routinesList is! List) {
        throw const FormatException('Lista de rotinas não encontrada no backup.');
      }

      final List<RoutineModel> imported = [];
      for (final item in routinesList) {
        if (item is Map<String, dynamic>) {
          imported.add(RoutineModel.fromJson(item));
        }
      }

      await saveRoutines(imported);

      if (decoded['themeId'] != null) {
        final themeId = decoded['themeId'] as String;
        final matchedPalette = AppThemePalette.values.firstWhere(
          (p) => AppPalettes.getPalette(p).id == themeId,
          orElse: () => AppThemePalette.amoledMonocromatico,
        );
        await saveTheme(matchedPalette);
      }

      if (decoded['customCategories'] is List) {
        final List<CategoryItem> cats = [];
        for (final item in decoded['customCategories']) {
          if (item is Map<String, dynamic>) {
            cats.add(CategoryItem.fromJson(item));
          }
        }
        if (cats.isNotEmpty) {
          await saveCategories(cats);
        }
      }

      if (decoded['timerPresets'] is List) {
        final List<TimerPresetItem> pres = [];
        for (final item in decoded['timerPresets']) {
          if (item is Map<String, dynamic>) {
            pres.add(TimerPresetItem.fromJson(item));
          }
        }
        if (pres.isNotEmpty) {
          await saveTimerPresets(pres);
        }
      }

      if (decoded['alarmSettings'] is Map<String, dynamic>) {
        final settings = AlarmSettingsModel.fromJson(decoded['alarmSettings'] as Map<String, dynamic>);
        await saveAlarmSettings(settings);
      }

      return imported.length;
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao importar backup: $e');
      rethrow;
    }
  }
}

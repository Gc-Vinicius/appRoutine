import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../../features/routine/domain/routine_model.dart';

/// Serviço 100% offline para persistência atômica de dados locais
class LocalStorageService {
  static const String _routinesFileName = 'routines.json';
  static const String _themeFileName = 'theme_preference.json';

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

  /// Carrega o tema selecionado pelo usuário
  static Future<AppThemePalette> loadSavedTheme() async {
    try {
      final file = await _getFile(_themeFileName);
      if (!await file.exists()) {
        return AppThemePalette.taigaNordica;
      }
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final themeId = data['themeId'] as String?;

      switch (themeId) {
        case 'carmim_pergaminho':
          return AppThemePalette.carmimPergaminho;
        case 'brisa_costeira':
          return AppThemePalette.brisaCosteira;
        case 'taiga_nordica':
        default:
          return AppThemePalette.taigaNordica;
      }
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao carregar tema: $e');
      return AppThemePalette.taigaNordica;
    }
  }

  /// Persiste a escolha do tema do usuário
  static Future<void> saveTheme(AppThemePalette palette) async {
    try {
      final file = await _getFile(_themeFileName);
      String themeId;
      switch (palette) {
        case AppThemePalette.carmimPergaminho:
          themeId = 'carmim_pergaminho';
          break;
        case AppThemePalette.taigaNordica:
          themeId = 'taiga_nordica';
          break;
        case AppThemePalette.brisaCosteira:
          themeId = 'brisa_costeira';
          break;
      }
      await file.writeAsString(jsonEncode({'themeId': themeId}), flush: true);
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao salvar tema: $e');
    }
  }

  /// Gera um backup JSON completo e formatado contendo todas as rotinas e preferências
  static Future<String> exportBackupJson() async {
    final routines = await loadRoutines() ?? [];
    final currentTheme = await loadSavedTheme();
    String themeId = 'taiga_nordica';
    if (currentTheme == AppThemePalette.carmimPergaminho) {
      themeId = 'carmim_pergaminho';
    } else if (currentTheme == AppThemePalette.brisaCosteira) {
      themeId = 'brisa_costeira';
    }

    final backupMap = {
      'app': 'appRoutine',
      'version': '1.2.0',
      'exportDate': DateTime.now().toIso8601String(),
      'themeId': themeId,
      'totalRoutines': routines.length,
      'routines': routines.map((r) => r.toJson()).toList(),
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
        if (themeId == 'carmim_pergaminho') {
          await saveTheme(AppThemePalette.carmimPergaminho);
        } else if (themeId == 'brisa_costeira') {
          await saveTheme(AppThemePalette.brisaCosteira);
        } else {
          await saveTheme(AppThemePalette.taigaNordica);
        }
      }

      return imported.length;
    } catch (e) {
      debugPrint('[LocalStorageService] Erro ao importar backup: $e');
      rethrow;
    }
  }
}

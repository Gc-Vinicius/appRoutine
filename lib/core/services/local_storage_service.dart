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
}

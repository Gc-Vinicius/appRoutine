import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_colors.dart';
import '../services/local_storage_service.dart';

/// Provedor para injetar o tema inicial carregado do disco
final initialThemePaletteProvider = Provider<AppThemePalette>((ref) {
  return AppThemePalette.amoledMonocromatico;
});

/// Notifier para seleção e alternância dinâmica de temas com persistência local (RF07)
class ThemeNotifier extends StateNotifier<AppThemePalette> {
  ThemeNotifier(super.initial);

  Future<void> setPalette(AppThemePalette palette) async {
    state = palette;
    await LocalStorageService.saveTheme(palette);
  }

  Future<void> setPaletteById(String id) async {
    for (final palette in AppThemePalette.values) {
      if (AppPalettes.getPalette(palette).id == id) {
        await setPalette(palette);
        return;
      }
    }
  }

  AppPaletteData get currentPaletteData => AppPalettes.getPalette(state);
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemePalette>((ref) {
  final initial = ref.watch(initialThemePaletteProvider);
  return ThemeNotifier(initial);
});

/// Provedor reativo oficial de AppPaletteData que notifica os widgets quando o tema é alterado
final currentPaletteProvider = Provider<AppPaletteData>((ref) {
  final paletteEnum = ref.watch(themeProvider);
  return AppPalettes.getPalette(paletteEnum);
});

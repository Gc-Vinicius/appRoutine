import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_colors.dart';

/// Notifier para seleção e alternância dinâmica de temas (RF07)
class ThemeNotifier extends StateNotifier<AppThemePalette> {
  ThemeNotifier() : super(AppThemePalette.taigaNordica);

  void setPalette(AppThemePalette palette) {
    state = palette;
  }

  void setPaletteById(String id) {
    switch (id) {
      case 'carmim_pergaminho':
        state = AppThemePalette.carmimPergaminho;
        break;
      case 'taiga_nordica':
        state = AppThemePalette.taigaNordica;
        break;
      case 'brisa_costeira':
        state = AppThemePalette.brisaCosteira;
        break;
    }
  }

  AppPaletteData get currentPaletteData => AppPalettes.getPalette(state);
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemePalette>((ref) {
  return ThemeNotifier();
});

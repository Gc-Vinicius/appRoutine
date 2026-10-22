import 'package:flutter/material.dart';

/// Enumeração das 10 Paletas de Cores definidas em cores.md
enum AppThemePalette {
  carmimPergaminho,
  taigaNordica,
  brisaCosteira,
  crepusculoRose,
  amoledMonocromatico,
  abismoBotanico,
  tundraArdosia,
  brasaEbano,
  lavaGrafite,
  nevoaGlacial,
}

/// Extensão de Cores Customizadas para o Design System
class AppPaletteData {
  final String id;
  final String name;
  final String concept;
  final bool isDark;

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color primary;
  final Color secondary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color badgeBg;
  final Color badgeText;

  // Lista dos 5 Hexadecimais oficiais documentados em cores.md
  final List<String> swatchesHex;

  /// Cor de primeiro plano com contraste garantido sobre `primary` (ex: botões CTA, chips ativos, ícones de destaque)
  final Color? _onPrimary;

  Color get onPrimary {
    if (_onPrimary != null) return _onPrimary;
    if (id == 'amoled_monocromatico') return const Color(0xFF000000);
    if (id == 'carmim_pergaminho') return textPrimary;
    if (id == 'crepusculo_rose') return const Color(0xFF2F3559);
    if (id == 'tundra_ardosia') return const Color(0xFF12122B);
    return ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
        ? Colors.white
        : const Color(0xFF000000);
  }

  const AppPaletteData({
    required this.id,
    required this.name,
    required this.concept,
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.primary,
    required this.secondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.badgeBg,
    required this.badgeText,
    required this.swatchesHex,
    Color? onPrimary,
  }) : _onPrimary = onPrimary;
}

class AppPalettes {
  /// Paleta 1: Carmim & Pergaminho (Tema Escuro / Sofisticado / Dark Academia)
  static const carmimPergaminho = AppPaletteData(
    id: 'carmim_pergaminho',
    name: 'Carmim & Pergaminho',
    concept: 'Tema Escuro / Dark Academia & Sofisticado',
    isDark: true,
    background: Color(0xFF262525),
    surface: Color(0xFF525252),
    surfaceVariant: Color(0xFF383838),
    border: Color(0xFF666666),
    primary: Color(0xFF822626),
    secondary: Color(0xFF690202),
    textPrimary: Color(0xFFE6DDBC),
    textSecondary: Color(0xFFD6CCA9),
    textMuted: Color(0xFFA89F82),
    badgeBg: Color(0xFF690202),
    badgeText: Color(0xFFE6DDBC),
    onPrimary: Color(0xFFE6DDBC),
    swatchesHex: ['#262525', '#525252', '#E6DDBC', '#822626', '#690202'],
  );

  /// Paleta 2: Taiga Nórdica (Tema Escuro / Moderno & Tech)
  static const taigaNordica = AppPaletteData(
    id: 'taiga_nordica',
    name: 'Taiga Nórdica',
    concept: 'Tema Escuro / Moderno & Tech',
    isDark: true,
    background: Color(0xFF232226),
    surface: Color(0xFF253342),
    surfaceVariant: Color(0xFF1B2633),
    border: Color(0xFF3E5954),
    primary: Color(0xFF5E9188),
    secondary: Color(0xFF3E5954),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB5CCC9),
    textMuted: Color(0xFF7E9E9A),
    badgeBg: Color(0xFF3E5954),
    badgeText: Color(0xFFFFFFFF),
    onPrimary: Colors.white,
    swatchesHex: ['#232226', '#253342', '#3E5954', '#5E9188', '#FFFFFF'],
  );

  /// Paleta 3: Brisa Costeira (Tema Claro / Minimalista & Clean)
  static const brisaCosteira = AppPaletteData(
    id: 'brisa_costeira',
    name: 'Brisa Costeira',
    concept: 'Tema Claro / Minimalista & Clean',
    isDark: false,
    background: Color(0xFFEBE7E0),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF3EFE9),
    border: Color(0xFFBDB8AD),
    primary: Color(0xFF44749D),
    secondary: Color(0xFFC6D4E1),
    textPrimary: Color(0xFF1E293B),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
    badgeBg: Color(0xFFC6D4E1),
    badgeText: Color(0xFF1E3A5F),
    onPrimary: Colors.white,
    swatchesHex: ['#EBE7E0', '#FFFFFF', '#44749D', '#C6D4E1', '#BDB8AD'],
  );

  /// Paleta 4: Crepúsculo Rosé (Tema Escuro / Acolhedor & Bem-Estar)
  static const crepusculoRose = AppPaletteData(
    id: 'crepusculo_rose',
    name: 'Crepúsculo Rosé',
    concept: 'Tema Escuro / Acolhedor & Bem-Estar',
    isDark: true,
    background: Color(0xFF2F3559),
    surface: Color(0xFF9A5071),
    surfaceVariant: Color(0xFF483050),
    border: Color(0xFFB56586),
    primary: Color(0xFFE394A7),
    secondary: Color(0xFFF1BBBB),
    textPrimary: Color(0xFFE6D8CB),
    textSecondary: Color(0xFFD1BEB0),
    textMuted: Color(0xFFA89F82),
    badgeBg: Color(0xFF9A5071),
    badgeText: Color(0xFFE6D8CB),
    onPrimary: Color(0xFF2F3559),
    swatchesHex: ['#2F3559', '#9A5071', '#E394A7', '#F1BBBB', '#E6D8CB'],
  );

  /// Paleta 5: AMOLED Monocromático (Tema Ultra Escuro / Foco & Minimalismo)
  static const amoledMonocromatico = AppPaletteData(
    id: 'amoled_monocromatico',
    name: 'AMOLED Monocromático',
    concept: 'Tema Ultra Escuro / True Black & Foco',
    isDark: true,
    background: Color(0xFF000000),
    surface: Color(0xFF1A1A1A),
    surfaceVariant: Color(0xFF121212),
    border: Color(0xFF343434),
    primary: Color(0xFFFFFFFF),
    secondary: Color(0xFF4F4E4E),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFCCCCCC),
    textMuted: Color(0xFF696868),
    badgeBg: Color(0xFF343434),
    badgeText: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF000000),
    swatchesHex: ['#000000', '#1A1A1A', '#343434', '#4F4E4E', '#696868'],
  );

  /// Paleta 6: Abismo Botânico (Tema Escuro / Profundidade & Acento Cítrico)
  static const abismoBotanico = AppPaletteData(
    id: 'abismo_botanico',
    name: 'Abismo Botânico',
    concept: 'Tema Escuro / Profundidade & Acento Cítrico',
    isDark: true,
    background: Color(0xFF142026),
    surface: Color(0xFF123142),
    surfaceVariant: Color(0xFF0D181D),
    border: Color(0xFF2A4B5E),
    primary: Color(0xFF3B657A),
    secondary: Color(0xFF20130A),
    textPrimary: Color(0xFFE9F0C9),
    textSecondary: Color(0xFFCBD2A7),
    textMuted: Color(0xFF8E9570),
    badgeBg: Color(0xFF3B657A),
    badgeText: Color(0xFFE9F0C9),
    onPrimary: Colors.white,
    swatchesHex: ['#142026', '#123142', '#20130A', '#3B657A', '#E9F0C9'],
  );

  /// Paleta 7: Tundra & Ardósia (Tema Escuro Mineral / Técnico & Discreto)
  static const tundraArdosia = AppPaletteData(
    id: 'tundra_ardosia',
    name: 'Tundra & Ardósia',
    concept: 'Tema Escuro Mineral / Técnico & Discreto',
    isDark: true,
    background: Color(0xFF12122B),
    surface: Color(0xFF383845),
    surfaceVariant: Color(0xFF212133),
    border: Color(0xFF5E5E5E),
    primary: Color(0xFFAAAA91),
    secondary: Color(0xFF848478),
    textPrimary: Color(0xFFAAAA91),
    textSecondary: Color(0xFF848478),
    textMuted: Color(0xFF5E5E5E),
    badgeBg: Color(0xFF383845),
    badgeText: Color(0xFFAAAA91),
    onPrimary: Color(0xFF12122B),
    swatchesHex: ['#12122B', '#383845', '#5E5E5E', '#848478', '#AAAA91'],
  );

  /// Paleta 8: Brasa & Ébano (Tema Noturno / Alta Intensidade & Alerta)
  static const brasaEbano = AppPaletteData(
    id: 'brasa_ebano',
    name: 'Brasa & Ébano',
    concept: 'Tema Noturno / Alta Intensidade & Alerta',
    isDark: true,
    background: Color(0xFF1A2B2B),
    surface: Color(0xFF332222),
    surfaceVariant: Color(0xFF261919),
    border: Color(0xFF4D1A1A),
    primary: Color(0xFF800909),
    secondary: Color(0xFF661111),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFE0C0C0),
    textMuted: Color(0xFFA08080),
    badgeBg: Color(0xFF661111),
    badgeText: Color(0xFFFFFFFF),
    onPrimary: Colors.white,
    swatchesHex: ['#1A2B2B', '#332222', '#4D1A1A', '#661111', '#800909'],
  );

  /// Paleta 9: Lava & Grafite (Tema Escuro Esportivo / Alta Performance & Energia)
  static const lavaGrafite = AppPaletteData(
    id: 'lava_grafite',
    name: 'Lava & Grafite',
    concept: 'Tema Escuro Esportivo / Alta Performance',
    isDark: true,
    background: Color(0xFF221D21),
    surface: Color(0xFF433D3D),
    surfaceVariant: Color(0xFF302B2F),
    border: Color(0xFF5A5252),
    primary: Color(0xFFF77014),
    secondary: Color(0xFFE33C08),
    textPrimary: Color(0xFFB7AEA5),
    textSecondary: Color(0xFF9E958C),
    textMuted: Color(0xFF756C64),
    badgeBg: Color(0xFFE33C08),
    badgeText: Color(0xFFFFFFFF),
    onPrimary: Colors.white,
    swatchesHex: ['#221D21', '#433D3D', '#B7AEA5', '#F77014', '#E33C08'],
  );

  /// Paleta 10: Névoa Glacial (Tema Claro Zen / Minimalista & Foco Calmo)
  static const nevoaGlacial = AppPaletteData(
    id: 'nevoa_glacial',
    name: 'Névoa Glacial',
    concept: 'Tema Claro Zen / Minimalista & Foco Calmo',
    isDark: false,
    background: Color(0xFFE6E8E3),
    surface: Color(0xFFD7DACF),
    surfaceVariant: Color(0xFFCBD0C2),
    border: Color(0xFFBEC3BC),
    primary: Color(0xFF65727A),
    secondary: Color(0xFF8F9A9C),
    textPrimary: Color(0xFF2B3338),
    textSecondary: Color(0xFF4F5960),
    textMuted: Color(0xFF707C84),
    badgeBg: Color(0xFFBEC3BC),
    badgeText: Color(0xFF2B3338),
    onPrimary: Colors.white,
    swatchesHex: ['#E6E8E3', '#D7DACF', '#BEC3BC', '#8F9A9C', '#65727A'],
  );

  static AppPaletteData getPalette(AppThemePalette palette) {
    switch (palette) {
      case AppThemePalette.carmimPergaminho:
        return carmimPergaminho;
      case AppThemePalette.taigaNordica:
        return taigaNordica;
      case AppThemePalette.brisaCosteira:
        return brisaCosteira;
      case AppThemePalette.crepusculoRose:
        return crepusculoRose;
      case AppThemePalette.amoledMonocromatico:
        return amoledMonocromatico;
      case AppThemePalette.abismoBotanico:
        return abismoBotanico;
      case AppThemePalette.tundraArdosia:
        return tundraArdosia;
      case AppThemePalette.brasaEbano:
        return brasaEbano;
      case AppThemePalette.lavaGrafite:
        return lavaGrafite;
      case AppThemePalette.nevoaGlacial:
        return nevoaGlacial;
    }
  }

  static const List<AppPaletteData> allPalettes = [
    carmimPergaminho,
    taigaNordica,
    brisaCosteira,
    crepusculoRose,
    amoledMonocromatico,
    abismoBotanico,
    tundraArdosia,
    brasaEbano,
    lavaGrafite,
    nevoaGlacial,
  ];
}

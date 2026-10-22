import 'package:flutter/material.dart';

/// Enumeração das Paletas de Cores definidas em cores.md (RF07)
enum AppThemePalette {
  carmimPergaminho,
  taigaNordica,
  brisaCosteira,
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
  });
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
    swatchesHex: ['#EBE7E0', '#FFFFFF', '#44749D', '#C6D4E1', '#BDB8AD'],
  );

  static AppPaletteData getPalette(AppThemePalette palette) {
    switch (palette) {
      case AppThemePalette.carmimPergaminho:
        return carmimPergaminho;
      case AppThemePalette.taigaNordica:
        return taigaNordica;
      case AppThemePalette.brisaCosteira:
        return brisaCosteira;
    }
  }
}

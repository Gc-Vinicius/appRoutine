import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Fábrica do ThemeData do Flutter aderente ao Material 3 e aos requisitos do app
class AppTheme {
  static ThemeData buildTheme(AppThemePalette paletteEnum) {
    final palette = AppPalettes.getPalette(paletteEnum);
    final isDark = palette.isDark;

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: palette.primary,
            secondary: palette.secondary,
            surface: palette.surface,
            onPrimary: palette.id == 'carmim_pergaminho' ? palette.textPrimary : Colors.white,
            onSecondary: palette.textPrimary,
            onSurface: palette.textPrimary,
            outline: palette.border,
          )
        : ColorScheme.light(
            primary: palette.primary,
            secondary: palette.secondary,
            surface: palette.surface,
            onPrimary: Colors.white,
            onSecondary: palette.textPrimary,
            onSurface: palette.textPrimary,
            outline: palette.border,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,

      // Barra de Aplicativo (AppBar)
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: palette.textPrimary),
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Botão Flutuante (FAB)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.primary,
        foregroundColor: (isDark && palette.id == 'carmim_pergaminho') ? palette.textPrimary : Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),

      // Switches (Ativos e Desativados)
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return (isDark && palette.id == 'carmim_pergaminho') ? palette.textPrimary : Colors.white;
          }
          return palette.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary;
          }
          return palette.surfaceVariant;
        }),
        trackOutlineColor: WidgetStateProperty.all(palette.border),
      ),

      // Inputs de Texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 1.8),
        ),
        hintStyle: TextStyle(color: palette.textMuted, fontSize: 13),
        labelStyle: TextStyle(color: palette.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
      ),

      // Botões Elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: (isDark && palette.id == 'carmim_pergaminho') ? palette.textPrimary : Colors.white,
          minimumSize: const Size(64, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          elevation: 0,
        ),
      ),

      // Diálogos e Modais
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: palette.textSecondary,
          fontSize: 14,
        ),
      ),

      // Seletor de Horário (TimePicker)
      timePickerTheme: TimePickerThemeData(
        backgroundColor: palette.surface,
        hourMinuteColor: palette.surfaceVariant,
        hourMinuteTextColor: palette.textPrimary,
        dialHandColor: palette.primary,
        dialBackgroundColor: palette.surfaceVariant,
        dialTextColor: palette.textPrimary,
        entryModeIconColor: palette.primary,
      ),

      // Seletor de Data (DatePicker)
      datePickerTheme: DatePickerThemeData(
        backgroundColor: palette.surface,
        headerBackgroundColor: palette.surface,
        headerForegroundColor: palette.textPrimary,
        todayForegroundColor: WidgetStateProperty.all(palette.primary),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return (isDark && palette.id == 'carmim_pergaminho') ? palette.textPrimary : Colors.white;
          }
          return palette.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary;
          }
          return null;
        }),
      ),

      // Tipografia
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        titleMedium: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
        bodyLarge: TextStyle(color: palette.textPrimary, fontSize: 14),
        bodyMedium: TextStyle(color: palette.textSecondary, fontSize: 13),
        bodySmall: TextStyle(color: palette.textMuted, fontSize: 11),
      ),
    );
  }
}

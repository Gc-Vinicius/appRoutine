import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_routine/features/routine/domain/category_item.dart';
import 'package:app_routine/features/routine/domain/routine_model.dart';
import 'package:app_routine/features/routine/domain/timer_preset_item.dart';
import 'package:app_routine/core/theme/app_colors.dart';
import 'package:app_routine/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('RoutineModel Tests', () {
    test('RoutineModel serialization and deserialization with Category and SkippedUntil', () {
      final routine = RoutineModel(
        id: 42,
        title: 'Beber Água',
        body: '300ml de água mineral',
        type: RoutineType.recurring,
        category: RoutineCategory.water,
        customCategoryName: null,
        customCategoryEmoji: null,
        hour: 9,
        minute: 15,
        weekdays: [1, 3, 5],
        skippedUntil: DateTime(2026, 10, 23, 9, 16),
        isActive: true,
        createdAt: DateTime(2026, 10, 22, 9, 0),
      );

      final json = routine.toJson();
      final fromJson = RoutineModel.fromJson(json);

      expect(fromJson.id, equals(42));
      expect(fromJson.title, equals('Beber Água'));
      expect(fromJson.body, equals('300ml de água mineral'));
      expect(fromJson.type, equals(RoutineType.recurring));
      expect(fromJson.category, equals(RoutineCategory.water));
      expect(fromJson.displayCategoryEmoji, equals('💧'));
      expect(fromJson.displayCategoryName, equals('Hidratação'));
      expect(fromJson.hour, equals(9));
      expect(fromJson.minute, equals(15));
      expect(fromJson.weekdays, equals([1, 3, 5]));
      expect(fromJson.skippedUntil, isNotNull);
      expect(fromJson.isActive, isTrue);
    });

    test('RoutineModel with custom category overrides displayCategory getters', () {
      final routine = RoutineModel(
        id: 99,
        title: 'Estudar Flutter',
        body: 'Revisar Riverpod e SQLite',
        type: RoutineType.recurring,
        category: RoutineCategory.general,
        customCategoryName: 'Programação',
        customCategoryEmoji: '💻',
        hour: 14,
        minute: 0,
        weekdays: [1, 2, 3, 4, 5],
        createdAt: DateTime.now(),
      );

      final json = routine.toJson();
      final fromJson = RoutineModel.fromJson(json);

      expect(fromJson.customCategoryName, equals('Programação'));
      expect(fromJson.customCategoryEmoji, equals('💻'));
      expect(fromJson.displayCategoryName, equals('Programação'));
      expect(fromJson.displayCategoryEmoji, equals('💻'));
    });

    test('RoutineModel copyWith updates fields properly', () {
      final routine = RoutineModel(
        id: 1,
        title: 'Original',
        body: 'Corpo original',
        type: RoutineType.punctual,
        category: RoutineCategory.health,
        hour: 10,
        minute: 0,
        createdAt: DateTime.now(),
      );

      final updated = routine.copyWith(
        title: 'Título Editado',
        category: RoutineCategory.workout,
        minute: 30,
        isActive: false,
      );

      expect(updated.id, equals(1));
      expect(updated.title, equals('Título Editado'));
      expect(updated.category, equals(RoutineCategory.workout));
      expect(updated.displayCategoryEmoji, equals('🏋️'));
      expect(updated.minute, equals(30));
      expect(updated.hour, equals(10));
      expect(updated.isActive, isFalse);
    });

    test('RoutineModel calculates timeUntilNextFormatted and skip state', () {
      final now = DateTime.now();
      // Alarme para daqui a 2 horas hoje
      final routine = RoutineModel(
        id: 10,
        title: 'Treino',
        body: 'Musculação',
        type: RoutineType.punctual,
        hour: (now.hour + 2) % 24,
        minute: now.minute,
        punctualDate: now.add(const Duration(hours: 2)),
        isActive: true,
        createdAt: now,
      );

      expect(routine.isCurrentlySkipped, isFalse);
      expect(routine.timeUntilNextFormatted, contains('Toca em'));

      // Agora com skippedUntil no futuro
      final skippedRoutine = routine.copyWith(
        skippedUntil: now.add(const Duration(hours: 3)),
      );
      expect(skippedRoutine.isCurrentlySkipped, isTrue);
      expect(skippedRoutine.timeUntilNextFormatted, equals('Próximo disparo pausado'));
    });
  });

  group('Domain Items Tests', () {
    test('CategoryItem defaults are populated', () {
      final defaults = CategoryItem.defaultCategories;
      expect(defaults.length, greaterThanOrEqualTo(5));
      expect(defaults.any((c) => c.name == 'Geral'), isTrue);
    });

    test('TimerPresetItem defaults are reduced to 3 presets', () {
      final defaults = TimerPresetItem.defaultPresets;
      expect(defaults.length, equals(3));
      expect(defaults.map((p) => p.name).toList(), equals(['5 min', '10 min', '25m (Pomodoro)']));
    });
  });

  group('Theme System Tests', () {
    test('Theme system contains 10 official palettes from cores.md', () {
      expect(AppPalettes.allPalettes.length, equals(10));
      final ids = AppPalettes.allPalettes.map((p) => p.id).toList();
      expect(ids, contains('carmim_pergaminho'));
      expect(ids, contains('taiga_nordica'));
      expect(ids, contains('brisa_costeira'));
      expect(ids, contains('crepusculo_rose'));
      expect(ids, contains('amoled_monocromatico'));
      expect(ids, contains('abismo_botanico'));
      expect(ids, contains('tundra_ardosia'));
      expect(ids, contains('brasa_ebano'));
      expect(ids, contains('lava_grafite'));
      expect(ids, contains('nevoa_glacial'));
    });

    test('ThemeNotifier transitions between palettes correctly', () {
      final notifier = ThemeNotifier(AppThemePalette.taigaNordica);
      expect(notifier.state, equals(AppThemePalette.taigaNordica));
      expect(notifier.currentPaletteData.id, equals('taiga_nordica'));

      notifier.setPaletteById('carmim_pergaminho');
      expect(notifier.state, equals(AppThemePalette.carmimPergaminho));
      expect(notifier.currentPaletteData.id, equals('carmim_pergaminho'));
      expect(notifier.currentPaletteData.background, equals(const Color(0xFF262525)));

      notifier.setPaletteById('brisa_costeira');
      expect(notifier.state, equals(AppThemePalette.brisaCosteira));
      expect(notifier.currentPaletteData.id, equals('brisa_costeira'));
      expect(notifier.currentPaletteData.background, equals(const Color(0xFFEBE7E0)));

      notifier.setPaletteById('amoled_monocromatico');
      expect(notifier.state, equals(AppThemePalette.amoledMonocromatico));
      expect(notifier.currentPaletteData.id, equals('amoled_monocromatico'));
    });
  });
}

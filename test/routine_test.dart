import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_routine/features/routine/domain/routine_model.dart';
import 'package:app_routine/core/theme/app_colors.dart';
import 'package:app_routine/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('RoutineModel Tests', () {
    test('RoutineModel serialization and deserialization', () {
      final routine = RoutineModel(
        id: 42,
        title: 'Beber Água',
        body: '300ml de água mineral',
        type: RoutineType.recurring,
        hour: 9,
        minute: 15,
        weekdays: [1, 3, 5],
        isActive: true,
        createdAt: DateTime(2026, 10, 22, 9, 0),
      );

      final json = routine.toJson();
      final fromJson = RoutineModel.fromJson(json);

      expect(fromJson.id, equals(42));
      expect(fromJson.title, equals('Beber Água'));
      expect(fromJson.body, equals('300ml de água mineral'));
      expect(fromJson.type, equals(RoutineType.recurring));
      expect(fromJson.hour, equals(9));
      expect(fromJson.minute, equals(15));
      expect(fromJson.weekdays, equals([1, 3, 5]));
      expect(fromJson.isActive, isTrue);
    });

    test('RoutineModel copyWith updates fields properly', () {
      final routine = RoutineModel(
        id: 1,
        title: 'Original',
        body: 'Corpo original',
        type: RoutineType.punctual,
        hour: 10,
        minute: 0,
        createdAt: DateTime.now(),
      );

      final updated = routine.copyWith(
        title: 'Título Editado',
        minute: 30,
        isActive: false,
      );

      expect(updated.id, equals(1));
      expect(updated.title, equals('Título Editado'));
      expect(updated.minute, equals(30));
      expect(updated.hour, equals(10));
      expect(updated.isActive, isFalse);
    });
  });

  group('Theme System Tests', () {
    test('ThemeNotifier transitions between 3 official palettes correctly', () {
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
    });

    test('All 3 palettes have matching 5 official swatches from cores.md', () {
      const carmim = AppPalettes.carmimPergaminho;
      expect(carmim.swatchesHex, equals(['#262525', '#525252', '#E6DDBC', '#822626', '#690202']));

      const taiga = AppPalettes.taigaNordica;
      expect(taiga.swatchesHex, equals(['#232226', '#253342', '#3E5954', '#5E9188', '#FFFFFF']));

      const brisa = AppPalettes.brisaCosteira;
      expect(brisa.swatchesHex, equals(['#EBE7E0', '#FFFFFF', '#44749D', '#C6D4E1', '#BDB8AD']));
    });
  });
}

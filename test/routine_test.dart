import 'package:app_routine/core/config/supabase_config.dart';
import 'package:app_routine/core/services/supabase_service.dart';
import 'package:app_routine/core/services/supabase_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_routine/features/routine/domain/alarm_settings_model.dart';
import 'package:app_routine/features/routine/domain/category_item.dart';
import 'package:app_routine/features/routine/domain/habit_checkin_model.dart';
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

    test('Diferenciação clara entre Alarme (celular) e Lembrete (smartwatch)', () {
      final now = DateTime.now();
      final alarme = RoutineModel(
        id: 101,
        title: 'Despertar',
        body: 'Acordar para trabalhar',
        type: RoutineType.punctual,
        hour: (now.hour + 1) % 24,
        minute: now.minute,
        isAlarm: true,
        punctualDate: now.add(const Duration(hours: 1)),
        createdAt: now,
      );

      final lembrete = RoutineModel(
        id: 102,
        title: 'Beber Água',
        body: 'Hidratação rápida',
        type: RoutineType.punctual,
        hour: (now.hour + 1) % 24,
        minute: now.minute,
        isAlarm: false,
        punctualDate: now.add(const Duration(hours: 1)),
        createdAt: now,
      );

      expect(alarme.isAlarm, isTrue);
      expect(alarme.isReminder, isFalse);
      expect(alarme.alertTypeLabel, equals('Alarme'));
      expect(alarme.timeUntilNextFormatted, contains('Toca em'));

      expect(lembrete.isAlarm, isFalse);
      expect(lembrete.isReminder, isTrue);
      expect(lembrete.alertTypeLabel, equals('Lembrete'));
      expect(lembrete.timeUntilNextFormatted, contains('Notifica em'));

      // Teste de desativação
      final lembreteInativo = lembrete.copyWith(isActive: false);
      expect(lembreteInativo.timeUntilNextFormatted, equals('Lembrete desativado'));

      final alarmeInativo = alarme.copyWith(isActive: false);
      expect(alarmeInativo.timeUntilNextFormatted, equals('Alarme desativado'));

      // Teste de desserialização a partir do formato do Supabase (is_alarm)
      final jsonSupabase = {
        'id': 200,
        'title': 'Remédio',
        'body': 'Vitamina C',
        'type': 'recurring',
        'category': 'health',
        'hour': 8,
        'minute': 0,
        'weekdays': [1, 2],
        'is_alarm': false,
        'is_active': true,
      };
      final parsed = RoutineModel.fromJson(jsonSupabase);
      expect(parsed.isAlarm, isFalse);
      expect(parsed.isReminder, isTrue);
      expect(parsed.alertTypeLabel, equals('Lembrete'));
    });

    test('Lembretes de visualização única (isOneShot) - modelo, serialização e getters', () {
      final now = DateTime.now();
      final oneShotReminder = RoutineModel(
        id: 301,
        title: 'Comprar Pão',
        body: 'Passar na padaria na volta',
        type: RoutineType.punctual,
        hour: (now.hour + 1) % 24,
        minute: now.minute,
        isAlarm: false,
        isOneShot: true,
        punctualDate: now.add(const Duration(hours: 1)),
        createdAt: now,
      );

      expect(oneShotReminder.isAlarm, isFalse);
      expect(oneShotReminder.isReminder, isTrue);
      expect(oneShotReminder.isOneShot, isTrue);
      expect(oneShotReminder.isOneShotReminder, isTrue);
      expect(oneShotReminder.hasPassed, isFalse);
      expect(oneShotReminder.typeLabel, equals('PONTUAL • USO ÚNICO'));
      expect(oneShotReminder.recurrenceSubtitle, contains('(Uso único)'));

      // Teste de serialização toJson e fromJson
      final json = oneShotReminder.toJson();
      expect(json['isOneShot'], isTrue);
      expect(json['isAlarm'], isFalse);

      final fromJson = RoutineModel.fromJson(json);
      expect(fromJson.isOneShot, isTrue);
      expect(fromJson.isOneShotReminder, isTrue);

      // Teste com formato do Supabase (is_one_shot)
      final supabaseJson = {
        'id': 302,
        'title': 'Recado Rápido',
        'body': 'Mensagem temporária',
        'type': 'punctual',
        'category': 'general',
        'hour': 12,
        'minute': 0,
        'is_alarm': false,
        'is_one_shot': true,
        'is_active': true,
      };
      final parsedSupabase = RoutineModel.fromJson(supabaseJson);
      expect(parsedSupabase.isOneShot, isTrue);
      expect(parsedSupabase.isOneShotReminder, isTrue);

      // Se for Alarme com isOneShot marcado, isOneShotReminder deve ser falso (exclusivo para lembretes)
      final oneShotAlarm = oneShotReminder.copyWith(isAlarm: true);
      expect(oneShotAlarm.isOneShotReminder, isFalse);

      // Teste do hasPassed para datas que já passaram
      final pastReminder = oneShotReminder.copyWith(
        punctualDate: now.subtract(const Duration(minutes: 5)),
      );
      expect(pastReminder.hasPassed, isTrue);
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

    test('AMOLED Monocromático and all palettes have valid onPrimary contrast', () {
      const amoled = AppPalettes.amoledMonocromatico;
      expect(amoled.primary, equals(const Color(0xFFFFFFFF)));
      expect(amoled.onPrimary, equals(const Color(0xFF000000)));

      // Todas as paletas devem possuir onPrimary distinto de primary
      for (final p in AppPalettes.allPalettes) {
        expect(p.primary, isNot(equals(p.onPrimary)),
            reason: 'Paleta ${p.id} não pode ter primary e onPrimary com mesma cor');
      }
    });
  });

  group('AlarmSettingsModel Tests', () {
    test('AlarmSettingsModel default values', () {
      const settings = AlarmSettingsModel();
      expect(settings.snoozeDurationMinutes, equals(10));
      expect(settings.maxSnoozeCount, equals(3));
      expect(settings.crescendoVolume, isTrue);
      expect(settings.crescendoDurationSeconds, equals(30));
    });

    test('AlarmSettingsModel copyWith and JSON serialization', () {
      const settings = AlarmSettingsModel();
      final updated = settings.copyWith(
        snoozeDurationMinutes: 15,
        maxSnoozeCount: 2,
        crescendoVolume: false,
      );

      final json = updated.toJson();
      final fromJson = AlarmSettingsModel.fromJson(json);

      expect(fromJson.snoozeDurationMinutes, equals(15));
      expect(fromJson.maxSnoozeCount, equals(2));
      expect(fromJson.crescendoVolume, isFalse);
      expect(fromJson.crescendoDurationSeconds, equals(30));
    });
  });

  group('HabitCheckinModel & Habits Tests', () {
    test('HabitCheckinModel serialization and helpers', () {
      final now = DateTime.now();
      final checkin = HabitCheckinModel(
        routineId: 77,
        date: DateTime(now.year, now.month, now.day),
        completedAt: now,
        isCompleted: true,
      );

      final json = checkin.toJson();
      final fromJson = HabitCheckinModel.fromJson(json);

      expect(fromJson.routineId, equals(77));
      expect(fromJson.isToday, isTrue);
      expect(fromJson.isCompleted, isTrue);
      expect(fromJson.dateKey, equals(checkin.dateKey));
    });

    test('HabitComplianceSummary calculates correct ratio, percentage and 7 days list', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check-ins para hoje, ontem e anteontem
      final checkins = [
        HabitCheckinModel(
          routineId: 1,
          date: today,
          completedAt: now,
          isCompleted: true,
        ),
        HabitCheckinModel(
          routineId: 1,
          date: today.subtract(const Duration(days: 1)),
          completedAt: now.subtract(const Duration(days: 1)),
          isCompleted: true,
        ),
        HabitCheckinModel(
          routineId: 1,
          date: today.subtract(const Duration(days: 2)),
          completedAt: now.subtract(const Duration(days: 2)),
          isCompleted: true,
        ),
      ];

      final summary = HabitComplianceSummary.fromCheckins(
        routineId: 1,
        checkins: checkins,
      );

      expect(summary.routineId, equals(1));
      expect(summary.totalDaysLast7, equals(7));
      expect(summary.completedDaysLast7, equals(3));
      expect(summary.formattedRatio, equals('3 de 7 dias'));
      expect(summary.formattedPercentage, equals('43%'));
      expect(summary.isCompletedToday, isTrue);
      expect(summary.currentStreak, equals(3));
      expect(summary.last7Days.length, equals(7));
    });

    test('HabitComplianceSummary calculates streak when today is not yet completed', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check-ins para ontem e anteontem (hoje ainda não feito)
      final checkins = [
        HabitCheckinModel(
          routineId: 1,
          date: today.subtract(const Duration(days: 1)),
          completedAt: now.subtract(const Duration(days: 1)),
          isCompleted: true,
        ),
        HabitCheckinModel(
          routineId: 1,
          date: today.subtract(const Duration(days: 2)),
          completedAt: now.subtract(const Duration(days: 2)),
          isCompleted: true,
        ),
      ];

      final summary = HabitComplianceSummary.fromCheckins(
        routineId: 1,
        checkins: checkins,
      );

      expect(summary.isCompletedToday, isFalse);
      expect(summary.completedDaysLast7, equals(2));
      // Streak continua vivo de ontem: 2 dias
      expect(summary.currentStreak, equals(2));
    });
  });

  group('Time Wheel & Clock Tests', () {
    test('Modulo logic correctly loops backwards from 0 to 23 and 59', () {
      expect((-1 % 24 + 24) % 24, equals(23));
      expect((-2 % 24 + 24) % 24, equals(22));
      expect((-1 % 60 + 60) % 60, equals(59));
      expect((-2 % 60 + 60) % 60, equals(58));
      expect((60 % 60 + 60) % 60, equals(0));
      expect((24 % 24 + 24) % 24, equals(0));
    });
  });

  group('Supabase Integration & Models Tests', () {
    test('UserProfile serialization and deserialization', () {
      final profile = UserProfile.fromMap({
        'id': 'usr-123',
        'nome': 'João Silva',
        'foto_url': 'https://example.com/avatar.jpg',
      });

      expect(profile.id, equals('usr-123'));
      expect(profile.nome, equals('João Silva'));
      expect(profile.fotoUrl, equals('https://example.com/avatar.jpg'));

      final map = profile.toMap();
      expect(map['id'], equals('usr-123'));
      expect(map['nome'], equals('João Silva'));
      expect(map['foto_url'], equals('https://example.com/avatar.jpg'));
    });

    test('UserProfile fallback when nome is missing', () {
      final profile = UserProfile.fromMap({'id': 'usr-456'});
      expect(profile.id, equals('usr-456'));
      expect(profile.nome, equals('Usuário'));
      expect(profile.fotoUrl, isNull);
    });

    test('SyncResult holds properties correctly', () {
      const res = SyncResult(
        success: true,
        message: 'Sync concluído com sucesso',
        routinesSynced: 5,
        checkinsSynced: 12,
      );
      expect(res.success, isTrue);
      expect(res.routinesSynced, equals(5));
      expect(res.checkinsSynced, equals(12));
    });

    test('SupabaseConfig has valid defaults', () {
      expect(SupabaseConfig.supabaseUrl, isNotEmpty);
      expect(SupabaseConfig.supabasePublishableKey, isNotEmpty);
      expect(SupabaseConfig.avatarsBucket, equals('avatars'));
    });
  });
}
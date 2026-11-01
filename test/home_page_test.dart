import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_routine/core/theme/app_colors.dart';
import 'package:app_routine/features/routine/domain/routine_model.dart';
import 'package:app_routine/features/routine/presentation/widgets/home_hero_card.dart';
import 'package:app_routine/features/routine/presentation/widgets/home_metrics_dashboard.dart';
import 'package:app_routine/features/routine/presentation/widgets/today_timeline_list.dart';
import 'package:app_routine/features/routine/presentation/widgets/floating_nav_dock.dart';

void main() {
  const palette = AppPalettes.amoledMonocromatico;

  group('Home Page Components Unit & Widget Tests', () {
    testWidgets('HomeHeroCard displays routine title, countdown, and action buttons', (tester) async {
      final now = DateTime.now();
      final routine = RoutineModel(
        id: 101,
        title: 'Treino Noturno & Alongamento',
        body: 'Treino de mobilidade e relaxamento',
        type: RoutineType.recurring,
        hour: (now.hour + 1) % 24,
        minute: now.minute,
        weekdays: [now.weekday],
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HomeHeroCard(
                routine: routine,
                palette: palette,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Treino Noturno & Alongamento'), findsOneWidget);
      expect(find.text('Concluir Hoje'), findsOneWidget);
      expect(find.text('Adiar 10m'), findsOneWidget);
    });

    testWidgets('HomeMetricsDashboard calculates and displays metrics properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeMetricsDashboard(
              palette: palette,
              completedToday: 4,
              totalToday: 6,
              currentStreak: 12,
              recordStreak: 18,
              focusTimeFormatted: '1h 45m',
              focusMetaFormatted: 'Meta: 2h/dia',
            ),
          ),
        ),
      );

      expect(find.text('PROGRESSO'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
      expect(find.text('4 de 6 feitas'), findsOneWidget);

      expect(find.text('OFENSIVA'), findsOneWidget);
      expect(find.text('12 Dias'), findsOneWidget);
      expect(find.text('Recorde: 18d'), findsOneWidget);

      expect(find.text('TEMPO FOCO'), findsOneWidget);
      expect(find.text('1h 45m'), findsOneWidget);
      expect(find.text('Meta: 2h/dia'), findsOneWidget);
    });

    testWidgets('TodayTimelineList displays today routines with status indicators', (tester) async {
      final routine1 = RoutineModel(
        id: 1,
        title: 'Despertar & Água Gelada',
        body: 'Hábito matinal',
        type: RoutineType.recurring,
        hour: 7,
        minute: 0,
        createdAt: DateTime.now(),
      );
      final routine2 = RoutineModel(
        id: 2,
        title: 'Treino Noturno',
        body: 'Treino da noite',
        type: RoutineType.recurring,
        hour: 21,
        minute: 30,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TodayTimelineList(
                todayRoutines: [routine1, routine2],
                nextRoutine: routine2,
                palette: palette,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Rotinas de Hoje'), findsOneWidget);
      expect(find.text('07:00 • Despertar & Água Gelada'), findsOneWidget);
      expect(find.text('21:30 • Treino Noturno'), findsOneWidget);
      expect(find.text('A Seguir'), findsOneWidget);
    });

    testWidgets('FloatingNavDock handles tab selection and FAB trigger', (tester) async {
      int selectedIndex = 0;
      bool fabClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloatingNavDock(
              currentIndex: selectedIndex,
              onIndexChanged: (idx) => selectedIndex = idx,
              onAddPressed: () => fabClicked = true,
              palette: palette,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Rotinas'), findsOneWidget);
      expect(find.text('Timer'), findsOneWidget);
      expect(find.text('Sono'), findsOneWidget);

      // Tap on Rotinas
      await tester.tap(find.text('Rotinas'));
      expect(selectedIndex, 1);

      // Tap on FAB (+)
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(fabClicked, true);
    });
  });
}

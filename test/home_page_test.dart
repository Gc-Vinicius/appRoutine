import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_routine/core/theme/app_colors.dart';
import 'package:app_routine/features/routine/domain/routine_model.dart';
import 'package:app_routine/features/routine/presentation/screens/calendar_screen.dart';
import 'package:app_routine/features/routine/presentation/screens/home_screen.dart';
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

    testWidgets('HomeMetricsDashboard calculates and displays metrics properly with dynamic fallbacks', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeMetricsDashboard(
              palette: palette,
              completedToday: 0,
              totalToday: 0,
              currentStreak: 0,
              recordStreak: 0,
              focusTimeFormatted: '0m',
              focusMetaFormatted: 'Meta: 2h/dia',
            ),
          ),
        ),
      );

      expect(find.text('PROGRESSO'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Nenhuma hoje'), findsOneWidget);

      expect(find.text('OFENSIVA'), findsOneWidget);
      expect(find.text('0 Dias'), findsOneWidget);
      expect(find.text('Recorde: 0d'), findsOneWidget);

      expect(find.text('TEMPO FOCO'), findsOneWidget);
      expect(find.text('0m'), findsOneWidget);
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

    testWidgets('FloatingNavDock handles 4 uncrowded tabs and FAB trigger', (tester) async {
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
      expect(find.text('Calendário'), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);

      // Tap on Calendário (Aba 2)
      await tester.tap(find.text('Calendário'));
      expect(selectedIndex, 2);

      // Tap on Ajustes (Aba 3)
      await tester.tap(find.text('Ajustes'));
      expect(selectedIndex, 3);

      // Tap on FAB (+)
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(fabClicked, true);
    });

    testWidgets('CalendarScreen renders roadmap preview and back navigation', (tester) async {
      bool backNavigated = false;
      bool menuPressed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CalendarScreen(
              onNavigateToHome: () => backNavigated = true,
              onMenuPressed: () => menuPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Calendário'), findsOneWidget);
      expect(find.text('EM BREVE'), findsOneWidget);
      expect(find.text('Gestão Visual no Calendário'), findsOneWidget);

      await tester.tap(find.text('Voltar para o Início'));
      expect(backNavigated, true);

      await tester.tap(find.byIcon(Icons.menu_rounded));
      expect(menuPressed, true);
    });

    testWidgets('FadeIndexedStack renders children and animates smoothly', (tester) async {
      int currentIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: FadeIndexedStack(
                  index: currentIndex,
                  children: const [
                    Text('Tab 0 Content'),
                    Text('Tab 1 Content'),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => currentIndex = 1),
                  child: const Icon(Icons.arrow_forward),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Tab 0 Content'), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(); // Starts animation
      await tester.pump(const Duration(milliseconds: 300)); // Finishes animation

      expect(find.text('Tab 1 Content'), findsOneWidget);
    });

    testWidgets('HomeScreen opens drawer when hamburger menu is tapped', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Encontra o botão de menu hambúrguer na Home
      final menuBtn = find.byTooltip('Menu');
      expect(menuBtn, findsOneWidget);

      await tester.tap(menuBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // Animação do drawer

      // Verifica itens do menu hambúrguer
      expect(find.text('FERRAMENTAS'), findsOneWidget);
      expect(find.text('Timer & Cronômetro'), findsOneWidget);
      expect(find.text('Calculadora de Sono'), findsOneWidget);
      expect(find.text('Rotinas & Alarmes'), findsOneWidget);
    });

    testWidgets('HomeScreen notification button tap displays SnackBar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      final notifBtn = find.byTooltip('Notificações');
      expect(notifBtn, findsOneWidget);

      await tester.tap(notifBtn);
      await tester.pump();

      expect(find.text('Histórico de notificações em breve.'), findsOneWidget);
    });

    testWidgets('HomeScreen avatar tap switches to Settings tab', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      final avatarFinder = find.byType(GestureKey);
      expect(avatarFinder, findsOneWidget);

      await tester.tap(avatarFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Configurações'), findsWidgets);
    });
  });
}

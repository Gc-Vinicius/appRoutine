import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_routine/main.dart';

void main() {
  testWidgets('AppRoutine smoke test e validacao da nova Home Page', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AppRoutine(),
      ),
    );

    // Verifica elementos principais do novo Dashboard e FloatingNavDock (4 abas limpas)
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Rotinas'), findsWidgets);
    expect(find.text('Calendário'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Rotinas de Hoje'), findsOneWidget);
    expect(find.text('PROGRESSO'), findsOneWidget);
    expect(find.text('OFENSIVA'), findsOneWidget);
    expect(find.text('TEMPO FOCO'), findsOneWidget);
  });
}

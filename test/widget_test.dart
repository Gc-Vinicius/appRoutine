import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_routine/main.dart';

void main() {
  testWidgets('AppRoutine smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AppRoutine(),
      ),
    );

    // Verifica abas da BottomNavigationBar
    expect(find.text('Rotinas'), findsWidgets);
    expect(find.text('Tempo'), findsOneWidget);
    expect(find.text('Sono'), findsOneWidget);
    expect(find.text('Temas'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
  });
}

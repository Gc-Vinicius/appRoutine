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

    expect(find.text('Rotinas & Hábitos'), findsOneWidget);
  });
}

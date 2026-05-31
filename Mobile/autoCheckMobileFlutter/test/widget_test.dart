import 'package:autocheck_flutter/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders login screen', (tester) async {
    await tester.pumpWidget(const AutoCheckApp());
    expect(find.text('Экспертский dashboard'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
  });
}

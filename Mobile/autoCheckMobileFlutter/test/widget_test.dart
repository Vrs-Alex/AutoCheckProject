import 'package:auto_check_mobile_flutter/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders login screen', (tester) async {
    await tester.pumpWidget(AutoCheckApp());
    expect(find.text('Экспертский dashboard'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
  });
}

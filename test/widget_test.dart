import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/main.dart';

void main() {
  testWidgets('shows the app shell', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Quiz App'), findsOneWidget);
  });
}

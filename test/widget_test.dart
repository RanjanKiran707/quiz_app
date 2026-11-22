import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quiz_app/core/theme/app_theme.dart';
import 'package:quiz_app/core/widgets/app_widgets.dart';

void main() {
  testWidgets('renders inline math and an empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Column(
            children: [
              MathText(r'Inline \(2^{3}\) math'),
              EmptyState(
                icon: Icons.folder_outlined,
                title: 'Nothing here',
                message: 'Create a folder to begin.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(MathText), findsOneWidget);
    expect(find.byType(Math), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
  });
}

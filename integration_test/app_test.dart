import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quiz_app/core/di/app_dependencies.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/main.dart';

import '../test/helpers/test_database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = openTestDatabase();
    AppDependencies.instance = AppDependencies.withDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('create a folder, open a quiz, attempt it and see the result',
      (tester) async {
    await tester.pumpWidget(const QuizApp());
    await tester.pumpAndSettle();

    expect(find.text('All folders'), findsOneWidget);
    expect(find.text('No folders yet'), findsOneWidget);

    await tester.tap(find.text('New folder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Computer Networks');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Computer Networks'), findsOneWidget);

    final folders = await AppDependencies.instance.folderRepository
        .watchChildFolders(null)
        .first;
    final folderId = folders.valueOrNull!.single.id;

    await AppDependencies.instance.quizRepository.importQuizzes(
      folderId,
      [
        const QuizImportModel(
          title: 'Sample quiz',
          questions: [
            QuestionImportModel(
              prompt: 'Which option is correct?',
              type: QuestionType.mcq,
              position: 0,
              options: [
                OptionImportModel(text: 'Right', isCorrect: true, position: 0),
                OptionImportModel(text: 'Wrong', isCorrect: false, position: 1),
              ],
            ),
          ],
        ),
      ],
    );

    await tester.tap(find.text('Computer Networks'));
    await tester.pumpAndSettle();
    expect(find.text('Sample quiz'), findsOneWidget);

    await tester.tap(find.text('Sample quiz'));
    await tester.pumpAndSettle();
    expect(find.text('Start attempt'), findsOneWidget);

    await tester.tap(find.text('Start attempt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('Which option is correct?'), findsOneWidget);
    await tester.tap(find.text('Right'));
    await tester.pump();
    await tester.tap(find.text('End attempt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End and see result'));
    await tester.pumpAndSettle();

    expect(find.text('Saved to history'), findsOneWidget);
    expect(find.text('100%'), findsWidgets);
  });
}

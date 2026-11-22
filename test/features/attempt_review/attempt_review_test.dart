import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quiz_app/core/di/app_dependencies.dart';
import 'package:quiz_app/core/theme/app_theme.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/domain/use_cases/business/complete_attempt/complete_attempt_argument_model.dart';
import 'package:quiz_app/domain/use_cases/ui/get_attempt_review/get_attempt_review_return_model.dart';
import 'package:quiz_app/features/attempt_review/attempt_review_view.dart';
import 'package:quiz_app/features/attempt_review/attempt_review_view_model.dart';

import '../../helpers/test_database.dart';

Future<void> waitForStream() =>
    Future<void>.delayed(const Duration(milliseconds: 120));

void main() {
  late AppDatabase db;
  late AppDependencies deps;
  late AttemptModel attempt;

  setUp(() async {
    db = openTestDatabase();
    deps = AppDependencies.withDatabase(db);
    final folder = await deps.folderRepository.createFolder(
      parentId: null,
      name: 'Computer Networks',
    );
    final ids = await deps.quizRepository.importQuizzes(
      folder.valueOrNull!.id,
      [
        const QuizImportModel(
          title: 'Sample quiz',
          questions: [
            QuestionImportModel(
              prompt: 'Which option is correct?',
              type: QuestionType.mcq,
              position: 0,
              explanation: 'Right is the only correct option.',
              options: [
                OptionImportModel(text: 'Right', isCorrect: true, position: 0),
                OptionImportModel(text: 'Wrong', isCorrect: false, position: 1),
              ],
            ),
            QuestionImportModel(
              prompt: 'Pick both correct options',
              type: QuestionType.msq,
              position: 1,
              options: [
                OptionImportModel(text: 'One', isCorrect: true, position: 0),
                OptionImportModel(text: 'Two', isCorrect: true, position: 1),
                OptionImportModel(text: 'Three', isCorrect: false, position: 2),
              ],
            ),
          ],
        ),
      ],
    );
    final quizId = ids.valueOrNull!.single;
    await waitForStream();
    final detail = (await deps.quizRepository.getQuiz(quizId)).valueOrNull!;
    final mcq = detail.questions[0];
    final saved = await deps.completeAttempt(CompleteAttemptArgumentModel(
      quizId: quizId,
      startedAt: DateTime.utc(2026, 1, 1, 10),
      endedAt: DateTime.utc(2026, 1, 1, 10, 3),
      answers: {
        mcq.id: mcq.options.firstWhere((option) => option.isCorrect).id,
      },
    ));
    attempt = saved.valueOrNull!;
  });

  tearDown(() async {
    await db.close();
  });

  test('loads a review with counts and statuses', () async {
    final vm = AttemptReviewViewModel(
      bundle: AttemptReviewBundle(attemptId: attempt.id),
      getAttemptReview: deps.getAttemptReview,
    );

    await vm.load();

    final state = vm.state.value;
    expect(state, isA<ViewStateLoaded<AttemptReviewModel>>());
    final data = (state as ViewStateLoaded<AttemptReviewModel>).data;
    expect(data.reviews.length, 2);
    expect(data.correctCount, 1);
    expect(data.unansweredCount, 1);
    expect(data.incorrectCount, 0);
    expect(data.reviews.first.givenDisplay, 'Right');
    expect(data.reviews.last.givenDisplay, 'No answer');

    vm.dispose();
  });

  test('reports an error for an unknown attempt', () async {
    final vm = AttemptReviewViewModel(
      bundle: const AttemptReviewBundle(attemptId: 'missing'),
      getAttemptReview: deps.getAttemptReview,
    );

    await vm.load();

    expect(vm.state.value, isA<ViewStateError<AttemptReviewModel>>());
    vm.dispose();
  });

  testWidgets('renders the question, both answers and the explanation',
      (tester) async {
    final vm = AttemptReviewViewModel(
      bundle: AttemptReviewBundle(attemptId: attempt.id),
      getAttemptReview: deps.getAttemptReview,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AttemptReviewView(
          bundle: AttemptReviewBundle(attemptId: attempt.id),
          viewModel: vm,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ANSWER REVIEW'), findsOneWidget);
    expect(find.text('Sample quiz'), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Unanswered'), findsOneWidget);
    expect(find.text('Your answer'.toUpperCase()), findsNWidgets(2));
    expect(find.text('Correct answer'.toUpperCase()), findsNWidgets(2));
    expect(find.text('Right'), findsWidgets);
    expect(find.text('No answer'), findsOneWidget);

    await tester.tap(find.text('Explanation').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Right is the only correct option.'),
      findsOneWidget,
    );
  });
}

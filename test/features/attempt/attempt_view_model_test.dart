import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/core/di/app_dependencies.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/features/attempt/attempt_view_model.dart';

import '../../helpers/test_database.dart';

Future<void> waitForStream() =>
    Future<void>.delayed(const Duration(milliseconds: 120));

void main() {
  late AppDatabase db;
  late AppDependencies deps;
  late AttemptViewModel vm;

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
              options: [
                OptionImportModel(text: 'Right', isCorrect: true, position: 0),
                OptionImportModel(text: 'Wrong', isCorrect: false, position: 1),
              ],
            ),
          ],
        ),
      ],
    );
    vm = AttemptViewModel(
      bundle: AttemptBundle(quizId: ids.valueOrNull!.single),
      getQuizScreen: deps.getQuizScreen,
      completeAttempt: deps.completeAttempt,
    );
    await waitForStream();
  });

  tearDown(() async {
    vm.dispose();
    await db.close();
  });

  test('starts, records answers and saves a scored attempt', () async {
    expect(vm.detail, isNotNull);
    expect(vm.phase.value, AttemptPhase.preStart);

    vm.start();
    expect(vm.phase.value, AttemptPhase.running);

    final question = vm.detail!.questions.single;
    final correct = question.options.firstWhere((option) => option.isCorrect);
    vm.chooseMcq(question.id, correct.id);
    expect(vm.answeredCount, 1);
    expect(vm.isAnswered(question), isTrue);

    final result = await vm.end();
    expect(result, isA<Ok<AttemptModel>>());
    expect(result.valueOrNull?.score, 1);
    expect(result.valueOrNull?.maxScore, 1);
  });
}

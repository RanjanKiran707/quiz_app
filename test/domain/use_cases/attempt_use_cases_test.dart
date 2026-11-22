import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/attempt/attempt_repository.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/data/folder/folder_repository.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/data/quiz/quiz_repository.dart';
import 'package:quiz_app/domain/use_cases/business/complete_attempt/complete_attempt_argument_model.dart';
import 'package:quiz_app/domain/use_cases/business/complete_attempt/complete_attempt_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/get_attempt_screen/get_attempt_screen_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/get_quiz_screen/get_quiz_screen_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/list_folder_contents/list_folder_contents_usecase.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FolderRepository folders;
  late QuizRepository quizzes;
  late AttemptRepository attempts;
  late CompleteAttemptUsecase completeAttempt;
  late ListFolderContentsUsecase listFolderContents;
  late GetQuizScreenUsecase getQuizScreen;
  late GetAttemptScreenUsecase getAttemptScreen;

  setUp(() {
    db = openTestDatabase();
    folders = FolderRepository(db);
    quizzes = QuizRepository(db);
    attempts = AttemptRepository(db);
    completeAttempt = CompleteAttemptUsecase(quizzes, attempts);
    listFolderContents = ListFolderContentsUsecase(folders, quizzes);
    getQuizScreen = GetQuizScreenUsecase(quizzes, attempts);
    getAttemptScreen = GetAttemptScreenUsecase(attempts, quizzes);
  });

  tearDown(() async {
    await db.close();
  });

  Future<QuizDetailModel> seedQuiz() async {
    final folder = (await folders.createFolder(
      parentId: null,
      name: 'Computer Networks',
    ))
        .valueOrNull!;
    await quizzes.importQuizzes(folder.id, [
      const QuizImportModel(
        title: 'Scored quiz',
        questions: [
          QuestionImportModel(
            prompt: 'Pick one',
            type: QuestionType.mcq,
            position: 0,
            options: [
              OptionImportModel(text: 'Right', isCorrect: true, position: 0),
              OptionImportModel(text: 'Wrong', isCorrect: false, position: 1),
            ],
          ),
          QuestionImportModel(
            prompt: 'Pick many',
            type: QuestionType.msq,
            position: 1,
            options: [
              OptionImportModel(text: 'A', isCorrect: true, position: 0),
              OptionImportModel(text: 'B', isCorrect: true, position: 1),
              OptionImportModel(text: 'C', isCorrect: false, position: 2),
            ],
          ),
          QuestionImportModel(
            prompt: 'Enter a number',
            type: QuestionType.numerical,
            position: 2,
            numericalAnswer: 5,
            tolerance: 0.05,
          ),
        ],
      ),
    ]);
    final summaries = await quizzes.watchQuizSummaries(folder.id).first;
    final quizId = summaries.valueOrNull!.single.id;
    return (await quizzes.getQuiz(quizId)).valueOrNull!;
  }

  test('completeAttempt scores MCQ, MSQ and numerical answers', () async {
    final detail = await seedQuiz();
    final answers = {
      detail.questions[0].id: detail.questions[0]
          .options
          .firstWhere((option) => option.isCorrect)
          .id,
      detail.questions[1].id: detail.questions[1]
          .options
          .where((option) => option.isCorrect)
          .map((option) => option.id)
          .toList(),
      detail.questions[2].id: 5.01,
    };

    final result = await completeAttempt(CompleteAttemptArgumentModel(
      quizId: detail.quiz.id,
      startedAt: DateTime.utc(2026, 1, 1, 10),
      endedAt: DateTime.utc(2026, 1, 1, 10, 5),
      answers: answers,
    ));

    expect(result, isA<Ok<AttemptModel>>());
    final attempt = result.valueOrNull!;
    expect(attempt.score, 3);
    expect(attempt.maxScore, 3);
    expect(attempt.durationMs, 300000);

    final fetched = await attempts.getAttempt(attempt.id);
    expect(fetched.valueOrNull?.score, 3);
  });

  test('completeAttempt gives zero for wrong, partial and blank answers',
      () async {
    final detail = await seedQuiz();
    final answers = {
      detail.questions[0].id: detail.questions[0]
          .options
          .firstWhere((option) => !option.isCorrect)
          .id,
      detail.questions[1].id: [
        detail.questions[1]
            .options
            .firstWhere((option) => option.isCorrect)
            .id,
      ],
      detail.questions[2].id: '',
    };

    final result = await completeAttempt(CompleteAttemptArgumentModel(
      quizId: detail.quiz.id,
      startedAt: DateTime.utc(2026, 1, 1, 10),
      endedAt: DateTime.utc(2026, 1, 1, 10, 1),
      answers: answers,
    ));

    expect(result.valueOrNull?.score, 0);
    expect(result.valueOrNull?.maxScore, 3);
  });

  test('folder contents use case returns root and nested data', () async {
    final detail = await seedQuiz();
    final folderId = detail.quiz.folderId;

    final root = await listFolderContents(null).first;
    expect(root.valueOrNull?.folder, isNull);
    expect(root.valueOrNull?.path, isEmpty);
    expect(root.valueOrNull?.folders.single.name, 'Computer Networks');

    final nested = await listFolderContents(folderId).first;
    expect(nested.valueOrNull?.folder?.name, 'Computer Networks');
    expect(nested.valueOrNull?.path.length, 1);
    expect(nested.valueOrNull?.quizzes.single.title, 'Scored quiz');
  });

  test('quiz and attempt screen use cases return combined data', () async {
    final detail = await seedQuiz();
    final save = await completeAttempt(CompleteAttemptArgumentModel(
      quizId: detail.quiz.id,
      startedAt: DateTime.utc(2026, 1, 1, 10),
      endedAt: DateTime.utc(2026, 1, 1, 10, 5),
      answers: {},
    ));
    final attemptId = save.valueOrNull!.id;

    final quizScreen = await getQuizScreen(detail.quiz.id).first;
    expect(quizScreen.valueOrNull?.detail.questions.length, 3);
    expect(quizScreen.valueOrNull?.attempts.length, 1);

    final attemptScreen = await getAttemptScreen(attemptId);
    expect(attemptScreen.valueOrNull?.attempt.id, attemptId);
    expect(attemptScreen.valueOrNull?.quiz?.title, 'Scored quiz');
  });
}

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
import 'package:quiz_app/domain/use_cases/ui/get_attempt_review/get_attempt_review_return_model.dart';
import 'package:quiz_app/domain/use_cases/ui/get_attempt_review/get_attempt_review_usecase.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FolderRepository folders;
  late QuizRepository quizzes;
  late AttemptRepository attempts;
  late CompleteAttemptUsecase completeAttempt;
  late GetAttemptReviewUsecase getAttemptReview;

  setUp(() {
    db = openTestDatabase();
    folders = FolderRepository(db);
    quizzes = QuizRepository(db);
    attempts = AttemptRepository(db);
    completeAttempt = CompleteAttemptUsecase(quizzes, attempts);
    getAttemptReview = GetAttemptReviewUsecase(attempts, quizzes);
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
            explanation: 'A is right.',
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
            unit: 'ms',
          ),
        ],
      ),
    ]);
    final summaries = await quizzes.watchQuizSummaries(folder.id).first;
    final quizId = summaries.valueOrNull!.single.id;
    return (await quizzes.getQuiz(quizId)).valueOrNull!;
  }

  test('review reports correct, incorrect and unanswered questions', () async {
    final detail = await seedQuiz();
    final mcq = detail.questions[0];
    final msq = detail.questions[1];

    final save = await completeAttempt(CompleteAttemptArgumentModel(
      quizId: detail.quiz.id,
      startedAt: DateTime.utc(2026, 1, 1, 10),
      endedAt: DateTime.utc(2026, 1, 1, 10, 4),
      answers: {
        mcq.id: mcq.options.firstWhere((option) => option.isCorrect).id,
        msq.id: [msq.options.firstWhere((option) => option.isCorrect).id],
      },
    ));
    final attempt = save.valueOrNull!;

    final result = await getAttemptReview(attempt.id);

    expect(result.valueOrNull?.attempt.id, attempt.id);
    expect(result.valueOrNull?.quiz.title, 'Scored quiz');
    final reviews = result.valueOrNull!.reviews;
    expect(reviews.length, 3);

    expect(reviews[0].status, AnswerReviewStatus.correct);
    expect(reviews[0].givenDisplay, 'Right');
    expect(reviews[0].correctDisplay, 'Right');

    expect(reviews[1].status, AnswerReviewStatus.incorrect);
    expect(reviews[1].givenDisplay, 'A');
    expect(reviews[1].correctDisplay, 'A · B');

    expect(reviews[2].status, AnswerReviewStatus.unanswered);
    expect(reviews[2].givenDisplay, 'No answer');
    expect(reviews[2].correctDisplay, '5 ms (±0.05)');

    expect(result.valueOrNull?.correctCount, 1);
    expect(result.valueOrNull?.incorrectCount, 1);
    expect(result.valueOrNull?.unansweredCount, 1);
  });

  test('review accepts the exact MSQ set and numerical tolerance', () async {
    final detail = await seedQuiz();
    final mcq = detail.questions[0];
    final msq = detail.questions[1];
    final numerical = detail.questions[2];

    final save = await completeAttempt(CompleteAttemptArgumentModel(
      quizId: detail.quiz.id,
      startedAt: DateTime.utc(2026, 1, 1, 11),
      endedAt: DateTime.utc(2026, 1, 1, 11, 2),
      answers: {
        mcq.id: mcq.options.firstWhere((option) => !option.isCorrect).id,
        msq.id: msq.options
            .where((option) => option.isCorrect)
            .map((option) => option.id)
            .toList(),
        numerical.id: '5.03',
      },
    ));

    final result = await getAttemptReview(save.valueOrNull!.id);
    final reviews = result.valueOrNull!.reviews;

    expect(reviews[0].status, AnswerReviewStatus.incorrect);
    expect(reviews[0].givenDisplay, 'Wrong');

    expect(reviews[1].status, AnswerReviewStatus.correct);
    expect(reviews[1].givenDisplay, 'A · B');

    expect(reviews[2].status, AnswerReviewStatus.correct);
    expect(reviews[2].givenDisplay, '5.03 ms');

    expect(result.valueOrNull?.correctCount, 2);
    expect(result.valueOrNull?.incorrectCount, 1);
  });

  test('review treats unreadable stored answers as unanswered', () async {
    final detail = await seedQuiz();
    final attempt = AttemptModel(
      id: 'broken-attempt',
      quizId: detail.quiz.id,
      startedAt: DateTime.utc(2026, 1, 1, 10).toIso8601String(),
      endedAt: DateTime.utc(2026, 1, 1, 10, 2).toIso8601String(),
      durationMs: 120000,
      score: 0,
      maxScore: 3,
      answersJson: '{not valid json',
    );
    final saved = await attempts.saveAttempt(attempt);
    expect(saved, isA<Ok<void>>());

    final result = await getAttemptReview(attempt.id);

    expect(result, isA<Ok<AttemptReviewModel>>());
    expect(result.valueOrNull?.reviews.length, 3);
    expect(result.valueOrNull?.unansweredCount, 3);
    expect(result.valueOrNull?.correctCount, 0);
  });

  test('review fails when the attempt does not exist', () async {
    final result = await getAttemptReview('missing');
    expect(result, isA<Err<AttemptReviewModel>>());
  });
}

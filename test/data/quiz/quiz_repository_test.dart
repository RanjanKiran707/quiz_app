import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/attempt/attempt_repository.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/data/folder/folder_repository.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/data/quiz/quiz_repository.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FolderRepository folders;
  late QuizRepository quizzes;
  late AttemptRepository attempts;

  setUp(() {
    db = openTestDatabase();
    folders = FolderRepository(db);
    quizzes = QuizRepository(db);
    attempts = AttemptRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> createFolder() async {
    final result = await folders.createFolder(
      parentId: null,
      name: 'Computer Networks',
    );
    return result.valueOrNull!.id;
  }

  QuizImportModel sampleQuiz(String title) => QuizImportModel(
        title: title,
        subtitle: 'A short subtitle',
        sourceKey: 'sample-key',
        questions: const [
          QuestionImportModel(
            prompt: 'Which one is correct?',
            type: QuestionType.mcq,
            position: 0,
            options: [
              OptionImportModel(text: 'Right', isCorrect: true, position: 0),
              OptionImportModel(text: 'Wrong', isCorrect: false, position: 1),
            ],
          ),
          QuestionImportModel(
            prompt: 'Enter the number',
            type: QuestionType.numerical,
            position: 1,
            numericalAnswer: 42,
            tolerance: 0,
          ),
        ],
      );

  test('imports a quiz with ordered questions and options', () async {
    final folderId = await createFolder();
    final imported = await quizzes.importQuizzes(folderId, [sampleQuiz('Quiz A')]);
    expect(imported, isA<Ok<void>>());

    final summaries = await quizzes.watchQuizSummaries(folderId).first;
    final summary = summaries.valueOrNull!.single;
    expect(summary.title, 'Quiz A');
    expect(summary.subtitle, 'A short subtitle');
    expect(summary.questionCount, 2);
    expect(summary.totalMarks, 2);
    expect(summary.attemptCount, 0);

    final detail = await quizzes.getQuiz(summary.id);
    expect(detail.valueOrNull?.questions.length, 2);
    expect(detail.valueOrNull?.questions.first.type, QuestionType.mcq);
    expect(detail.valueOrNull?.questions.first.options.length, 2);
    expect(detail.valueOrNull?.questions.first.options.first.isCorrect, isTrue);
    expect(detail.valueOrNull?.questions[1].type, QuestionType.numerical);
    expect(detail.valueOrNull?.questions[1].numericalAnswer, 42);
  });

  test('summary includes attempts and the latest score', () async {
    final folderId = await createFolder();
    await quizzes.importQuizzes(folderId, [sampleQuiz('Quiz A')]);
    final summaries = await quizzes.watchQuizSummaries(folderId).first;
    final quizId = summaries.valueOrNull!.single.id;

    final saved = await attempts.saveAttempt(AttemptModel(
      id: 'a1',
      quizId: quizId,
      startedAt: '2026-01-01T10:00:00.000Z',
      endedAt: '2026-01-01T10:05:00.000Z',
      durationMs: 300000,
      score: 1,
      maxScore: 2,
      answersJson: '{}',
    ));
    expect(saved, isA<Ok<void>>());

    final after = await quizzes.watchQuizSummaries(folderId).first;
    final summary = after.valueOrNull!.single;
    expect(summary.attemptCount, 1);
    expect(summary.lastScore, 1);
    expect(summary.lastMaxScore, 2);
    expect(summary.lastAttemptAt, '2026-01-01T10:00:00.000Z');
  });

  test('imports multiple quizzes in one batch', () async {
    final folderId = await createFolder();
    final imported = await quizzes.importQuizzes(folderId, [
      sampleQuiz('Quiz A'),
      sampleQuiz('Quiz B'),
    ]);
    expect(imported, isA<Ok<void>>());

    final summaries = await quizzes.watchQuizSummaries(folderId).first;
    expect(summaries.valueOrNull!.length, 2);
    expect(
      summaries.valueOrNull!.map((summary) => summary.title).toSet(),
      {'Quiz A', 'Quiz B'},
    );
  });

  test('deletes a quiz and its questions and attempts', () async {
    final folderId = await createFolder();
    await quizzes.importQuizzes(folderId, [sampleQuiz('Quiz A')]);
    final summaries = await quizzes.watchQuizSummaries(folderId).first;
    final quizId = summaries.valueOrNull!.single.id;
    await attempts.saveAttempt(AttemptModel(
      id: 'a1',
      quizId: quizId,
      startedAt: '2026-01-01T10:00:00.000Z',
      endedAt: '2026-01-01T10:05:00.000Z',
      durationMs: 300000,
      score: 1,
      maxScore: 2,
      answersJson: '{}',
    ));

    final deleted = await quizzes.deleteQuiz(quizId);
    expect(deleted, isA<Ok<void>>());

    final detail = await quizzes.getQuiz(quizId);
    expect(detail.valueOrNull, isNull);
    final attemptsLeft = await attempts.watchAttempts(quizId).first;
    expect(attemptsLeft.valueOrNull, isEmpty);
  });

  test('getQuiz returns null for an unknown id', () async {
    final result = await quizzes.getQuiz('missing');
    expect(result.valueOrNull, isNull);
  });
}

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

  Future<String> seedQuiz() async {
    final folder = await folders.createFolder(
      parentId: null,
      name: 'Computer Networks',
    );
    final folderId = folder.valueOrNull!.id;
    await quizzes.importQuizzes(folderId, [
      const QuizImportModel(
        title: 'Sample quiz',
        questions: [
          QuestionImportModel(
            prompt: 'Question',
            type: QuestionType.mcq,
            position: 0,
            options: [
              OptionImportModel(text: 'A', isCorrect: true, position: 0),
              OptionImportModel(text: 'B', isCorrect: false, position: 1),
            ],
          ),
        ],
      ),
    ]);
    final summaries = await quizzes.watchQuizSummaries(folderId).first;
    return summaries.valueOrNull!.single.id;
  }

  AttemptModel attempt(String id, String quizId, String startedAt) => AttemptModel(
        id: id,
        quizId: quizId,
        startedAt: startedAt,
        endedAt: startedAt,
        durationMs: 60000,
        score: 1,
        maxScore: 1,
        answersJson: '{}',
      );

  test('saves an attempt and reads it back', () async {
    final quizId = await seedQuiz();
    final saved = await attempts.saveAttempt(
      attempt('a1', quizId, '2026-01-01T10:00:00.000Z'),
    );
    expect(saved, isA<Ok<void>>());

    final fetched = await attempts.getAttempt('a1');
    expect(fetched.valueOrNull?.quizId, quizId);
    expect(fetched.valueOrNull?.score, 1);

    final missing = await attempts.getAttempt('missing');
    expect(missing.valueOrNull, isNull);
  });

  test('watchAttempts returns newest first', () async {
    final quizId = await seedQuiz();
    await attempts.saveAttempt(
      attempt('older', quizId, '2026-01-01T10:00:00.000Z'),
    );
    await attempts.saveAttempt(
      attempt('newer', quizId, '2026-02-01T10:00:00.000Z'),
    );

    final list = await attempts.watchAttempts(quizId).first;
    expect(list.valueOrNull!.map((item) => item.id), ['newer', 'older']);
  });

  test('saving an attempt for a missing quiz is a storage failure', () async {
    final saved = await attempts.saveAttempt(
      attempt('a1', 'missing-quiz', '2026-01-01T10:00:00.000Z'),
    );
    expect(saved, isA<Err<void>>());
  });
}

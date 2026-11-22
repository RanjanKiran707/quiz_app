import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/attempt/attempt_repository.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/data/folder/folder_model.dart';
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

  Future<FolderModel> createFolder(
    String name, {
    String? parentId,
  }) async {
    final result = await folders.createFolder(parentId: parentId, name: name);
    return result.valueOrNull!;
  }

  test('creates and reads folders', () async {
    final folder = await createFolder('Computer Networks');

    final fetched = await folders.getFolder(folder.id);
    expect(fetched.valueOrNull?.name, 'Computer Networks');
    expect(fetched.valueOrNull?.parentFolderId, isNull);

    final missing = await folders.getFolder('missing');
    expect(missing.valueOrNull, isNull);
  });

  test('watchChildFolders lists only the requested level, sorted', () async {
    await createFolder('Physics');
    await createFolder('Aptitude');
    final networks = await createFolder('Computer Networks');
    await createFolder('Transport Layer', parentId: networks.id);

    final roots = await folders.watchChildFolders(null).first;
    expect(
      roots.valueOrNull!.map((folder) => folder.name),
      ['Aptitude', 'Computer Networks', 'Physics'],
    );

    final children = await folders.watchChildFolders(networks.id).first;
    expect(
      children.valueOrNull!.map((folder) => folder.name),
      ['Transport Layer'],
    );
  });

  test('renames a folder and keeps names unique among siblings', () async {
    final folder = await createFolder('Physics');
    await createFolder('Mathematics');

    final renamed = await folders.renameFolder(folder.id, 'Physical Sciences');
    expect(renamed, isA<Ok<void>>());

    final fetched = await folders.getFolder(folder.id);
    expect(fetched.valueOrNull?.name, 'Physical Sciences');

    final taken = await folders.isNameTaken(
      parentId: null,
      name: 'mathematics',
    );
    expect(taken.valueOrNull, isTrue);

    final excluded = await folders.isNameTaken(
      parentId: null,
      name: 'Physical Sciences',
      excludeId: folder.id,
    );
    expect(excluded.valueOrNull, isFalse);
  });

  test('getFolderPath returns root to leaf', () async {
    final root = await createFolder('Computer Networks');
    final child = await createFolder('Transport Layer', parentId: root.id);
    final leaf = await createFolder('TCP', parentId: child.id);

    final path = await folders.getFolderPath(leaf.id);
    expect(
      path.valueOrNull!.map((folder) => folder.name),
      ['Computer Networks', 'Transport Layer', 'TCP'],
    );
  });

  test('getDeletePreview counts the subtree and deletes cascade', () async {
    final root = await createFolder('Computer Networks');
    final child = await createFolder('Transport Layer', parentId: root.id);

    final imported = await quizzes.importQuizzes(root.id, [
      const QuizImportModel(
        title: 'Subnetting Basics',
        questions: [
          QuestionImportModel(
            prompt: 'Choose one',
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
    expect(imported, isA<Ok<void>>());

    final summaries = await quizzes.watchQuizSummaries(root.id).first;
    final quizId = summaries.valueOrNull!.single.id;

    final saved = await attempts.saveAttempt(AttemptModel(
      id: 'a1',
      quizId: quizId,
      startedAt: '2026-01-01T10:00:00.000Z',
      endedAt: '2026-01-01T10:05:00.000Z',
      durationMs: 300000,
      score: 1,
      maxScore: 1,
      answersJson: '{}',
    ));
    expect(saved, isA<Ok<void>>());

    final preview = await folders.getDeletePreview(root.id);
    expect(preview.valueOrNull?.folders, 1);
    expect(preview.valueOrNull?.quizzes, 1);
    expect(preview.valueOrNull?.attempts, 1);
    expect(preview.valueOrNull?.questions, 1);

    final deleted = await folders.deleteFolder(root.id);
    expect(deleted, isA<Ok<void>>());

    final gone = await folders.getFolder(child.id);
    expect(gone.valueOrNull, isNull);
    final quizGone = await quizzes.getQuiz(quizId);
    expect(quizGone.valueOrNull, isNull);
    final attemptsLeft = await attempts.watchAttempts(quizId).first;
    expect(attemptsLeft.valueOrNull, isEmpty);
  });
}

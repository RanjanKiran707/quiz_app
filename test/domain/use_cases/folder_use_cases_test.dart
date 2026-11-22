import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/data/folder/folder_repository.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/data/quiz/quiz_repository.dart';
import 'package:quiz_app/domain/use_cases/business/create_folder/create_folder_argument_model.dart';
import 'package:quiz_app/domain/use_cases/business/create_folder/create_folder_usecase.dart';
import 'package:quiz_app/domain/use_cases/business/delete_folder/delete_folder_usecase.dart';
import 'package:quiz_app/domain/use_cases/business/import_quizzes/import_quizzes_argument_model.dart';
import 'package:quiz_app/domain/use_cases/business/import_quizzes/import_quizzes_usecase.dart';
import 'package:quiz_app/domain/use_cases/business/rename_folder/rename_folder_argument_model.dart';
import 'package:quiz_app/domain/use_cases/business/rename_folder/rename_folder_usecase.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FolderRepository folders;
  late QuizRepository quizzes;
  late CreateFolderUsecase createFolder;
  late RenameFolderUsecase renameFolder;
  late DeleteFolderUsecase deleteFolder;
  late ImportQuizzesUsecase importQuizzes;

  setUp(() {
    db = openTestDatabase();
    folders = FolderRepository(db);
    quizzes = QuizRepository(db);
    createFolder = CreateFolderUsecase(folders);
    renameFolder = RenameFolderUsecase(folders);
    deleteFolder = DeleteFolderUsecase(folders);
    importQuizzes = ImportQuizzesUsecase(quizzes);
  });

  tearDown(() async {
    await db.close();
  });

  test('create folder validates and stores a trimmed name', () async {
    final result = await createFolder(
      const CreateFolderArgumentModel(parentId: null, name: '  Physics  '),
    );
    expect(result, isA<Ok<dynamic>>());
    final folder = result.valueOrNull!;
    expect(folder.name, 'Physics');
  });

  test('create folder rejects blank and duplicate names', () async {
    final empty = await createFolder(
      const CreateFolderArgumentModel(parentId: null, name: '   '),
    );
    expect(empty, isA<Err<dynamic>>());
    expect(empty.failureMessage, 'folder_name_required');

    await createFolder(
      const CreateFolderArgumentModel(parentId: null, name: 'Physics'),
    );
    final duplicate = await createFolder(
      const CreateFolderArgumentModel(parentId: null, name: 'physics'),
    );
    expect(duplicate, isA<Err<dynamic>>());
    expect(duplicate.failureMessage, 'folder_name_taken');
  });

  test('rename folder rejects a duplicate sibling', () async {
    final physics = (await createFolder(
      const CreateFolderArgumentModel(parentId: null, name: 'Physics'),
    ))
        .valueOrNull!;
    await createFolder(
      const CreateFolderArgumentModel(parentId: null, name: 'Mathematics'),
    );

    final duplicate = await renameFolder(
      RenameFolderArgumentModel(id: physics.id, name: 'mathematics'),
    );
    expect(duplicate, isA<Err<dynamic>>());
    expect(duplicate.failureMessage, 'folder_name_taken');

    final renamed = await renameFolder(
      RenameFolderArgumentModel(id: physics.id, name: 'Physical Sciences'),
    );
    expect(renamed, isA<Ok<dynamic>>());
    expect(
      (await folders.getFolder(physics.id)).valueOrNull?.name,
      'Physical Sciences',
    );
  });

  test('delete folder removes the subtree', () async {
    final root = (await createFolder(
      const CreateFolderArgumentModel(parentId: null, name: 'Root'),
    ))
        .valueOrNull!;
    final child = (await createFolder(
      CreateFolderArgumentModel(parentId: root.id, name: 'Child'),
    ))
        .valueOrNull!;

    final result = await deleteFolder(root.id);
    expect(result, isA<Ok<dynamic>>());
    expect((await folders.getFolder(root.id)).valueOrNull, isNull);
    expect((await folders.getFolder(child.id)).valueOrNull, isNull);
  });

  test('import quizzes validates and stores valid quizzes', () async {
    final folder = (await createFolder(
      const CreateFolderArgumentModel(parentId: null, name: 'Folder'),
    ))
        .valueOrNull!;

    const valid = QuizImportModel(
      title: 'Valid quiz',
      questions: [
        QuestionImportModel(
          prompt: 'Pick one',
          type: QuestionType.mcq,
          position: 0,
          options: [
            OptionImportModel(text: 'A', isCorrect: true, position: 0),
            OptionImportModel(text: 'B', isCorrect: false, position: 1),
          ],
        ),
      ],
    );

    final imported = await importQuizzes(
      ImportQuizzesArgumentModel(folderId: folder.id, quizzes: [valid]),
    );
    expect(imported, isA<Ok<dynamic>>());

    const invalid = QuizImportModel(
      title: 'Invalid quiz',
      questions: [
        QuestionImportModel(
          prompt: 'No correct answer',
          type: QuestionType.mcq,
          position: 0,
          options: [
            OptionImportModel(text: 'A', isCorrect: false, position: 0),
            OptionImportModel(text: 'B', isCorrect: false, position: 1),
          ],
        ),
      ],
    );
    final rejected = await importQuizzes(
      ImportQuizzesArgumentModel(folderId: folder.id, quizzes: [invalid]),
    );
    expect(rejected, isA<Err<dynamic>>());
    expect(rejected.failureMessage, 'mcq_correct_required');
  });
}

extension ResultFailureMessage on Result<dynamic> {
  String? get failureMessage => switch (this) {
        Err(:final failure) => failure.message,
        Ok() => null,
      };
}

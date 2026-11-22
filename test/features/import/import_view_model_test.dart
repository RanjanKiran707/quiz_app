import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/core/di/app_dependencies.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/features/import/import_view_model.dart';

import '../../helpers/test_database.dart';

Future<void> waitForStream() =>
    Future<void>.delayed(const Duration(milliseconds: 120));

void main() {
  late AppDatabase db;
  late AppDependencies deps;
  late ImportViewModel vm;
  late String folderId;

  setUp(() async {
    db = openTestDatabase();
    deps = AppDependencies.withDatabase(db);
    final folder = await deps.folderRepository.createFolder(
      parentId: null,
      name: 'Computer Networks',
    );
    folderId = folder.valueOrNull!.id;
    vm = ImportViewModel(
      bundle: ImportBundle(folderId: folderId),
      getFolder: deps.getFolder,
      parseQuizJson: deps.parseQuizJson,
      importQuizzes: deps.importQuizzes,
    );
    await vm.load();
  });

  tearDown(() async {
    vm.dispose();
    await db.close();
  });

  test('parses a valid file and imports it', () async {
    const source = '''
    {
      "title": "Sample quiz",
      "questions": [
        { "t": "MCQ", "q": "Pick one", "o": ["A", "B"], "a": 0 }
      ]
    }
    ''';

    vm.addTextFile(name: 'quiz.json', size: 200, text: source);
    expect(vm.files.value.single.isValid, isTrue);

    final imported = await vm.importAll();
    expect(imported, isA<Ok<List<String>>>());
    expect(imported.valueOrNull?.length, 1);

    final summaries =
        await deps.quizRepository.watchQuizSummaries(folderId).first;
    expect(summaries.valueOrNull?.single.title, 'Sample quiz');
  });

  test('keeps an invalid file out of the import', () async {
    vm.addTextFile(
      name: 'broken.json',
      size: 100,
      text: '{"title": "", "questions": []}',
    );
    expect(vm.files.value.single.isValid, isFalse);
    expect(vm.importState.value, isA<ViewStateIdle<void>>());
    final imported = await vm.importAll();
    expect(imported, isA<Err<List<String>>>());
  });
}

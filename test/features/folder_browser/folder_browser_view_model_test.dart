import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/core/di/app_dependencies.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/domain/use_cases/ui/list_folder_contents/list_folder_contents_return_model.dart';
import 'package:quiz_app/features/folder_browser/folder_browser_view_model.dart';

import '../../helpers/test_database.dart';

Future<void> waitForStream() =>
    Future<void>.delayed(const Duration(milliseconds: 120));

void main() {
  late AppDatabase db;
  late AppDependencies deps;
  late FolderBrowserViewModel vm;

  setUp(() async {
    db = openTestDatabase();
    deps = AppDependencies.withDatabase(db);
    vm = FolderBrowserViewModel(
      bundle: const FolderBrowserBundle(),
      listFolderContents: deps.listFolderContents,
      createFolder: deps.createFolder,
      renameFolder: deps.renameFolder,
      deleteFolder: deps.deleteFolder,
      deleteQuiz: deps.deleteQuiz,
      getFolderDeletePreview: deps.getFolderDeletePreview,
    );
    await waitForStream();
  });

  tearDown(() async {
    vm.dispose();
    await db.close();
  });

  test('loads an empty root folder', () {
    final state = vm.state.value;
    expect(state, isA<ViewStateLoaded<FolderContentsModel>>());
    final contents = (state as ViewStateLoaded<FolderContentsModel>).data;
    expect(contents.folder, isNull);
    expect(contents.folders, isEmpty);
    expect(contents.quizzes, isEmpty);
  });

  test('creates, renames and deletes a folder through the view model', () async {
    final created = await vm.createFolder('Physics');
    expect(created.valueOrNull?.name, 'Physics');
    await waitForStream();
    expect(
      vm.contents?.folders.map((folder) => folder.name),
      contains('Physics'),
    );

    final folderId = created.valueOrNull!.id;
    final renamed = await vm.renameFolder(folderId, 'Physical Sciences');
    expect(renamed, isA<Ok<void>>());
    await waitForStream();
    expect(
      vm.contents?.folders.map((folder) => folder.name),
      contains('Physical Sciences'),
    );

    final deleted = await vm.deleteFolder(folderId);
    expect(deleted, isA<Ok<void>>());
    await waitForStream();
    expect(vm.contents?.folders, isEmpty);
  });
}

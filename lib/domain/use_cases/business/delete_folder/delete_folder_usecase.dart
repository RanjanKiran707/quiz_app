import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/folder/folder_repository_interface.dart';

class DeleteFolderUsecase {
  DeleteFolderUsecase(this._folders);

  final FolderRepositoryInterface _folders;

  Future<Result<void>> call(String id) => _folders.deleteFolder(id);
}

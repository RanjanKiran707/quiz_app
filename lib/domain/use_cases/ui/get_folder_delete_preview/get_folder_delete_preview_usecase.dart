import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/folder/folder_model.dart';
import 'package:quiz_app/data/folder/folder_repository_interface.dart';

class GetFolderDeletePreviewUsecase {
  GetFolderDeletePreviewUsecase(this._folders);

  final FolderRepositoryInterface _folders;

  Future<Result<FolderDeletePreviewModel>> call(String id) =>
      _folders.getDeletePreview(id);
}

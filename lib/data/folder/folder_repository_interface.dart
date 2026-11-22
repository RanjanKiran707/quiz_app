import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/folder/folder_model.dart';

abstract interface class FolderRepositoryInterface {
  Stream<Result<List<FolderModel>>> watchChildFolders(String? parentId);

  Future<Result<FolderModel?>> getFolder(String id);

  Future<Result<List<FolderModel>>> getFolderPath(String id);

  Future<Result<FolderModel>> createFolder({
    required String? parentId,
    required String name,
  });

  Future<Result<void>> renameFolder(String id, String name);

  Future<Result<void>> deleteFolder(String id);

  Future<Result<FolderDeletePreviewModel>> getDeletePreview(String id);

  Future<Result<bool>> isNameTaken({
    required String? parentId,
    required String name,
    String? excludeId,
  });
}

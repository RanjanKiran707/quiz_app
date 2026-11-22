import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/folder/folder_model.dart';
import 'package:quiz_app/data/folder/folder_repository_interface.dart';
import 'package:quiz_app/domain/use_cases/business/rename_folder/rename_folder_argument_model.dart';

class RenameFolderUsecase {
  RenameFolderUsecase(this._folders);

  final FolderRepositoryInterface _folders;

  Future<Result<void>> call(RenameFolderArgumentModel arguments) async {
    final name = arguments.name.trim();
    if (name.isEmpty) {
      return const Err(ValidationFailure('folder_name_required'));
    }
    if (name.length > 60) {
      return const Err(ValidationFailure('folder_name_too_long'));
    }

    final folderResult = await _folders.getFolder(arguments.id);
    if (folderResult case Err(:final failure)) return Err(failure);
    final folder = (folderResult as Ok<FolderModel?>).value;
    if (folder == null) {
      return const Err(StorageFailure('folder_not_found'));
    }

    final takenResult = await _folders.isNameTaken(
      parentId: folder.parentFolderId,
      name: name,
      excludeId: arguments.id,
    );
    if (takenResult case Err(:final failure)) return Err(failure);
    if ((takenResult as Ok<bool>).value) {
      return const Err(ValidationFailure('folder_name_taken'));
    }

    return _folders.renameFolder(arguments.id, name);
  }
}

import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/folder/folder_model.dart';
import 'package:quiz_app/data/folder/folder_repository_interface.dart';
import 'package:quiz_app/domain/use_cases/business/create_folder/create_folder_argument_model.dart';

class CreateFolderUsecase {
  CreateFolderUsecase(this._folders);

  final FolderRepositoryInterface _folders;

  Future<Result<FolderModel>> call(CreateFolderArgumentModel arguments) async {
    final name = arguments.name.trim();
    if (name.isEmpty) {
      return const Err(ValidationFailure('folder_name_required'));
    }
    if (name.length > 60) {
      return const Err(ValidationFailure('folder_name_too_long'));
    }

    final takenResult = await _folders.isNameTaken(
      parentId: arguments.parentId,
      name: name,
    );
    if (takenResult case Err(:final failure)) return Err(failure);
    if ((takenResult as Ok<bool>).value) {
      return const Err(ValidationFailure('folder_name_taken'));
    }

    return _folders.createFolder(
      parentId: arguments.parentId,
      name: name,
    );
  }
}

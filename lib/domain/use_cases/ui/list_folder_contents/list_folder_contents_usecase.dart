import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/core/utils/stream_utils.dart';
import 'package:quiz_app/data/folder/folder_model.dart';
import 'package:quiz_app/data/folder/folder_repository_interface.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/data/quiz/quiz_repository_interface.dart';
import 'package:quiz_app/domain/use_cases/ui/list_folder_contents/list_folder_contents_return_model.dart';

class ListFolderContentsUsecase {
  ListFolderContentsUsecase(this._folders, this._quizzes);

  final FolderRepositoryInterface _folders;
  final QuizRepositoryInterface _quizzes;

  Stream<Result<FolderContentsModel>> call(String? folderId) async* {
    final Result<List<FolderModel>> pathResult = folderId == null
        ? const Ok<List<FolderModel>>([])
        : await _folders.getFolderPath(folderId);

    if (pathResult case Err(:final failure)) {
      yield Err(failure);
      return;
    }
    final path = (pathResult as Ok<List<FolderModel>>).value;
    if (folderId != null && path.isEmpty) {
      yield const Err(StorageFailure('folder_not_found'));
      return;
    }
    final folder = folderId == null ? null : path.last;

    final folderStream = _folders.watchChildFolders(folderId);
    final Stream<Result<List<QuizSummaryModel>>> quizStream = folderId == null
        ? Stream<Result<List<QuizSummaryModel>>>.value(
            const Ok<List<QuizSummaryModel>>([]),
          )
        : _quizzes.watchQuizSummaries(folderId);

    yield* combineLatest2(
      folderStream,
      quizStream,
      (Result<List<FolderModel>> folderResult,
          Result<List<QuizSummaryModel>> quizResult) {
        if (folderResult case Err(:final failure)) {
          return Err<FolderContentsModel>(failure);
        }
        if (quizResult case Err(:final failure)) {
          return Err<FolderContentsModel>(failure);
        }
        return Ok(FolderContentsModel(
          folder: folder,
          path: path,
          folders: (folderResult as Ok<List<FolderModel>>).value,
          quizzes: (quizResult as Ok<List<QuizSummaryModel>>).value,
        ));
      },
    );
  }
}

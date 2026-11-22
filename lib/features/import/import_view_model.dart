import 'package:flutter/foundation.dart';
import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/core/utils/view_state.dart';
import 'package:quiz_app/data/folder/folder_model.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/domain/use_cases/business/import_quizzes/import_quizzes_argument_model.dart';
import 'package:quiz_app/domain/use_cases/business/import_quizzes/import_quizzes_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/get_folder/get_folder_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/parse_quiz_json/parse_quiz_json_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/parse_quiz_json/quiz_parse_result_model.dart';
import 'package:uuid/uuid.dart';

class ImportBundle {
  final String folderId;

  const ImportBundle({required this.folderId});
}

class ImportFile {
  final String id;
  final String name;
  final int size;
  final QuizParseResultModel? parse;

  const ImportFile({
    required this.id,
    required this.name,
    required this.size,
    required this.parse,
  });

  bool get isValid => parse?.isValid == true;
  QuizImportModel? get quiz => parse?.quiz;
  List<String> get errors => parse?.errors ?? const [];
  bool get repaired => parse?.repaired ?? false;
}

class ImportViewModel {
  ImportViewModel({
    required this.bundle,
    required GetFolderUsecase getFolder,
    required ParseQuizJsonUsecase parseQuizJson,
    required ImportQuizzesUsecase importQuizzes,
  })  : _getFolder = getFolder,
        _parseQuizJson = parseQuizJson,
        _importQuizzes = importQuizzes;

  final ImportBundle bundle;
  final GetFolderUsecase _getFolder;
  final ParseQuizJsonUsecase _parseQuizJson;
  final ImportQuizzesUsecase _importQuizzes;
  final Uuid _uuid = const Uuid();

  final ValueNotifier<ViewState<FolderModel?>> folderState =
      ValueNotifier(const ViewStateLoading());
  final ValueNotifier<List<ImportFile>> files = ValueNotifier(const []);
  final ValueNotifier<bool> reading = ValueNotifier(false);
  final ValueNotifier<ViewState<void>> importState =
      ValueNotifier(const ViewStateIdle());

  Future<void> load() async {
    folderState.value = const ViewStateLoading();
    final result = await _getFolder(bundle.folderId);
    folderState.value = result.fold(
      (failure) => ViewStateError(failure),
      (folder) => folder == null
          ? const ViewStateError(StorageFailure('folder_not_found'))
          : ViewStateLoaded(folder),
    );
  }

  void setReading(bool value) => reading.value = value;

  void addTextFile({
    required String name,
    required int size,
    required String text,
  }) {
    final parse = size > 5 * 1024 * 1024
        ? const QuizParseResultModel(
            quiz: null,
            errors: ['This file is larger than 5 MB.'],
            repaired: false,
          )
        : _parseQuizJson(text);
    files.value = [
      ...files.value,
      ImportFile(
        id: _uuid.v4(),
        name: name,
        size: size,
        parse: parse,
      ),
    ];
  }

  void removeFile(String id) {
    files.value = files.value.where((file) => file.id != id).toList();
  }

  List<ImportFile> get validFiles =>
      files.value.where((file) => file.isValid).toList();

  Future<Result<List<String>>> importAll() async {
    if (importState.value.isLoading) {
      return const Err(StorageFailure('busy'));
    }
    final quizzes = validFiles.map((file) => file.quiz!).toList();
    if (quizzes.isEmpty) {
      return const Err(ValidationFailure('no_quizzes'));
    }

    importState.value = const ViewStateLoading();
    final result = await _importQuizzes(
      ImportQuizzesArgumentModel(folderId: bundle.folderId, quizzes: quizzes),
    );
    importState.value = result.fold(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
    return result;
  }

  void dispose() {
    folderState.dispose();
    files.dispose();
    reading.dispose();
    importState.dispose();
  }
}

import 'package:drift_flutter/drift_flutter.dart';
import 'package:quiz_app/data/attempt/attempt_repository.dart';
import 'package:quiz_app/data/attempt/attempt_repository_interface.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/data/folder/folder_repository.dart';
import 'package:quiz_app/data/folder/folder_repository_interface.dart';
import 'package:quiz_app/data/quiz/quiz_repository.dart';
import 'package:quiz_app/data/quiz/quiz_repository_interface.dart';
import 'package:quiz_app/domain/use_cases/business/complete_attempt/complete_attempt_usecase.dart';
import 'package:quiz_app/domain/use_cases/business/create_folder/create_folder_usecase.dart';
import 'package:quiz_app/domain/use_cases/business/delete_folder/delete_folder_usecase.dart';
import 'package:quiz_app/domain/use_cases/business/delete_quiz/delete_quiz_usecase.dart';
import 'package:quiz_app/domain/use_cases/business/import_quizzes/import_quizzes_usecase.dart';
import 'package:quiz_app/domain/use_cases/business/rename_folder/rename_folder_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/get_attempt_screen/get_attempt_screen_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/get_folder/get_folder_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/get_folder_delete_preview/get_folder_delete_preview_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/get_quiz_screen/get_quiz_screen_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/list_folder_contents/list_folder_contents_usecase.dart';
import 'package:quiz_app/domain/use_cases/ui/parse_quiz_json/parse_quiz_json_usecase.dart';

class AppDependencies {
  static late AppDependencies instance;

  final AppDatabase database;
  final FolderRepositoryInterface folderRepository;
  final QuizRepositoryInterface quizRepository;
  final AttemptRepositoryInterface attemptRepository;

  final CreateFolderUsecase createFolder;
  final RenameFolderUsecase renameFolder;
  final DeleteFolderUsecase deleteFolder;
  final ImportQuizzesUsecase importQuizzes;
  final DeleteQuizUsecase deleteQuiz;
  final CompleteAttemptUsecase completeAttempt;

  final ListFolderContentsUsecase listFolderContents;
  final GetQuizScreenUsecase getQuizScreen;
  final GetAttemptScreenUsecase getAttemptScreen;
  final GetFolderUsecase getFolder;
  final GetFolderDeletePreviewUsecase getFolderDeletePreview;
  final ParseQuizJsonUsecase parseQuizJson;

  AppDependencies._({
    required this.database,
    required this.folderRepository,
    required this.quizRepository,
    required this.attemptRepository,
    required this.createFolder,
    required this.renameFolder,
    required this.deleteFolder,
    required this.importQuizzes,
    required this.deleteQuiz,
    required this.completeAttempt,
    required this.listFolderContents,
    required this.getQuizScreen,
    required this.getAttemptScreen,
    required this.getFolder,
    required this.getFolderDeletePreview,
    required this.parseQuizJson,
  });

  static Future<void> init() async {
    instance = AppDependencies.withDatabase(
      AppDatabase(driftDatabase(name: 'quiz_app')),
    );
  }

  factory AppDependencies.withDatabase(AppDatabase database) {
    final folderRepository = FolderRepository(database);
    final quizRepository = QuizRepository(database);
    final attemptRepository = AttemptRepository(database);

    return AppDependencies._(
      database: database,
      folderRepository: folderRepository,
      quizRepository: quizRepository,
      attemptRepository: attemptRepository,
      createFolder: CreateFolderUsecase(folderRepository),
      renameFolder: RenameFolderUsecase(folderRepository),
      deleteFolder: DeleteFolderUsecase(folderRepository),
      importQuizzes: ImportQuizzesUsecase(quizRepository),
      deleteQuiz: DeleteQuizUsecase(quizRepository),
      completeAttempt: CompleteAttemptUsecase(quizRepository, attemptRepository),
      listFolderContents:
          ListFolderContentsUsecase(folderRepository, quizRepository),
      getQuizScreen: GetQuizScreenUsecase(quizRepository, attemptRepository),
      getAttemptScreen:
          GetAttemptScreenUsecase(attemptRepository, quizRepository),
      getFolder: GetFolderUsecase(folderRepository),
      getFolderDeletePreview:
          GetFolderDeletePreviewUsecase(folderRepository),
      parseQuizJson: ParseQuizJsonUsecase(),
    );
  }

  Future<void> close() => database.close();
}

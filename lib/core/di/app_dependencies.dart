import 'package:drift_flutter/drift_flutter.dart';
import 'package:quiz_app/data/attempt/attempt_repository.dart';
import 'package:quiz_app/data/attempt/attempt_repository_interface.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/data/folder/folder_repository.dart';
import 'package:quiz_app/data/folder/folder_repository_interface.dart';
import 'package:quiz_app/data/quiz/quiz_repository.dart';
import 'package:quiz_app/data/quiz/quiz_repository_interface.dart';

class AppDependencies {
  static late AppDependencies instance;

  final AppDatabase database;
  final FolderRepositoryInterface folderRepository;
  final QuizRepositoryInterface quizRepository;
  final AttemptRepositoryInterface attemptRepository;

  AppDependencies._({
    required this.database,
    required this.folderRepository,
    required this.quizRepository,
    required this.attemptRepository,
  });

  static Future<void> init() async {
    final database = AppDatabase(driftDatabase(name: 'quiz_app'));
    instance = AppDependencies._(
      database: database,
      folderRepository: FolderRepository(database),
      quizRepository: QuizRepository(database),
      attemptRepository: AttemptRepository(database),
    );
  }

  Future<void> close() => database.close();
}

import 'package:quiz_app/data/folder/folder_model.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';

class FolderContentsModel {
  final FolderModel? folder;
  final List<FolderModel> path;
  final List<FolderModel> folders;
  final List<QuizSummaryModel> quizzes;

  const FolderContentsModel({
    required this.folder,
    required this.path,
    required this.folders,
    required this.quizzes,
  });
}

import 'package:quiz_app/data/quiz/quiz_model.dart';

class ImportQuizzesArgumentModel {
  final String folderId;
  final List<QuizImportModel> quizzes;

  const ImportQuizzesArgumentModel({
    required this.folderId,
    required this.quizzes,
  });
}

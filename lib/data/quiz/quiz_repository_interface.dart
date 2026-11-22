import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';

abstract interface class QuizRepositoryInterface {
  Stream<Result<List<QuizSummaryModel>>> watchQuizSummaries(String folderId);

  Future<Result<QuizDetailModel?>> getQuiz(String id);

  Future<Result<List<String>>> importQuizzes(
    String folderId,
    List<QuizImportModel> quizzes,
  );

  Future<Result<void>> deleteQuiz(String id);
}

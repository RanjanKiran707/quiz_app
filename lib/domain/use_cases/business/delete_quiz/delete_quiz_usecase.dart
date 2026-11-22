import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/quiz/quiz_repository_interface.dart';

class DeleteQuizUsecase {
  DeleteQuizUsecase(this._quizzes);

  final QuizRepositoryInterface _quizzes;

  Future<Result<void>> call(String id) => _quizzes.deleteQuiz(id);
}

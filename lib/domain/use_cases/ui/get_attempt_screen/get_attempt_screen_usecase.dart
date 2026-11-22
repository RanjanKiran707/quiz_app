import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/attempt/attempt_repository_interface.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/data/quiz/quiz_repository_interface.dart';
import 'package:quiz_app/domain/use_cases/ui/get_attempt_screen/get_attempt_screen_return_model.dart';

class GetAttemptScreenUsecase {
  GetAttemptScreenUsecase(this._attempts, this._quizzes);

  final AttemptRepositoryInterface _attempts;
  final QuizRepositoryInterface _quizzes;

  Future<Result<AttemptScreenModel>> call(String attemptId) async {
    final attemptResult = await _attempts.getAttempt(attemptId);
    if (attemptResult case Err(:final failure)) return Err(failure);
    final attempt = (attemptResult as Ok<AttemptModel?>).value;
    if (attempt == null) {
      return const Err(StorageFailure('attempt_not_found'));
    }

    final quizResult = await _quizzes.getQuiz(attempt.quizId);
    if (quizResult case Err(:final failure)) return Err(failure);
    final detail = (quizResult as Ok<QuizDetailModel?>).value;

    return Ok(AttemptScreenModel(attempt: attempt, quiz: detail?.quiz));
  }
}

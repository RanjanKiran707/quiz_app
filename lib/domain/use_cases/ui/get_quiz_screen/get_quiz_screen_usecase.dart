import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/attempt/attempt_repository_interface.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/data/quiz/quiz_repository_interface.dart';
import 'package:quiz_app/domain/use_cases/ui/get_quiz_screen/get_quiz_screen_return_model.dart';

class GetQuizScreenUsecase {
  GetQuizScreenUsecase(this._quizzes, this._attempts);

  final QuizRepositoryInterface _quizzes;
  final AttemptRepositoryInterface _attempts;

  Stream<Result<QuizScreenModel>> call(String quizId) async* {
    final quizResult = await _quizzes.getQuiz(quizId);
    if (quizResult case Err(:final failure)) {
      yield Err(failure);
      return;
    }
    final detail = (quizResult as Ok<QuizDetailModel?>).value;
    if (detail == null) {
      yield const Err(StorageFailure('quiz_not_found'));
      return;
    }

    yield* _attempts.watchAttempts(quizId).map(
          (attemptsResult) => attemptsResult.map(
            (attempts) => QuizScreenModel(detail: detail, attempts: attempts),
          ),
        );
  }
}

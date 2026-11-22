import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/attempt/attempt_model.dart';

abstract interface class AttemptRepositoryInterface {
  Stream<Result<List<AttemptModel>>> watchAttempts(String quizId);

  Future<Result<AttemptModel?>> getAttempt(String id);

  Future<Result<void>> saveAttempt(AttemptModel attempt);
}

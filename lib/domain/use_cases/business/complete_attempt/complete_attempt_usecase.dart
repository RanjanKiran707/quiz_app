import 'dart:convert';

import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/attempt/attempt_repository_interface.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/data/quiz/quiz_repository_interface.dart';
import 'package:quiz_app/domain/use_cases/business/complete_attempt/complete_attempt_argument_model.dart';
import 'package:uuid/uuid.dart';

class CompleteAttemptUsecase {
  CompleteAttemptUsecase(this._quizzes, this._attempts);

  final QuizRepositoryInterface _quizzes;
  final AttemptRepositoryInterface _attempts;
  final Uuid _uuid = const Uuid();

  Future<Result<AttemptModel>> call(
    CompleteAttemptArgumentModel arguments,
  ) async {
    if (arguments.endedAt.isBefore(arguments.startedAt)) {
      return const Err(ValidationFailure('attempt_time_invalid'));
    }

    final quizResult = await _quizzes.getQuiz(arguments.quizId);
    if (quizResult case Err(:final failure)) return Err(failure);
    final detail = (quizResult as Ok<QuizDetailModel?>).value;
    if (detail == null) {
      return const Err(StorageFailure('quiz_not_found'));
    }

    var score = 0;
    var maxScore = 0;
    for (final question in detail.questions) {
      maxScore += question.marks;
      if (_isCorrect(question, arguments.answers[question.id])) {
        score += question.marks;
      }
    }

    final attempt = AttemptModel(
      id: _uuid.v4(),
      quizId: arguments.quizId,
      startedAt: arguments.startedAt.toUtc().toIso8601String(),
      endedAt: arguments.endedAt.toUtc().toIso8601String(),
      durationMs:
          arguments.endedAt.difference(arguments.startedAt).inMilliseconds,
      score: score,
      maxScore: maxScore,
      answersJson: jsonEncode(arguments.answers),
    );

    final saved = await _attempts.saveAttempt(attempt);
    return saved.fold(
      (failure) => Err(failure),
      (_) => Ok(attempt),
    );
  }

  bool _isCorrect(QuestionModel question, dynamic answer) {
    switch (question.type) {
      case QuestionType.numerical:
        final value = answer is num
            ? answer.toDouble()
            : double.tryParse(answer?.toString() ?? '');
        if (value == null || question.numericalAnswer == null) return false;
        return (value - question.numericalAnswer!).abs() <=
            (question.tolerance ?? 0) + 1e-9;

      case QuestionType.mcq:
        if (answer is! String) return false;
        final selected = question.options.where((o) => o.id == answer);
        return selected.length == 1 && selected.first.isCorrect;

      case QuestionType.msq:
        if (answer is! List) return false;
        final selected = answer.whereType<String>().toSet();
        final correct =
            question.options.where((o) => o.isCorrect).map((o) => o.id).toSet();
        return selected.length == correct.length &&
            selected.containsAll(correct);
    }
  }
}

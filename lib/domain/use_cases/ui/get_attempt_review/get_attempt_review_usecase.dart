import 'dart:convert';

import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/attempt/attempt_repository_interface.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/data/quiz/quiz_repository_interface.dart';
import 'package:quiz_app/domain/use_cases/ui/get_attempt_review/get_attempt_review_return_model.dart';

class GetAttemptReviewUsecase {
  GetAttemptReviewUsecase(this._attempts, this._quizzes);

  final AttemptRepositoryInterface _attempts;
  final QuizRepositoryInterface _quizzes;

  Future<Result<AttemptReviewModel>> call(String attemptId) async {
    final attemptResult = await _attempts.getAttempt(attemptId);
    if (attemptResult case Err(:final failure)) return Err(failure);
    final attempt = (attemptResult as Ok<AttemptModel?>).value;
    if (attempt == null) {
      return const Err(StorageFailure('attempt_not_found'));
    }

    final quizResult = await _quizzes.getQuiz(attempt.quizId);
    if (quizResult case Err(:final failure)) return Err(failure);
    final detail = (quizResult as Ok<QuizDetailModel?>).value;
    if (detail == null) {
      return const Err(StorageFailure('quiz_not_found'));
    }

    final answers = _decodeAnswers(attempt.answersJson);
    final reviews = [
      for (final question in detail.questions)
        _reviewQuestion(question, answers[question.id]),
    ];

    return Ok(AttemptReviewModel(
      attempt: attempt,
      quiz: detail.quiz,
      reviews: reviews,
    ));
  }

  Map<String, dynamic> _decodeAnswers(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } on FormatException {
      return const {};
    }
    return const {};
  }

  AttemptAnswerReviewModel _reviewQuestion(
    QuestionModel question,
    dynamic answer,
  ) {
    switch (question.type) {
      case QuestionType.numerical:
        return _reviewNumerical(question, answer);
      case QuestionType.mcq:
        return _reviewMcq(question, answer);
      case QuestionType.msq:
        return _reviewMsq(question, answer);
    }
  }

  AttemptAnswerReviewModel _reviewNumerical(
    QuestionModel question,
    dynamic answer,
  ) {
    final entered = _parseNumber(answer);
    final expected = question.numericalAnswer;
    final unit = (question.unit ?? '').trim();
    final suffix = unit.isEmpty ? '' : ' $unit';
    final tolerance = question.tolerance ?? 0;

    final isCorrect = entered != null &&
        expected != null &&
        (entered - expected).abs() <= tolerance + 1e-9;

    final correctDisplay = expected == null
        ? '—'
        : '${_formatNumber(expected)}$suffix'
            '${tolerance > 0 ? ' (±${_formatNumber(tolerance)})' : ''}';

    return AttemptAnswerReviewModel(
      question: question,
      givenAnswer: answer,
      givenDisplay:
          entered == null ? 'No answer' : '${_formatNumber(entered)}$suffix',
      correctDisplay: correctDisplay,
      status: entered == null
          ? AnswerReviewStatus.unanswered
          : isCorrect
              ? AnswerReviewStatus.correct
              : AnswerReviewStatus.incorrect,
    );
  }

  AttemptAnswerReviewModel _reviewMcq(
    QuestionModel question,
    dynamic answer,
  ) {
    final selectedIds = answer is String && answer.isNotEmpty
        ? <String>[answer]
        : const <String>[];
    final selected = question.options
        .where((option) => selectedIds.contains(option.id));
    final correct = question.options.where((option) => option.isCorrect);

    final isUnanswered = selectedIds.isEmpty;
    final isCorrect = selected.length == 1 &&
        selected.first.isCorrect &&
        selectedIds.length == 1;

    return AttemptAnswerReviewModel(
      question: question,
      givenAnswer: answer,
      givenDisplay: isUnanswered
          ? 'No answer'
          : selected.isEmpty
              ? 'Unknown option'
              : selected.first.text,
      correctDisplay: correct.isEmpty ? '—' : correct.first.text,
      status: isUnanswered
          ? AnswerReviewStatus.unanswered
          : isCorrect
              ? AnswerReviewStatus.correct
              : AnswerReviewStatus.incorrect,
    );
  }

  AttemptAnswerReviewModel _reviewMsq(
    QuestionModel question,
    dynamic answer,
  ) {
    final selectedIds = answer is List
        ? answer.whereType<String>().toSet()
        : const <String>{};
    final selected = question.options
        .where((option) => selectedIds.contains(option.id));
    final correct = question.options.where((option) => option.isCorrect);

    final correctIds = correct.map((option) => option.id).toSet();
    final isUnanswered = selectedIds.isEmpty;
    final isCorrect = selectedIds.length == correctIds.length &&
        selectedIds.containsAll(correctIds);

    return AttemptAnswerReviewModel(
      question: question,
      givenAnswer: answer,
      givenDisplay: isUnanswered
          ? 'No answer'
          : selected.isEmpty
              ? 'Unknown options'
              : selected.map((option) => option.text).join(' · '),
      correctDisplay:
          correct.isEmpty ? '—' : correct.map((option) => option.text).join(' · '),
      status: isUnanswered
          ? AnswerReviewStatus.unanswered
          : isCorrect
              ? AnswerReviewStatus.correct
              : AnswerReviewStatus.incorrect,
    );
  }

  double? _parseNumber(dynamic answer) {
    if (answer is num) return answer.toDouble();
    final text = answer?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}

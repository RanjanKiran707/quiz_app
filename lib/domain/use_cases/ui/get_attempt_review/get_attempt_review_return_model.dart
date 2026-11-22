import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';

enum AnswerReviewStatus { correct, incorrect, unanswered }

class AttemptAnswerReviewModel {
  final QuestionModel question;
  final dynamic givenAnswer;
  final String givenDisplay;
  final String correctDisplay;
  final AnswerReviewStatus status;

  const AttemptAnswerReviewModel({
    required this.question,
    required this.givenAnswer,
    required this.givenDisplay,
    required this.correctDisplay,
    required this.status,
  });

  bool get isCorrect => status == AnswerReviewStatus.correct;
  bool get isUnanswered => status == AnswerReviewStatus.unanswered;
}

class AttemptReviewModel {
  final AttemptModel attempt;
  final QuizModel quiz;
  final List<AttemptAnswerReviewModel> reviews;

  const AttemptReviewModel({
    required this.attempt,
    required this.quiz,
    required this.reviews,
  });

  int get correctCount =>
      reviews.where((review) => review.isCorrect).length;

  int get incorrectCount => reviews
      .where((review) => review.status == AnswerReviewStatus.incorrect)
      .length;

  int get unansweredCount =>
      reviews.where((review) => review.isUnanswered).length;
}

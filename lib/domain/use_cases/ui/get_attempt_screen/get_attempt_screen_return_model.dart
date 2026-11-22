import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';

class AttemptScreenModel {
  final AttemptModel attempt;
  final QuizModel? quiz;

  const AttemptScreenModel({required this.attempt, required this.quiz});
}

import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';

class QuizScreenModel {
  final QuizDetailModel detail;
  final List<AttemptModel> attempts;

  const QuizScreenModel({required this.detail, required this.attempts});
}

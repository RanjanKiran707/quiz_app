import 'package:quiz_app/data/quiz/quiz_model.dart';

class QuizParseResultModel {
  final QuizImportModel? quiz;
  final List<String> errors;
  final bool repaired;

  const QuizParseResultModel({
    required this.quiz,
    required this.errors,
    required this.repaired,
  });

  bool get isValid => quiz != null && errors.isEmpty;
}

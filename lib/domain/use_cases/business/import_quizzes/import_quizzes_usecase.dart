import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/data/quiz/quiz_repository_interface.dart';
import 'package:quiz_app/domain/use_cases/business/import_quizzes/import_quizzes_argument_model.dart';

class ImportQuizzesUsecase {
  ImportQuizzesUsecase(this._quizzes);

  final QuizRepositoryInterface _quizzes;

  Future<Result<void>> call(ImportQuizzesArgumentModel arguments) async {
    if (arguments.quizzes.isEmpty) {
      return const Err(ValidationFailure('no_quizzes'));
    }

    for (final quiz in arguments.quizzes) {
      if (quiz.title.trim().isEmpty) {
        return const Err(ValidationFailure('quiz_title_required'));
      }
      if (quiz.questions.isEmpty) {
        return const Err(ValidationFailure('quiz_questions_required'));
      }

      for (final question in quiz.questions) {
        if (question.prompt.trim().isEmpty) {
          return const Err(ValidationFailure('question_prompt_required'));
        }
        if (question.marks <= 0) {
          return const Err(ValidationFailure('question_marks_invalid'));
        }

        switch (question.type) {
          case QuestionType.mcq:
            final correct = question.options.where((o) => o.isCorrect).length;
            if (correct != 1) {
              return const Err(ValidationFailure('mcq_correct_required'));
            }
          case QuestionType.msq:
            if (!question.options.any((o) => o.isCorrect)) {
              return const Err(ValidationFailure('msq_correct_required'));
            }
          case QuestionType.numerical:
            if (question.numericalAnswer == null) {
              return const Err(ValidationFailure('numerical_answer_required'));
            }
        }
      }
    }

    return _quizzes.importQuizzes(arguments.folderId, arguments.quizzes);
  }
}

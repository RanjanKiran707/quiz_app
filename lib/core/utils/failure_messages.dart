import 'package:quiz_app/core/errors/failure.dart';

const _messages = <String, String>{
  'folder_name_required': 'Give the folder a name.',
  'folder_name_too_long': 'Folder names can be up to 60 characters.',
  'folder_name_taken': 'A folder with this name already exists here.',
  'folder_not_found': 'This folder no longer exists.',
  'quiz_not_found': 'This quiz no longer exists.',
  'attempt_not_found': 'This attempt no longer exists.',
  'no_quizzes': 'There are no valid quizzes to import.',
  'quiz_title_required': 'The quiz needs a title.',
  'quiz_questions_required': 'This quiz has no questions.',
  'question_prompt_required': 'A question is missing its text.',
  'question_marks_invalid': 'A question has an invalid mark value.',
  'mcq_correct_required': 'An MCQ must have exactly one correct option.',
  'msq_correct_required': 'An MSQ must have at least one correct option.',
  'numerical_answer_required': 'A numerical question needs a numeric answer.',
  'attempt_time_invalid': 'The attempt timestamps are invalid.',
  'storage_error': 'The local database is unavailable. Please try again.',
};

String messageFor(Failure failure) {
  final mapped = _messages[failure.message];
  if (mapped != null) return mapped;
  if (failure is StorageFailure) {
    return 'The local database is unavailable. Please try again.';
  }
  if (failure is ValidationFailure) {
    return 'Please check the input and try again.';
  }
  return 'Something went wrong. Please try again.';
}

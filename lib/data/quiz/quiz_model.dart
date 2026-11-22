import 'package:drift/drift.dart';
import 'package:quiz_app/data/database/app_database.dart';

enum QuestionType {
  mcq,
  msq,
  numerical;

  String get dbValue => name;

  String get label => switch (this) {
        QuestionType.mcq => 'MCQ',
        QuestionType.msq => 'MSQ',
        QuestionType.numerical => 'Numerical',
      };

  static QuestionType fromDb(String value) => switch (value) {
        'mcq' => mcq,
        'msq' => msq,
        'numerical' => numerical,
        _ => throw ArgumentError('Unknown question type: $value'),
      };
}

class QuizModel {
  final String id;
  final String folderId;
  final String title;
  final String? subtitle;
  final String? sourceKey;
  final String createdAt;

  const QuizModel({
    required this.id,
    required this.folderId,
    required this.title,
    required this.subtitle,
    required this.sourceKey,
    required this.createdAt,
  });

  factory QuizModel.fromRow(Quiz row) => QuizModel(
        id: row.id,
        folderId: row.folderId,
        title: row.title,
        subtitle: row.subtitle,
        sourceKey: row.sourceKey,
        createdAt: row.createdAt,
      );

  QuizzesCompanion toCompanion() => QuizzesCompanion.insert(
        id: id,
        folderId: folderId,
        title: title,
        subtitle: Value(subtitle),
        sourceKey: Value(sourceKey),
        createdAt: createdAt,
      );
}

class QuestionOptionModel {
  final String id;
  final String questionId;
  final String text;
  final bool isCorrect;
  final int position;

  const QuestionOptionModel({
    required this.id,
    required this.questionId,
    required this.text,
    required this.isCorrect,
    required this.position,
  });

  factory QuestionOptionModel.fromRow(QuestionOption row) =>
      QuestionOptionModel(
        id: row.id,
        questionId: row.questionId,
        text: row.optionText,
        isCorrect: row.isCorrect,
        position: row.position,
      );

  QuestionOptionsCompanion toCompanion() => QuestionOptionsCompanion.insert(
        id: id,
        questionId: questionId,
        optionText: text,
        isCorrect: Value(isCorrect),
        position: position,
      );
}

class QuestionModel {
  final String id;
  final String quizId;
  final String prompt;
  final QuestionType type;
  final int marks;
  final int position;
  final String? difficulty;
  final String? explanation;
  final String? unit;
  final double? numericalAnswer;
  final double? tolerance;
  final List<QuestionOptionModel> options;

  const QuestionModel({
    required this.id,
    required this.quizId,
    required this.prompt,
    required this.type,
    required this.marks,
    required this.position,
    required this.difficulty,
    required this.explanation,
    required this.unit,
    required this.numericalAnswer,
    required this.tolerance,
    this.options = const [],
  });

  factory QuestionModel.fromRow(
    Question row, {
    List<QuestionOptionModel> options = const [],
  }) =>
      QuestionModel(
        id: row.id,
        quizId: row.quizId,
        prompt: row.prompt,
        type: QuestionType.fromDb(row.type),
        marks: row.marks,
        position: row.position,
        difficulty: row.difficulty,
        explanation: row.explanation,
        unit: row.unit,
        numericalAnswer: row.numericalAnswer,
        tolerance: row.tolerance,
        options: options,
      );

  QuestionsCompanion toCompanion() => QuestionsCompanion.insert(
        id: id,
        quizId: quizId,
        prompt: prompt,
        type: type.dbValue,
        marks: Value(marks),
        position: position,
        difficulty: Value(difficulty),
        explanation: Value(explanation),
        unit: Value(unit),
        numericalAnswer: Value(numericalAnswer),
        tolerance: Value(tolerance),
      );
}

class QuizDetailModel {
  final QuizModel quiz;
  final List<QuestionModel> questions;

  const QuizDetailModel({required this.quiz, required this.questions});
}

class QuizSummaryModel {
  final String id;
  final String folderId;
  final String title;
  final String? subtitle;
  final String createdAt;
  final int questionCount;
  final int totalMarks;
  final int attemptCount;
  final int? lastScore;
  final int? lastMaxScore;
  final String? lastAttemptAt;

  const QuizSummaryModel({
    required this.id,
    required this.folderId,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.questionCount,
    required this.totalMarks,
    required this.attemptCount,
    required this.lastScore,
    required this.lastMaxScore,
    required this.lastAttemptAt,
  });
}

class OptionImportModel {
  final String text;
  final bool isCorrect;
  final int position;

  const OptionImportModel({
    required this.text,
    required this.isCorrect,
    required this.position,
  });
}

class QuestionImportModel {
  final String prompt;
  final QuestionType type;
  final int marks;
  final int position;
  final String? difficulty;
  final String? explanation;
  final String? unit;
  final double? numericalAnswer;
  final double? tolerance;
  final List<OptionImportModel> options;

  const QuestionImportModel({
    required this.prompt,
    required this.type,
    this.marks = 1,
    required this.position,
    this.difficulty,
    this.explanation,
    this.unit,
    this.numericalAnswer,
    this.tolerance,
    this.options = const [],
  });
}

class QuizImportModel {
  final String title;
  final String? subtitle;
  final String? sourceKey;
  final List<QuestionImportModel> questions;

  const QuizImportModel({
    required this.title,
    this.subtitle,
    this.sourceKey,
    required this.questions,
  });
}

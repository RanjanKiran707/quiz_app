import 'package:drift/drift.dart';
import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/data/database/result_stream.dart';
import 'package:quiz_app/data/quiz/quiz_model.dart';
import 'package:quiz_app/data/quiz/quiz_repository_interface.dart';
import 'package:uuid/uuid.dart';

class QuizRepository implements QuizRepositoryInterface {
  QuizRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Stream<Result<List<QuizSummaryModel>>> watchQuizSummaries(String folderId) {
    final query = _db.customSelect(
      '''
      SELECT
        q.id AS id,
        q.folder_id AS folder_id,
        q.title AS title,
        q.subtitle AS subtitle,
        q.created_at AS created_at,
        (SELECT COUNT(*) FROM questions qu WHERE qu.quiz_id = q.id) AS question_count,
        (SELECT COALESCE(SUM(qu.marks), 0) FROM questions qu WHERE qu.quiz_id = q.id) AS total_marks,
        (SELECT COUNT(*) FROM attempts a WHERE a.quiz_id = q.id) AS attempt_count,
        (SELECT a.score FROM attempts a WHERE a.quiz_id = q.id ORDER BY a.started_at DESC LIMIT 1) AS last_score,
        (SELECT a.max_score FROM attempts a WHERE a.quiz_id = q.id ORDER BY a.started_at DESC LIMIT 1) AS last_max_score,
        (SELECT a.started_at FROM attempts a WHERE a.quiz_id = q.id ORDER BY a.started_at DESC LIMIT 1) AS last_attempt_at
      FROM quizzes q
      WHERE q.folder_id = ?
      ORDER BY q.created_at DESC
      ''',
      variables: [Variable<String>(folderId)],
      readsFrom: {_db.quizzes, _db.questions, _db.attempts},
    );

    return resultStream(
      query.watch(),
      (rows) => rows
          .map(
            (row) => QuizSummaryModel(
              id: row.read<String>('id'),
              folderId: row.read<String>('folder_id'),
              title: row.read<String>('title'),
              subtitle: row.read<String?>('subtitle'),
              createdAt: row.read<String>('created_at'),
              questionCount: row.read<int>('question_count'),
              totalMarks: row.read<int>('total_marks'),
              attemptCount: row.read<int>('attempt_count'),
              lastScore: row.read<int?>('last_score'),
              lastMaxScore: row.read<int?>('last_max_score'),
              lastAttemptAt: row.read<String?>('last_attempt_at'),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<Result<QuizDetailModel?>> getQuiz(String id) async {
    try {
      final quizRow = await (_db.select(_db.quizzes)
            ..where((table) => table.id.equals(id)))
          .getSingleOrNull();
      if (quizRow == null) return const Ok(null);

      final questionRows = await (_db.select(_db.questions)
            ..where((table) => table.quizId.equals(id))
            ..orderBy([(table) => OrderingTerm.asc(table.position)]))
          .get();
      final questionIds = questionRows.map((row) => row.id).toList();

      final optionsByQuestion = <String, List<QuestionOptionModel>>{};
      if (questionIds.isNotEmpty) {
        final optionRows = await (_db.select(_db.questionOptions)
              ..where((table) => table.questionId.isIn(questionIds))
              ..orderBy([(table) => OrderingTerm.asc(table.position)]))
            .get();
        for (final row in optionRows) {
          optionsByQuestion
              .putIfAbsent(row.questionId, () => [])
              .add(QuestionOptionModel.fromRow(row));
        }
      }

      return Ok(QuizDetailModel(
        quiz: QuizModel.fromRow(quizRow),
        questions: questionRows
            .map((row) => QuestionModel.fromRow(
                  row,
                  options: optionsByQuestion[row.id] ?? const [],
                ))
            .toList(),
      ));
    } catch (error) {
      return Err(StorageFailure(error.toString()));
    }
  }

  @override
  Future<Result<List<String>>> importQuizzes(
    String folderId,
    List<QuizImportModel> quizzes,
  ) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final importedIds = <String>[];

      await _db.transaction(() async {
        for (final quiz in quizzes) {
          final quizId = _uuid.v4();
          importedIds.add(quizId);
          await _db.into(_db.quizzes).insert(
                QuizModel(
                  id: quizId,
                  folderId: folderId,
                  title: quiz.title,
                  subtitle: quiz.subtitle,
                  sourceKey: quiz.sourceKey,
                  createdAt: now,
                ).toCompanion(),
              );

          for (final question in quiz.questions) {
            final questionId = _uuid.v4();
            await _db.into(_db.questions).insert(
                  QuestionModel(
                    id: questionId,
                    quizId: quizId,
                    prompt: question.prompt,
                    type: question.type,
                    marks: question.marks,
                    position: question.position,
                    difficulty: question.difficulty,
                    explanation: question.explanation,
                    unit: question.unit,
                    numericalAnswer: question.numericalAnswer,
                    tolerance: question.tolerance,
                  ).toCompanion(),
                );

            for (final option in question.options) {
              await _db.into(_db.questionOptions).insert(
                    QuestionOptionModel(
                      id: _uuid.v4(),
                      questionId: questionId,
                      text: option.text,
                      isCorrect: option.isCorrect,
                      position: option.position,
                    ).toCompanion(),
                  );
            }
          }
        }
      });

      return Ok(importedIds);
    } catch (error) {
      return Err(StorageFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> deleteQuiz(String id) async {
    try {
      final quizRow = await (_db.select(_db.quizzes)
            ..where((table) => table.id.equals(id)))
          .getSingleOrNull();
      if (quizRow == null) {
        return const Err(StorageFailure('Quiz not found.'));
      }

      final questionRows = await (_db.select(_db.questions)
            ..where((table) => table.quizId.equals(id)))
          .get();
      final questionIds = questionRows.map((row) => row.id).toList();

      await _db.transaction(() async {
        await (_db.delete(_db.attempts)
              ..where((table) => table.quizId.equals(id)))
            .go();
        if (questionIds.isNotEmpty) {
          await (_db.delete(_db.questionOptions)
                ..where((table) => table.questionId.isIn(questionIds)))
              .go();
        }
        await (_db.delete(_db.questions)
              ..where((table) => table.quizId.equals(id)))
            .go();
        await (_db.delete(_db.quizzes)
              ..where((table) => table.id.equals(id)))
            .go();
      });

      return const Ok(null);
    } catch (error) {
      return Err(StorageFailure(error.toString()));
    }
  }
}

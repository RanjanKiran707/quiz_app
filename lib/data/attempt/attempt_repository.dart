import 'package:drift/drift.dart';
import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/attempt/attempt_model.dart';
import 'package:quiz_app/data/attempt/attempt_repository_interface.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/data/database/result_stream.dart';

class AttemptRepository implements AttemptRepositoryInterface {
  AttemptRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<Result<List<AttemptModel>>> watchAttempts(String quizId) {
    final query = _db.select(_db.attempts)
      ..where((table) => table.quizId.equals(quizId))
      ..orderBy([(table) => OrderingTerm.desc(table.startedAt)]);

    return resultStream(
      query.watch(),
      (rows) => rows.map(AttemptModel.fromRow).toList(),
    );
  }

  @override
  Future<Result<AttemptModel?>> getAttempt(String id) async {
    try {
      final row = await (_db.select(_db.attempts)
            ..where((table) => table.id.equals(id)))
          .getSingleOrNull();
      return Ok(row == null ? null : AttemptModel.fromRow(row));
    } catch (error) {
      return Err(StorageFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> saveAttempt(AttemptModel attempt) async {
    try {
      await _db.into(_db.attempts).insert(attempt.toCompanion());
      return const Ok(null);
    } catch (error) {
      return Err(StorageFailure(error.toString()));
    }
  }
}

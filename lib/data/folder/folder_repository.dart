import 'package:drift/drift.dart';
import 'package:quiz_app/core/errors/failure.dart';
import 'package:quiz_app/core/errors/result.dart';
import 'package:quiz_app/data/database/app_database.dart';
import 'package:quiz_app/data/database/result_stream.dart';
import 'package:quiz_app/data/folder/folder_model.dart';
import 'package:quiz_app/data/folder/folder_repository_interface.dart';
import 'package:uuid/uuid.dart';

class FolderRepository implements FolderRepositoryInterface {
  FolderRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Stream<Result<List<FolderModel>>> watchChildFolders(String? parentId) {
    final query = _db.select(_db.folders)
      ..where((table) => parentId == null
          ? table.parentFolderId.isNull()
          : table.parentFolderId.equals(parentId))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);

    return resultStream(
      query.watch(),
      (rows) => rows.map(FolderModel.fromRow).toList(),
    );
  }

  @override
  Future<Result<FolderModel?>> getFolder(String id) async {
    try {
      final row = await (_db.select(_db.folders)
            ..where((table) => table.id.equals(id)))
          .getSingleOrNull();
      return Ok(row == null ? null : FolderModel.fromRow(row));
    } catch (error) {
      return Err(StorageFailure(error.toString()));
    }
  }

  @override
  Future<Result<List<FolderModel>>> getFolderPath(String id) async {
    try {
      final path = <FolderModel>[];
      String? currentId = id;
      var guard = 0;

      while (currentId != null && guard++ < 100) {
        final folderId = currentId;
        final row = await (_db.select(_db.folders)
              ..where((table) => table.id.equals(folderId)))
            .getSingleOrNull();
        if (row == null) break;

        path.insert(0, FolderModel.fromRow(row));
        currentId = row.parentFolderId;
      }

      return Ok(path);
    } catch (error) {
      return Err(StorageFailure(error.toString()));
    }
  }

  @override
  Future<Result<FolderModel>> createFolder({
    required String? parentId,
    required String name,
  }) async {
    try {
      final folder = FolderModel(
        id: _uuid.v4(),
        name: name,
        parentFolderId: parentId,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );
      await _db.into(_db.folders).insert(folder.toCompanion());
      return Ok(folder);
    } catch (error) {
      return Err(StorageFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> renameFolder(String id, String name) async {
    try {
      final updated = await (_db.update(_db.folders)
            ..where((table) => table.id.equals(id)))
          .write(FoldersCompanion(name: Value(name)));

      if (updated == 0) {
        return const Err(StorageFailure('Folder not found.'));
      }
      return const Ok(null);
    } catch (error) {
      return Err(StorageFailure(error.toString()));
    }
  }

  @override
  Future<Result<void>> deleteFolder(String id) async {
    try {
      final folderIds = await _folderIdsUnder(id);
      if (folderIds.isEmpty) {
        return const Err(StorageFailure('Folder not found.'));
      }

      final quizRows = await (_db.select(_db.quizzes)
            ..where((table) => table.folderId.isIn(folderIds)))
          .get();
      final quizIds = quizRows.map((row) => row.id).toList();

      var questionIds = <String>[];
      if (quizIds.isNotEmpty) {
        final questionRows = await (_db.select(_db.questions)
              ..where((table) => table.quizId.isIn(quizIds)))
            .get();
        questionIds = questionRows.map((row) => row.id).toList();
      }

      await _db.transaction(() async {
        if (quizIds.isNotEmpty) {
          await (_db.delete(_db.attempts)
                ..where((table) => table.quizId.isIn(quizIds)))
              .go();
        }
        if (questionIds.isNotEmpty) {
          await (_db.delete(_db.questionOptions)
                ..where((table) => table.questionId.isIn(questionIds)))
              .go();
        }
        if (quizIds.isNotEmpty) {
          await (_db.delete(_db.questions)
                ..where((table) => table.quizId.isIn(quizIds)))
              .go();
          await (_db.delete(_db.quizzes)
                ..where((table) => table.id.isIn(quizIds)))
              .go();
        }
        await (_db.delete(_db.folders)
              ..where((table) => table.id.isIn(folderIds)))
            .go();
      });

      return const Ok(null);
    } catch (error) {
      return Err(StorageFailure(error.toString()));
    }
  }

  @override
  Future<Result<FolderDeletePreviewModel>> getDeletePreview(
    String id,
  ) async {
    try {
      final folder = await getFolder(id);
      final folderModel = folder.valueOrNull;
      if (folderModel == null) {
        return const Err(StorageFailure('Folder not found.'));
      }

      final folderIds = await _folderIdsUnder(id);
      final quizRows = await (_db.select(_db.quizzes)
            ..where((table) => table.folderId.isIn(folderIds)))
          .get();
      final quizIds = quizRows.map((row) => row.id).toList();

      var questionCount = 0;
      var attemptCount = 0;
      if (quizIds.isNotEmpty) {
        final questionRows = await (_db.select(_db.questions)
              ..where((table) => table.quizId.isIn(quizIds)))
            .get();
        questionCount = questionRows.length;
        final attemptRows = await (_db.select(_db.attempts)
              ..where((table) => table.quizId.isIn(quizIds)))
            .get();
        attemptCount = attemptRows.length;
      }

      return Ok(FolderDeletePreviewModel(
        folder: folderModel,
        folders: folderIds.length - 1,
        quizzes: quizIds.length,
        attempts: attemptCount,
        questions: questionCount,
      ));
    } catch (error) {
      return Err(StorageFailure(error.toString()));
    }
  }

  @override
  Future<Result<bool>> isNameTaken({
    required String? parentId,
    required String name,
    String? excludeId,
  }) async {
    try {
      final rows = await (_db.select(_db.folders)
            ..where((table) => parentId == null
                ? table.parentFolderId.isNull()
                : table.parentFolderId.equals(parentId)))
          .get();
      final lowered = name.toLowerCase();
      final taken = rows.any((row) =>
          row.id != excludeId && row.name.toLowerCase() == lowered);
      return Ok(taken);
    } catch (error) {
      return Err(StorageFailure(error.toString()));
    }
  }

  Future<List<String>> _folderIdsUnder(String id) async {
    final ids = <String>[];
    final queue = <String>[id];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final row = await (_db.select(_db.folders)
            ..where((table) => table.id.equals(current)))
          .getSingleOrNull();
      if (row == null) continue;

      ids.add(current);
      final children = await (_db.select(_db.folders)
            ..where((table) => table.parentFolderId.equals(current)))
          .get();
      queue.addAll(children.map((child) => child.id));
    }

    return ids;
  }
}

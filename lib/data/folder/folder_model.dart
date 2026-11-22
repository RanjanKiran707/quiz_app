import 'package:drift/drift.dart';
import 'package:quiz_app/data/database/app_database.dart';

class FolderModel {
  final String id;
  final String name;
  final String? parentFolderId;
  final String createdAt;

  const FolderModel({
    required this.id,
    required this.name,
    required this.parentFolderId,
    required this.createdAt,
  });

  factory FolderModel.fromRow(Folder row) => FolderModel(
        id: row.id,
        name: row.name,
        parentFolderId: row.parentFolderId,
        createdAt: row.createdAt,
      );

  FoldersCompanion toCompanion() => FoldersCompanion.insert(
        id: id,
        name: name,
        parentFolderId: Value(parentFolderId),
        createdAt: createdAt,
      );
}

class FolderDeletePreviewModel {
  final FolderModel folder;
  final int folders;
  final int quizzes;
  final int attempts;
  final int questions;

  const FolderDeletePreviewModel({
    required this.folder,
    required this.folders,
    required this.quizzes,
    required this.attempts,
    required this.questions,
  });
}

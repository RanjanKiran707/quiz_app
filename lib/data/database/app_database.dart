import 'package:drift/drift.dart';

part 'app_database.g.dart';

@TableIndex(name: 'folder_parent', columns: {#parentFolderId})
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get parentFolderId => text()
      .nullable()
      .references(Folders, #id, onDelete: KeyAction.cascade)();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Quiz')
@TableIndex(name: 'quiz_folder', columns: {#folderId})
class Quizzes extends Table {
  TextColumn get id => text()();
  TextColumn get folderId =>
      text().references(Folders, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get sourceKey => text().nullable()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'question_quiz_position', columns: {#quizId, #position})
class Questions extends Table {
  TextColumn get id => text()();
  TextColumn get quizId =>
      text().references(Quizzes, #id, onDelete: KeyAction.cascade)();
  TextColumn get prompt => text()();
  TextColumn get type =>
      text().customConstraint("NOT NULL CHECK (type IN ('mcq','msq','numerical'))")();
  IntColumn get marks => integer().withDefault(const Constant(1))();
  IntColumn get position => integer()();
  TextColumn get difficulty => text().nullable()();
  TextColumn get explanation => text().nullable()();
  TextColumn get unit => text().nullable()();
  RealColumn get numericalAnswer => real().nullable()();
  RealColumn get tolerance => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'option_question_position', columns: {#questionId, #position})
class QuestionOptions extends Table {
  TextColumn get id => text()();
  TextColumn get questionId =>
      text().references(Questions, #id, onDelete: KeyAction.cascade)();
  TextColumn get optionText => text().named('text')();
  BoolColumn get isCorrect => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'attempt_quiz_started', columns: {#quizId, #startedAt})
class Attempts extends Table {
  TextColumn get id => text()();
  TextColumn get quizId =>
      text().references(Quizzes, #id, onDelete: KeyAction.cascade)();
  TextColumn get startedAt => text()();
  TextColumn get endedAt => text()();
  IntColumn get durationMs => integer()();
  IntColumn get score => integer()();
  IntColumn get maxScore => integer()();
  TextColumn get answersJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [Folders, Quizzes, Questions, QuestionOptions, Attempts],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

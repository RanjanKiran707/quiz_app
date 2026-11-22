# Data layer progress

Status: Done
Last updated: 2026-11-22

## Checklist

| Item | Code | Tests |
|---|---|---|
| Core types (`Failure`, `Result`, `ViewState`, `ObxValue`, DI) | [x] | [x] |
| Drift database (`folders`, `quizzes`, `questions`, `question_options`, `attempts`) | [x] | [x] |
| Folder model, repository interface and implementation | [x] | [x] |
| Quiz model, repository interface and implementation | [x] | [x] |
| Attempt model, repository interface and implementation | [x] | [x] |
| Foreign-key cascade / explicit cascade deletion | [x] | [x] |
| In-memory database tests | [x] | [x] |

## Test status

Passing, 14 tests, 2026-11-22.

```
flutter analyze  -> No issues found
flutter test     -> All tests passed (14)
```

## Change log

Newest first.

| Date | Change | Why |
|---|---|---|
| 2026-11-22 | Phase started | Begin the data layer from `docs/data_model.html` |
| 2026-11-22 | Added Drift schema and generated `app_database.g.dart` | Typed SQLite storage with foreign keys and reactive watches |
| 2026-11-22 | Added folder, quiz and attempt repositories | Data access for all entities |
| 2026-11-22 | Added repository tests against `NativeDatabase.memory()` | Verify persistence, ordering, counts and cascades |
| 2026-11-22 | Added `AppDependencies` and wired `main.dart` | One place creates the database and repositories |

## Open issues / decisions

- `QuestionOptions.text` uses the Dart getter `optionText` with the SQL column name `text` so it does not shadow Drift's `text()` builder. The model keeps the public field name `text`.
- `questions.marks` has a database default of 1; the `> 0` rule is enforced by the domain layer (import validation and use cases).
- `deleteFolder` and `deleteQuiz` perform explicit cascade deletes inside a transaction rather than relying only on SQLite foreign keys. Foreign keys are still enabled in `beforeOpen`.
- `Result<void>` success is `Ok(null)`; tests assert `Ok<void>` explicitly.
- The app has no HTTP client. Repositories read and write Drift directly.
- `package:flutter/material.dart` is reported as deprecated on Flutter 3.50.1; `// ignore_for_file: deprecated_member_use` is used until the Material UI migration is agreed.

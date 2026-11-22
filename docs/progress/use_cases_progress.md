# Use cases progress

Status: Done
Last updated: 2026-11-22

## Checklist

| Item | Code | Tests |
|---|---|---|
| Create folder (validation + duplicate siblings) | [x] | [x] |
| Rename folder (validation + duplicate siblings) | [x] | [x] |
| Delete folder (pass-through) | [x] | [x] |
| Import quizzes (defensive validation) | [x] | [x] |
| Delete quiz (pass-through) | [x] | [x] |
| Complete attempt (scoring MCQ / MSQ / numerical, save attempt) | [x] | [x] |
| List folder contents (folder + path + folders + quiz summaries) | [x] | [x] |
| Get quiz screen (detail + live attempts) | [x] | [x] |
| Get attempt screen (attempt + quiz) | [x] | [x] |
| Get folder (import target) | [x] | [x] |
| Get folder delete preview | [x] | [x] |
| Parse quiz JSON (backslash repair + validation) | [x] | [x] |
| AppDependencies wiring | [x] | — |

## Test status

Passing, 27 tests, 2026-11-22.

```
flutter analyze  -> No issues found
flutter test     -> All tests passed (27)
```

## Change log

Newest first.

| Date | Change | Why |
|---|---|---|
| 2026-11-22 | Phase started | Implement the domain layer |
| 2026-11-22 | Added business use cases | Folder CRUD, import, delete quiz, complete attempt |
| 2026-11-22 | Added UI use cases | Folder contents, quiz screen, attempt screen, folder lookup |
| 2026-11-22 | Added pure JSON parser | Repairs unescaped LaTeX and validates the compact schema |
| 2026-11-22 | Added `combineLatest2` helper | Combine Drift watch streams without another package |
| 2026-11-22 | Wired every use case in `AppDependencies` | Single startup graph |

## Open issues / decisions

- `CompleteAttemptUsecase` computes the score from the quiz snapshot. MCQ requires the selected option id; MSQ requires an exact set; numerical uses the question tolerance (0 by default).
- Business use case failures use short codes (`folder_name_required`, `folder_name_taken`, etc.) that the View maps to copy.
- `ParseQuizJsonUsecase` returns `QuizParseResultModel` instead of `Result` because a malformed file yields multiple user-facing validation errors. A file that parses is still a `QuizImportModel` even when it has validation errors, so the preview can show its title and question counts.
- UI use cases use `Stream` for live folder/quiz/attempt data. The path and quiz detail are fetched once per screen; the attempt list stays live.
- No HTTP client exists; every use case reaches Drift through repositories.

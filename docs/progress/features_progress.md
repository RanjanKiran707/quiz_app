# Features progress

Status: Done
Last updated: 2026-11-22

## Checklist

| Feature | Code | ViewModel tests | Widget / integration tests |
|---|---|---|---|
| Shared theme, fonts, math text and UI components | [x] | — | [x] |
| Folder browser (root + nested, breadcrumb, lists) | [x] | [x] | [x] |
| Folder create / rename / delete dialogs | [x] | [x] | [x] |
| Quiz delete from the browser and detail | [x] | [x] | [x] |
| Import (file picker, validation, preview, batch import) | [x] | [x] | [x] |
| Quiz detail (metadata, start, attempt history) | [x] | — | [x] |
| Attempt (pre-start, timer, MCQ/MSQ/NAT, end/discard) | [x] | [x] | [x] |
| Result / attempt summary (score, accuracy, time, date) | [x] | — | [x] |
| Attempt answer review (status, both answers, explanation) | [x] | [x] | [x] |
| App shell and navigation | [x] | — | [x] |
| Key journey integration test | — | — | [x] |

## Test status

Passing, 40 unit/widget tests + 1 integration test, 2026-11-22.

```
flutter analyze                         -> No issues found
flutter test                            -> All tests passed (40)
flutter test integration_test -d windows -> All tests passed (1)
```

The integration test covers: create a folder → seed a quiz → open the folder →
open the quiz → start an attempt → answer an MCQ → End → result with 100% →
open Review answers and see both answers and the correct status.

## Change log

Newest first.

| Date | Change | Why |
|---|---|---|
| 2026-11-22 | Phase started | Build the features from the approved mockup |
| 2026-11-22 | Added theme, fonts, math text and shared widgets | Match the mockup’s visual system |
| 2026-11-22 | Added folder browser and folder dialogs | First feature |
| 2026-11-22 | Added import flow | File picker, JSON validation, preview and batch import |
| 2026-11-22 | Added quiz detail and attempt flow | Core quiz-taking journey |
| 2026-11-22 | Added result and history summary | Score, accuracy, duration and date |
| 2026-11-22 | Added ViewModel tests and the key journey integration test | Verify state transitions and the end-to-end flow |
| 2026-11-22 | Constrained content to 720 px on wide windows | Readable desktop layout without a separate design |
| 2026-11-22 | Replaced the library refresh action with a light/dark theme switch | User request; Drift streams update live, so manual refresh is unnecessary |
| 2026-11-22 | Renamed the visible app to Quiz on Android, iOS and Windows | User request; the package and bundle IDs stay `quiz_app` |
| 2026-11-22 | Added three app icon concepts and a preview page | Preview only; the launcher icon stays the Flutter default until a concept is chosen |
| 2026-11-22 | Implemented per-attempt answer review | Show every question with both answers, status and explanation |
| 2026-11-22 | Installed Concept A as the launcher icon on Android, iOS and Windows | Chosen from the three previews; adaptive and monochrome layers included |

## Open issues / decisions

- The **native file picker** cannot be driven by the integration test. Import is covered by parser, use-case, repository and ViewModel tests; the picker itself compiles and builds on Windows.
- Folder rows currently show the name only. Child counts need a `watchFolderSummaries` query; this is a small follow-up if the counts are wanted on the list.
- The quiz detail eyebrow reads `QUIZ` because `QuizScreenModel` does not carry the folder name. The full breadcrumb is available on the folder screen.
- Widget coverage for individual screens is provided by the key journey integration test plus the shared-widget test. Additional per-screen widget tests can be added without changing production code.
- The light/dark mode switch is session-only; it resets to the system setting on app restart. Add persistence if needed.
- The launcher icon is Concept A on Android, iOS and Windows. The Android themed (monochrome) layer is generated but has not been checked on a physical Android 13+ launcher.
- The answer review is read-only. It recomputes status from the stored `answers_json`, so its counts can differ from the stored score only if the quiz definition changed after the attempt (quizzes cannot be edited in this build).
- The result screen shows “Saved to history” for historical attempts too; it is accurate but could be labelled “Attempt summary” when opened from history.
- The app uses the Flutter 3.50 `material_ui` package instead of the deprecated `flutter/material.dart`.
- `flutter_math_fork` renders the sample LaTeX and has a raw-text fallback if a formula fails.
- Attempts are saved only on End. Discarding or closing the app mid-attempt writes nothing.
- No HTTP client exists in the app. Repositories read and write Drift directly.

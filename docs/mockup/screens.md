# Mockup screens

**Status:** Awaiting approval
**Entry point:** `docs/mockup/index.html` (double-click; no server)
**Reference:** `docs/product_spec.md`, `docs/data_model.html`, `docs/dependencies.html`
**Theme:** light and dark, toggled from the developer toolbar
**Device:** 390 × 844 phone frame on desktop; full viewport below 560 px

The mockup is a self-contained page. It has **no HTTP layer and no fake server**. Screens call a local repository facade backed by an in-memory database persisted to `localStorage`. The repository methods mirror the future Drift repositories, so the mapping to Phase 1 code is direct.

> **Intentional deviation:** `Flutter/flutter_mockup_generator.md` describes a fake HTTP layer. This project is fully local, so the mockup calls the repository directly instead. Screens and states are unchanged.

---

## 1. Screen inventory

| # | Screen | Route | Purpose | States | Repository calls |
|---|---|---|---|---|---|
| 1 | All folders (root) | `#/` | Browse top-level folders, create a folder | loading, empty, error, loaded | `folderContents('root')` |
| 2 | Folder | `#/folders/:folderId` | Browse sub-folders and quizzes in a folder | loading, empty, error, loaded | `folderContents(id)`, `folderDeletePreview(id)` |
| 3 | Quiz detail | `#/quizzes/:quizId` | Read quiz metadata, start an attempt, view history | loading, empty history, error, loaded | `quiz(id)`, `deleteQuiz(id)` |
| 4 | Attempt — pre-start | `#/quizzes/:quizId/attempt` | Explain the rules; hold questions until Start | loading, idle, error | `quiz(id)` |
| 5 | Attempt — running | same route, in-page state | Answer questions with a live timer and End control | running, answered progress, end confirmation, discard confirmation, storage error | `saveAttempt(payload)` |
| 6 | Result (fresh attempt) | `#/quizzes/:quizId/result/:attemptId` | Show score, accuracy, time and date after End | loading, loaded, error | `attempt(id)` |
| 7 | Attempt summary | `#/attempts/:attemptId` | Read a past attempt from history | loading, loaded, error | `attempt(id)` |
| 8 | Import | `#/import?folder=:folderId` | Pick one or more JSON files, validate, preview, import | idle/empty, reading, partial valid, all invalid, importing, success, error | `folderContents(id)`, `importQuizzes(folderId, quizzes)` |
| 9 | Not found | any unknown route, e.g. `#/does-not-exist` | Friendly dead-end with a way back | loaded | — |

### Sheets, dialogs and transient UI

| # | Overlay | Opened from | States |
|---|---|---|---|
| 10 | Add menu | FAB on All folders or Folder | idle; offers New folder, and Import quizzes inside a folder |
| 11 | New folder | Add menu or empty state | idle, validation error, saving, duplicate name, storage error |
| 12 | Folder actions | Row more button or folder app bar | idle; Rename folder, Delete folder |
| 13 | Rename folder | Folder actions | idle, validation error, saving, duplicate name, storage error |
| 14 | Delete folder | Folder actions | loading preview, counts, deleting, storage error |
| 15 | Quiz actions | Quiz row more button or quiz app bar | idle; Delete quiz |
| 16 | Delete quiz | Quiz actions | counts, deleting, storage error |
| 17 | End attempt | End button (app bar or footer) | answered/unanswered summary, saving, storage error |
| 18 | Discard attempt | Close button, back gesture, browser back | confirmation |
| 19 | Toast | Any completed mutation | success or error, auto-dismiss |

---

## 2. Route map

```
#/                                  All folders (root)
#/folders/f-net                     Folder
#/quizzes/q-ipv4                    Quiz detail
#/quizzes/q-ipv4/attempt            Pre-start → running
#/quizzes/q-ipv4/result/:attemptId   Result after End
#/attempts/a-ipv4-10                Attempt summary from history
#/import?folder=f-net               Import into a folder
#/does-not-exist                    Not found
```

Navigation uses hash routes, so the browser back button and deep links work. Back while an attempt is running is intercepted: the URL is restored and the discard sheet is shown.

---

## 3. Repository contract

Screens never read the mock database directly. They call `repo.*`; each method returns a Promise, applies the simulated query delay, and may throw `DataError { code, message }`. The UI renders the message and offers a retry where appropriate.

| Method | Purpose | Returns |
|---|---|---|
| `folderContents(id)` | Folder metadata, breadcrumb, direct folders/quizzes, library stats | `{ folder, path, folders, quizzes, stats }` |
| `folderDeletePreview(id)` | Counts for the delete confirmation | `{ folder, folders, quizzes, attempts, questions }` |
| `createFolder(parentId, name)` | Create a folder | created folder summary |
| `renameFolder(id, name)` | Rename a folder | updated folder summary |
| `deleteFolder(id)` | Delete a folder and its subtree | `null` (cascades in the mock database) |
| `quiz(id)` | Quiz, folder, ordered questions/options, attempts | `{ quiz, folder, questions, attempts }` |
| `importQuizzes(folderId, quizzes)` | Insert canonical quizzes into a folder | `{ imported, skipped }` |
| `deleteQuiz(id)` | Delete a quiz and its history | `null` |
| `saveAttempt(payload)` | Save a completed attempt and compute its score | `{ attempt, quiz }` |
| `attempt(id)` | Attempt summary and its quiz | `{ attempt, quiz }` |

The simulated query delay is 350 ms by default (0/150/350/700 ms). The storage error rate can be set to 0/10/30/100%. Errors are thrown as `DataError`, never returned as HTTP responses.

---

## 4. Repository → Drift mapping

| Mock repository call | Future Flutter code |
|---|---|
| `folderContents(id)` | `FolderRepositoryInterface.watchFolderContents(id)` → `ListFolderContentsUsecase` |
| `folderDeletePreview(id)` | `FolderRepositoryInterface.getDeletePreview(id)` → `GetFolderDeletePreviewUsecase` |
| `createFolder(parentId, name)` | `CreateFolderUsecase` → `FolderRepositoryInterface.createFolder(...)` |
| `renameFolder(id, name)` | `RenameFolderUsecase` → `FolderRepositoryInterface.renameFolder(...)` |
| `deleteFolder(id)` | `DeleteFolderUsecase` → `FolderRepositoryInterface.deleteFolder(...)` |
| `quiz(id)` | `QuizRepositoryInterface.watchQuiz(id)` → `GetQuizDetailUsecase` |
| `importQuizzes(folderId, quizzes)` | `ImportQuizzesUsecase` → `QuizRepositoryInterface.importQuizzes(...)` |
| `deleteQuiz(id)` | `DeleteQuizUsecase` → `QuizRepositoryInterface.deleteQuiz(...)` |
| `saveAttempt(payload)` | `CompleteAttemptUsecase` → `AttemptRepositoryInterface.saveAttempt(...)` |
| `attempt(id)` | `AttemptRepositoryInterface.getAttempt(id)` → `GetAttemptUsecase` |

The client-side JSON parsing in the mock stands in for the future pure Dart mapper. After parsing, the payload is already the canonical quiz shape, so the repository boundary stays clean.

There is **no HTTP client, API client or fake server** in the real app. Repositories read and write Drift directly; the only external input is the JSON file picked by the user.

---

## 5. Seed data

| Item | Count / value |
|---|---|
| Root folders | 8 (Aptitude, Archive, Biology, Chemistry, Computer Networks, History, Mathematics, Physics) |
| Nested folders | 1 (Transport Layer inside Computer Networks) |
| Quizzes | 13 |
| Questions | 99 (including the real 35-question IPv4 quiz) |
| Attempts | 33 (10 on the IPv4 quiz, 1–4 on the others) |
| Empty folder | Archive (`f-empty`) |
| Long title | "Computer Networks, Lecture 1: Classful IPv4 Addressing" |
| Math content | Real inline LaTeX from `docs/quiz.json`, rendered with bundled KaTeX |

The IPv4 quiz is parsed from the embedded `docs/quiz.json` text at startup using the same parser as the import screen. That means the seeded 35-question quiz exercises the real schema, the backslash repair and the math rendering.

Stable IDs for the toolbar: `f-net`, `f-net-transport`, `f-empty`, `q-ipv4`, `a-ipv4-10`.

---

## 6. Import behaviour

- The file picker accepts one or more `.json` files. Drag and drop is supported on desktop.
- Each file is read with `File.text()` and parsed locally. Strict JSON is tried first; the importer repairs unescaped LaTeX backslashes (`\(`, `\)`, `\times`, `\text`) and warns that the source should be valid JSON.
- Validation runs before anything is written:
  - `title` required, ≤ 120 characters;
  - 1–1,000 questions;
  - `t` must be `MCQ`, `MSQ` or `NAT`;
  - `q` required;
  - MCQ: at least two non-empty, unique options and exactly one in-range index;
  - MSQ: at least two options and one or more unique in-range indices;
  - NAT: a finite numeric answer.
- The preview shows one row per file with title, type counts, marks, valid/invalid status, repair notice and per-question errors, plus batch totals.
- Invalid files are skipped; valid files can still be imported. Each file is validated independently; a failed file never blocks the valid ones.
- Limits: 5 MB / 1,000 questions per file; 50 files / 20 MB per batch.
- The quiz `key` is stored but never used to block or merge imports.
- After import, one quiz opens if exactly one was imported; otherwise the folder opens with a toast.

The **Sample import** and **Invalid import** buttons in the developer toolbar load a valid and an invalid file without needing a local file.

---

## 7. State coverage

| State | Where to see it |
|---|---|
| Loading | Set query delay to 700 ms and change screens; skeletons match the final layout |
| Empty | All folders (after deleting all top-level folders) or Archive (`f-empty`) |
| Empty attempts | Any quiz with no attempts, e.g. a freshly imported quiz |
| Storage error | Set storage error rate to 100% and change screens |
| Validation | New folder with a blank or duplicate name; Import an invalid file |
| Saving | Create/rename/delete/import with query delay at 700 ms |
| Success | Toast after create, rename, delete, import or saving an attempt |
| Not found | `#/does-not-exist` or the toolbar's Not found option |
| Dark theme | Toggle Dark theme in the developer toolbar |

The app has no online/offline mode; local Drift is the only data source, so there is no offline banner.

---

## 8. Developer toolbar

Outside the phone frame (below it on narrow windows):

- **Screen jump** — every key route.
- **Data** — Reset data, Sample import, Invalid import, Empty folder.
- **Query delay** — 0 / 150 / 350 / 700 ms.
- **Storage error rate** — 0 / 10 / 30 / 100%.
- **Dark theme** — toggle, persisted in `localStorage`.
- **Screenshot mode** — hides the toolbar and frame chrome; an exit pill remains.
- **Data log** — the last 50 repository calls as `OK/ERR method → ms`.

The toolbar is review-only and is never reachable from inside the app UI.

---

## 9. Deliberate omissions

- No quiz editing, moving or re-import into an existing quiz (MVP spec).
- No per-question review screen. Attempts store `answers_json`; the UI shows the summary only.
- Seeded attempts store `{}` in `answers_json`; newly completed attempts store real answers.
- An in-progress attempt is not persisted if the page is reloaded or closed.
- The import is client-side in the mock because it runs in a browser. The real app uses `file_picker` and a pure Dart mapper.
- The mock has no network, accounts, analytics or sync. Data lives in `localStorage`; the real app uses Drift.

---

## 10. How to review

1. Double-click `docs/mockup/index.html`.
2. Browse a folder, open the IPv4 quiz, start an attempt, answer a few questions, press End.
3. Check the result and the new row in the quiz's attempt history.
4. Click the FAB inside Computer Networks and import the sample quiz.
5. Use the developer toolbar to walk the loading, empty, storage-error and dark states.
6. Try a duplicate folder name and an invalid import file to see validation.

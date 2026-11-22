# Mockup screens

**Status:** Awaiting approval
**Entry point:** `docs/mockup/index.html` (double-click; no server)
**Reference:** `docs/product_spec.md`, `docs/data_model.html`, `docs/dependencies.html`
**Theme:** light and dark, toggled from the developer toolbar
**Device:** 390 × 844 phone frame on desktop; full viewport below 560 px

The mockup is a single self-contained page. All data goes through a fake HTTP layer backed by an in-memory database persisted to `localStorage`.

---

## 1. Screen inventory

| # | Screen | Route | Purpose | States | Endpoints |
|---|---|---|---|---|---|
| 1 | All folders (root) | `#/` | Browse top-level folders, create a folder | loading, empty, error, offline, loaded | `GET /api/folders/root/contents` |
| 2 | Folder | `#/folders/:folderId` | Browse sub-folders and quizzes in a folder | loading, empty, error, offline, loaded | `GET /api/folders/:id/contents`, `GET /api/folders/:id/delete-preview` |
| 3 | Quiz detail | `#/quizzes/:quizId` | Read quiz metadata, start an attempt, view history | loading, empty history, error, offline, loaded | `GET /api/quizzes/:id`, `DELETE /api/quizzes/:id` |
| 4 | Attempt — pre-start | `#/quizzes/:quizId/attempt` | Explain the rules; hold questions until Start | loading, idle, error, offline | `GET /api/quizzes/:id` |
| 5 | Attempt — running | same route, in-page state | Answer questions with a live timer and End control | running, answered progress, end confirmation, discard confirmation, offline write block | `POST /api/attempts` |
| 6 | Result (fresh attempt) | `#/quizzes/:quizId/result/:attemptId` | Show score, accuracy, time and date after End | loading, loaded, error, offline | `GET /api/attempts/:id` |
| 7 | Attempt summary | `#/attempts/:attemptId` | Read a past attempt from history | loading, loaded, error, offline | `GET /api/attempts/:id` |
| 8 | Import | `#/import?folder=:folderId` | Pick one or more JSON files, validate, preview, import | idle/empty, reading, partial valid, all invalid, importing, success, error, offline | `GET /api/folders/:id/contents`, `POST /api/quizzes/import` |
| 9 | Not found | any unknown route, e.g. `#/does-not-exist` | Friendly dead-end with a way back | loaded | — |

### Sheets, dialogs and transient UI

| # | Overlay | Opened from | States |
|---|---|---|---|
| 10 | Add menu | FAB on Library or Folder | idle; offers New folder, and Import quizzes inside a folder |
| 11 | New folder | Add menu or empty state | idle, validation error, saving, server conflict (duplicate name), error |
| 12 | Folder actions | Row more button or folder app bar | idle; Rename folder, Delete folder |
| 13 | Rename folder | Folder actions | idle, validation error, saving, server conflict, error |
| 14 | Delete folder | Folder actions | loading preview, counts, deleting, error |
| 15 | Quiz actions | Quiz row more button or quiz app bar | idle; Delete quiz |
| 16 | Delete quiz | Quiz actions | counts, deleting, error |
| 17 | End attempt | End button (app bar or footer) | answered/unanswered summary, saving, error |
| 18 | Discard attempt | Close button, back gesture, browser back | confirmation |
| 19 | Toast | Any completed mutation | success or error, auto-dismiss |
| 20 | Offline banner | Any data screen while offline | persistent, Retry |

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

## 3. Endpoint contract

All requests go through the overridden `window.fetch`; nothing reaches the network. Success responses are `{ data: ... }`; failures are `{ error: { code, message } }` with real status codes.

| Method | Path | Purpose | Success | Notes |
|---|---|---|---|---|
| `GET` | `/api/folders/:id/contents` | Folder metadata, breadcrumb, direct folders and quizzes, library stats | `200` | `id` is `root` for the library |
| `GET` | `/api/folders/:id/delete-preview` | Counts for the delete confirmation | `200` | Recursive sub-folders, quizzes and attempts |
| `POST` | `/api/folders` | Create a folder | `201` | 422 for empty/long names; 409 for duplicate siblings |
| `PATCH` | `/api/folders/:id` | Rename a folder | `200` | Same validation as create |
| `DELETE` | `/api/folders/:id` | Delete a folder and its subtree | `204` | Cascades to quizzes, questions, options and attempts |
| `GET` | `/api/quizzes/:id` | Quiz, folder, ordered questions/options, attempts | `200` | 404 if the quiz is gone |
| `POST` | `/api/quizzes/import` | Insert canonical quizzes into a folder | `201` | Accepts parsed quizzes; the client validates files |
| `DELETE` | `/api/quizzes/:id` | Delete a quiz and its history | `204` | Cascades |
| `POST` | `/api/attempts` | Save a completed attempt | `201` | Computes score and max score from answers |
| `GET` | `/api/attempts/:id` | Attempt summary and its quiz | `200` | 404 if the attempt is gone |

Latency is 350 ms by default and can be set to 0, 150, 350 or 700 ms. Error rate can be set to 0%, 10%, 30% or 100%. Offline mode returns `503` for every call; the UI shows a persistent banner and blocks writes.

---

## 4. Endpoint → Flutter mapping

| Mock endpoint | Future Flutter code |
|---|---|
| `GET /api/folders/:id/contents` | `FolderRepositoryInterface.watchFolderContents(id)` → `ListFolderContentsUsecase` |
| `GET /api/folders/:id/delete-preview` | `FolderRepositoryInterface.getDeletePreview(id)` → `GetFolderDeletePreviewUsecase` |
| `POST /api/folders` | `CreateFolderUsecase` |
| `PATCH /api/folders/:id` | `RenameFolderUsecase` |
| `DELETE /api/folders/:id` | `DeleteFolderUsecase` |
| `GET /api/quizzes/:id` | `QuizRepositoryInterface.watchQuiz(id)` → `GetQuizDetailUsecase` |
| `POST /api/quizzes/import` | `ImportQuizzesUsecase` after the pure JSON mapper validates the file |
| `DELETE /api/quizzes/:id` | `DeleteQuizUsecase` |
| `POST /api/attempts` | `CompleteAttemptUsecase` (the real use case computes the score, then the repository writes it) |
| `GET /api/attempts/:id` | `AttemptRepositoryInterface.getAttempt(id)` → `GetAttemptUsecase` |

The client-side JSON parsing in the mock is a stand-in for the future pure Dart mapper. The HTTP payload after parsing is already the canonical quiz shape, so the repository boundary stays clean.

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
- Invalid files are skipped; valid files can still be imported. Each file is atomic on the server.
- Limits: 5 MB / 1,000 questions per file; 50 files / 20 MB per batch.
- The quiz `key` is stored but never used to block or merge imports.
- After import, one quiz opens if exactly one was imported; otherwise the folder opens with a toast.

The **Sample import** and **Invalid import** buttons in the developer toolbar load a valid and an invalid file without needing a local file.

---

## 7. State coverage

| State | Where to see it |
|---|---|
| Loading | Set latency to 700 ms and change screens; skeletons match the final layout |
| Empty | All folders (after deleting all top-level folders) or Archive (`f-empty`) |
| Empty attempts | Any quiz with no attempts, e.g. a freshly imported quiz |
| Error | Set error rate to 100% and change screens |
| Offline | Toggle Offline, then change screens or try a mutation |
| Validation | New folder with a blank or duplicate name; Import an invalid file |
| Saving | Create/rename/delete/import with latency at 700 ms |
| Success | Toast after create, rename, delete, import or saving an attempt |
| Not found | `#/does-not-exist` or the toolbar's Not found option |
| Dark theme | Toggle Dark theme in the developer toolbar |

---

## 8. Developer toolbar

Outside the phone frame (below it on narrow windows):

- **Screen jump** — every key route.
- **Data** — Reset data, Sample import, Invalid import, Empty folder.
- **Latency** — 0 / 150 / 350 / 700 ms.
- **Error rate** — 0 / 10 / 30 / 100%.
- **Offline** — toggle.
- **Dark theme** — toggle, persisted in `localStorage`.
- **Screenshot mode** — hides the toolbar and frame chrome; an exit pill remains.
- **Network log** — the last 50 requests as `METHOD path → status (ms)`.

The toolbar is review-only and is never reachable from inside the app UI.

---

## 9. Deliberate omissions

- No quiz editing, moving or re-import into an existing quiz (MVP spec).
- No per-question review screen. Attempts store `answers_json`; the UI shows the summary only.
- Seeded attempts store `{}` in `answers_json`; newly completed attempts store real answers.
- An in-progress attempt is not persisted if the page is reloaded or closed.
- The import is client-side in the mock because `file://` blocks fetching local JSON. The real app uses `file_picker` and a pure Dart mapper.
- The mock has no real network, accounts, analytics or sync.

---

## 10. How to review

1. Double-click `docs/mockup/index.html`.
2. Browse a folder, open the IPv4 quiz, start an attempt, answer a few questions, press End.
3. Check the result and the new row in the quiz's attempt history.
4. Click the FAB inside Computer Networks and import the sample quiz.
5. Use the developer toolbar to walk the loading, empty, error, offline and dark states.
6. Try a duplicate folder name and an invalid import file to see validation.

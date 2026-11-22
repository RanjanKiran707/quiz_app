# Quiz App — Product Specification

**Status:** Approved v4 — implemented
**Date:** 2026-11-22
**Source:** User PRD plus decisions agreed on 2026-11-22
**App / package name:** `quiz_app`
**Repository:** `github.com/RanjanKiran707/quiz_app` (public, to be created)
**Platform:** Flutter, mobile-first responsive (Android / iOS; Windows desktop used for development and testing)

---

## 1. Overview

Quiz App is a lightweight, local-first application for organising quizzes inside nested folders, importing quiz content from JSON, attempting quizzes, and reviewing a per-quiz history of attempts with question-by-question answers.

The product is deliberately small: folder navigation, JSON import, quiz taking, attempt history and answer review. No accounts, no network, no social features. The interface stays minimal and distraction-free.

### Core value

1. Keep many quizzes tidy in a folder tree.
2. Bring content in quickly through one or more JSON files.
3. Practise the three question formats that matter: MCQ, MSQ, Numerical.
4. See exactly how each attempt went: score, time taken, date.
5. Review every answer from an attempt: your answer, the correct answer and the explanation.

---

## 2. Goals and non-goals

### Goals (MVP)

- Arbitrarily nested folders that can hold sub-folders and quizzes.
- Create, rename and delete folders; delete quizzes.
- Import one or more quizzes from `.json` files into the current folder.
- Attempt a quiz unlimited times.
- Support only MCQ, MSQ and Numerical questions.
- Explicit **Start** and **End** controls with elapsed-time tracking.
- Persist every completed attempt and show score, time taken and date.
- Review every attempt question by question: your answer, the correct answer, status and explanation.
- Clean, minimal, responsive UI in light and dark mode.
- All data stored locally and available offline.

### Non-goals (MVP)

- Playlist and YouTube import (future scope).
- In-app quiz authoring/editing, re-import into an existing quiz, moving quizzes or folders.
- Accounts, authentication, cloud sync, sharing, collaboration.
- Leaderboards, streaks, notifications, gamification.
- Per-question timers, negative marking, question shuffling, question pools.
- Analytics beyond the per-quiz attempt history.

---

## 3. Users and core jobs

Single local user, typically a student or self-learner.

| Job | Trigger | Desired outcome |
|---|---|---|
| Organise content | Quiz collection grows | Folders make the right quiz easy to find |
| Add a quiz | One or more quiz JSON files exist | Imported into the chosen folder in one flow |
| Practise | Ready to test knowledge | Start, answer, end, see score |
| Check progress | Wants proof of practice | Attempt history shows score, time and date |
| Learn from mistakes | Wants to see what went wrong | Review every question, both answers and the explanation |

No onboarding, login or profile is required.

---

## 4. Scope summary

| Area | MVP | Future |
|---|---|---|
| Folders | Nested tree, create / rename / delete | Move, reorder, drag and drop |
| Quizzes | JSON import (single or batch), delete, unlimited attempts | Edit, duplicate, share, playlist/YouTube import |
| Question types | MCQ, MSQ, Numerical | True/False, fill-in-the-blank, matching |
| Attempts | Start/End timing, score, history, per-question answer review | Resume, pause |
| Data | Local SQLite (Drift), fully offline | Cloud backup / sync |
| Design | Minimal Material 3, light + dark, mobile-first | App icon, theming options |

---

## 5. Information architecture

```
Root ("All folders")            ← fixed, cannot be renamed or deleted
└── Folder A
    ├── Sub-folder A1
    │   └── Quiz 1
    └── Quiz 2
```

Rules:

- A folder may contain any number of sub-folders and quizzes.
- A quiz always belongs to exactly one folder. Quizzes are not created at the root.
- Nesting depth is effectively unlimited; the UI must remain usable at shallow-to-moderate depth (breadcrumb + back navigation).
- Deleting a folder deletes its entire subtree, including quizzes and their attempt history, after explicit confirmation.

---

## 6. Functional requirements

### FR-1 Folder management

| ID | Requirement |
|---|---|
| FR-1.1 | The root screen lists the top-level folders and is titled **All folders**. |
| FR-1.2 | Tapping a folder opens it and lists its sub-folders followed by its quizzes. |
| FR-1.3 | A **New folder** action creates a folder inside the folder currently open. |
| FR-1.4 | A folder can be renamed from its list row or from inside the folder. |
| FR-1.5 | A folder can be deleted. If it contains content, the confirmation names the number of sub-folders, quizzes and stored attempts that will be removed. |
| FR-1.6 | Folder names are trimmed, 1–60 characters, and unique (case-insensitive) among siblings. Invalid or duplicate names show inline validation and are not saved. |
| FR-1.7 | The root cannot be renamed or deleted. |
| FR-1.8 | A breadcrumb shows the current path and allows jumping to any ancestor. The system back action goes up one folder, except while an attempt is running (see FR-4). |
| FR-1.9 | Empty folders and the empty root show a short empty state with the primary action to create a folder. |

### FR-2 Quiz import

| ID | Requirement |
|---|---|
| FR-2.1 | **Import quiz** is available inside a folder (not at the root). |
| FR-2.2 | The user picks one or more `.json` files in a single file-picker dialog. |
| FR-2.3 | Each file is parsed and fully validated before anything is written. Each file imports atomically: either that whole quiz is saved or nothing from that file is saved. |
| FR-2.4 | The preview lists every selected file with its title, question count by type, total marks and validation status, plus batch totals (files, questions, marks). |
| FR-2.5 | Validation failures are listed per file with a question number and a plain-language reason (see §10). Invalid files are skipped; valid files in the same batch can still be imported. |
| FR-2.6 | A successful batch creates one new quiz per valid file in the current folder. If exactly one quiz was imported it opens; otherwise the folder is shown with the new quizzes and an `N imported, M skipped` summary. |
| FR-2.7 | Importing the same file twice creates two independent quizzes; existing quizzes are never modified or replaced. |
| FR-2.8 | Limits: each file ≤ 5 MB and ≤ 1,000 questions; each batch ≤ 50 files and ≤ 20 MB total. Oversized files or batches are rejected with a clear message. |
| FR-2.9 | The import format is the compact quiz format documented in §10: `title`, optional `subtitle` and `key`, and a `questions` array whose items use `t` (`MCQ` / `MSQ` / `NAT`), `q`, `o`, `a`, `e`, and optional `d` / `u`. |
| FR-2.10 | Files produced by the user's current generator contain unescaped LaTeX backslashes and are therefore not strict JSON. The importer repairs backslash sequences inside strings before parsing (§10.3) and tells the user that regenerating valid JSON is recommended. |
| FR-2.11 | Batch import is all-or-nothing per file, not per batch: a failed file never rolls back files that already imported successfully. |

### FR-3 Question types

Only three types are supported. Each question carries a prompt, a positive mark value (default 1) and a position. Marks are summed to the quiz total.

| Type | Answer input | Correctness rule |
|---|---|---|
| **MCQ** — single correct option | Pick exactly one option | Selected option is the correct option |
| **MSQ** — one or more correct options | Pick any number of options | Selected set exactly equals the correct set (all-or-nothing) |
| **Numerical** | Numeric text field (decimals and negatives allowed) | `abs(given − correct) ≤ tolerance`; tolerance defaults to 0 and must be ≥ 0 |

- MCQ requires at least two options and exactly one correct option.
- MSQ requires at least two options and at least one correct option.
- Numerical requires a finite numeric answer.
- Unanswered questions score zero.
- No negative marking.

### FR-4 Attempt flow and timing

| ID | Requirement |
|---|---|
| FR-4.1 | A quiz can be attempted unlimited times from its detail screen. |
| FR-4.2 | Starting opens an attempt screen in a **pre-start** state: quiz title, question count, total marks, scoring rules and a **Start** button. Questions are hidden until Start. |
| FR-4.3 | **Start** records the start timestamp, reveals the questions and starts the live timer. The timer counts real elapsed time from the start timestamp, so backgrounding the app does not lose time. |
| FR-4.4 | The running screen shows the live elapsed time and a persistent **End** action. |
| FR-4.5 | **End** asks for confirmation, including how many questions are unanswered, then scores the attempt, saves it and shows the result. |
| FR-4.6 | The saved duration is `endedAt − startedAt`, not a tick count. |
| FR-4.7 | Back navigation while running asks **Discard this attempt?**; confirming discards it and nothing is added to history. The system back gesture and the AppBar back arrow behave the same. |
| FR-4.8 | Back navigation before Start (or after the result) is not blocked. |
| FR-4.9 | An attempt is saved only on **End**. Force-quitting the app during an attempt loses that attempt (MVP limitation, documented). |
| FR-4.10 | The result screen shows score, percentage, marks earned out of total, and time taken. It offers **Review answers**, **Try again** and **Back to quiz**. |

### FR-5 Scoring

- `score = Σ marks of correctly answered questions`.
- `maxScore = Σ marks of all questions`.
- Percentage is rounded for display only; stored values are exact.
- MSQ is all-or-nothing; partial selections earn zero.
- Numerical comparison uses the question's tolerance; with tolerance 0, values are compared numerically (no string comparison) with a small floating-point epsilon where needed.
- Answers are persisted with the attempt and shown in the attempt review (question by question).

### FR-6 Attempt history

| ID | Requirement |
|---|---|
| FR-6.1 | The quiz detail screen lists every completed attempt, newest first. |
| FR-6.2 | Each row shows **score** (e.g. `7/10` or `70%`), **time taken** (e.g. `04:32`), and **date/time** of the attempt. |
| FR-6.3 | Tapping a row opens that attempt's result summary. |
| FR-6.4 | Empty, loading and error states are handled explicitly. |
| FR-6.5 | History is stored locally and survives app restarts. |
| FR-6.6 | **Review answers** opens a read-only screen listing every question in quiz order. Each item shows the prompt, the user's answer, the correct answer, a Correct / Incorrect / Unanswered status and the explanation when present. |
| FR-6.7 | The review uses the answers stored with that attempt; it never changes the score, answers or history. |
| FR-6.8 | Numerical review shows the entered value, the expected value, the unit and the tolerance where applicable. MSQ review shows the full selected set and the full correct set. |

### FR-7 Deletion and integrity

- Deleting a quiz removes its questions, options, attempts and answers after confirmation.
- Deleting a folder cascades to descendants and their content.
- Each file import and each attempt save run inside a database transaction.
- Foreign keys are enforced and cascades are tested.

---

## 7. Attempt lifecycle

```
Quiz detail
   │ Start attempt
   ▼
Pre-start (timer off, questions hidden)
   │ Start                         │ Back
   ▼                               ▼
Running (timer on)              Quiz detail
   │ End              │ Back
   ▼                  ▼
Confirm end       Confirm discard
   │ Yes              │ Yes
   ▼                  ▼
Result screen      Quiz detail (nothing saved)
   │
   ├── Saved attempt appears in history
```

---

## 8. Conceptual data model

A detailed interactive ER diagram will be produced in `docs/data_model.html` before implementation; this section fixes the meaning.

| Entity | Fields (conceptual) | Relationships |
|---|---|---|
| Folder | id, name, parentFolderId (nullable), createdAt | parent → Folder; one-to-many children |
| Quiz | id, folderId, title, subtitle (optional), sourceKey (optional), createdAt | → Folder; one-to-many questions, attempts |
| Question | id, quizId, prompt, type (`mcq` / `msq` / `numerical`), marks, position, difficulty (optional), explanation (optional), unit (optional), numericalAnswer (nullable), tolerance (nullable) | → Quiz; one-to-many options |
| QuestionOption | id, questionId, text, isCorrect, position | → Question |
| Attempt | id, quizId, startedAt, endedAt, durationMs, score, maxScore, answersJson | → Quiz |

Notes:

- IDs are stable strings (UUIDs).
- Import snapshots the quiz definition into these tables; the original JSON is not re-read later.
- Timestamps are stored in UTC and displayed in local time.
- `answersJson` holds the user's selections/number per question and is displayed in the attempt review.
- The import format has no marks field, so every question is worth 1 mark and the quiz total equals the question count.
- `sourceKey` is stored for traceability but is not used for duplicate detection: re-importing the same `key` always creates a new quiz.
- `difficulty`, `explanation` and `unit` are stored even though the MVP UI does not show explanations; this avoids losing source data on import.
- There is no HTTP client, API layer or remote server. Repositories read and write Drift directly; the only external input is the JSON file the user picks.

---

## 9. Screens and states

| # | Screen | Purpose | Required states |
|---|---|---|---|
| 1 | Folder screen (root / nested) | Browse folders and quizzes, open content | loading, empty, loaded, error |
| 2 | Create folder dialog | Name and create a folder | idle, validation error, saving |
| 3 | Rename folder dialog | Rename an existing folder | idle, validation error, saving |
| 4 | Delete folder dialog | Confirm cascade deletion with counts | idle, deleting |
| 5 | Import quiz screen | Pick one or more files, validate, preview and import | idle, picking, validating, partial-invalid preview, valid preview, importing, batch result, error |
| 6 | Quiz detail | Metadata, Start, attempt history, delete | loading, empty history, loaded, error |
| 7 | Attempt — pre-start | Rules and Start control | idle |
| 8 | Attempt — running | Questions, answers, live timer, End | running, validation hint, end confirmation |
| 9 | Attempt result | Score, percentage, time, navigation | loaded |
| 10 | Delete quiz dialog | Confirm quiz and history deletion | idle, deleting |
| 11 | Attempt summary (from history) | Read-only result of a past attempt | loaded |
| 12 | Attempt review | Every question with your answer, correct answer, status and explanation | loading, loaded, error |

Shared UX rules:

- Every destructive action requires confirmation.
- Loading blocks duplicate submissions and disables the relevant controls.
- Errors are plain language and say what to do next; technical details are not shown.
- All list screens handle pull-to-refresh where data may have changed (desktop: refresh action).

---

## 10. Import format and validation

### 10.1 Source format

The importer accepts the compact format used by the user's quiz generator. Keys are short to keep files small.

| Level | Field | Type | Required | Meaning |
|---|---|---|---|---|
| Quiz | `title` | string | yes | Quiz title, ≤ 120 chars |
| Quiz | `subtitle` | string | no | One-line description, ≤ 240 chars |
| Quiz | `key` | string | no | Stable source identifier, stored as `sourceKey` |
| Quiz | `questions` | array | yes | 1–1,000 questions |
| Question | `t` | `MCQ` / `MSQ` / `NAT` | yes | Question type; matched case-insensitively |
| Question | `d` | `Easy` / `Medium` / `Hard` | no | Difficulty |
| Question | `q` | string | yes | Prompt |
| Question | `o` | string[] | MCQ/MSQ | At least 2 options |
| Question | `a` | int / int[] / number | yes | MCQ: 0-based option index; MSQ: 0-based indices; NAT: numeric answer |
| Question | `e` | string | no | Explanation, stored for later |
| Question | `u` | string | no | Unit suffix for a numerical answer |

Rules:

- `NAT` maps to the app's **Numerical** type; `NAT` questions must not carry `o`.
- MCQ `a` is exactly one index; MSQ `a` is one or more unique indices, in any order.
- Option indices are 0-based and must be within `o`.
- There are no marks in the source, so every question is worth **1 mark** and the quiz maximum equals the number of questions.
- There is no tolerance field; numerical answers are compared exactly (with a floating-point epsilon) unless a future format adds tolerance.
- `d`, `e` and `u` are optional and stored; the MVP does not display explanations or difficulty.
- `key` is never used to block or merge imports (per decision); re-importing always creates a new quiz.
- Files may contain inline LaTeX (`\(...\)`, `^`, `\times`, `\text`); it is rendered, not stripped.
- Extra unknown fields are ignored, so future producer additions do not break import.

**Reference file:** `docs/quiz.json` — 35 questions (15 MCQ, 10 MSQ, 10 NAT), 3–4 options each, 24 Medium and 11 Hard, 3 with units, all with explanations. Maximum score 35.

### 10.2 Validation

| Rule | Error message shape |
|---|---|
| File readable, UTF-8, ≤ 5 MB | "This file could not be read." |
| Parses as JSON after the backslash repair in §10.3 | "This file contains malformed JSON." |
| `title` present and non-empty | "The quiz needs a title." |
| `questions` present with 1–1,000 items | "This quiz has no questions." / "This quiz exceeds 1,000 questions." |
| `t` is MCQ, MSQ or NAT | "Question 4 has an unsupported type." |
| `q` present and non-empty | "Question 4 has no question text." |
| MCQ: `o` has ≥ 2 non-empty strings; `a` is one in-range index | "Question 4 must have exactly one correct option." |
| MSQ: `o` has ≥ 2 non-empty strings; `a` is a non-empty list of unique in-range indices | "Question 4 must have at least one correct option." |
| NAT: `a` is a finite number | "Question 4 needs a numeric answer." |
| No empty or duplicate option text | "Question 4 has an empty or repeated option." |

All errors are collected and shown per file. Nothing is written for a file unless that whole file is valid; other valid files in the batch are unaffected.

### 10.3 Non-standard backslashes

The current generator writes LaTeX without escaping it for JSON:

```json
"e": "Class C fixes 3 leading bits, so it holds \(2^{29}\) addresses ... \(64 \times 256 = 2^{14}\) ..."
```

Strict parsers reject `\(` and silently turn `\times` / `\text` into a tab plus text. The importer therefore:

1. Reads the raw file and tries a strict parse first.
2. If that fails, or the raw text contains `\(`, treats backslashes inside JSON strings as literal LaTeX: every `\` is doubled before parsing, except `\"` and `\\`, which are kept as JSON escapes.
3. Shows a one-time notice: the quiz was imported, but the file should be regenerated with escaped backslashes (`\\(`, `\\times`, `\\text`) to be valid JSON.

This repair is scoped to import and is tested against `docs/quiz.json` (124 unescaped delimiters). The canonical long-term format is strict JSON. Note: in this compatibility mode an intended `\n` inside a string becomes a literal `\n`; quiz files from this generator do not use embedded newlines.

### 10.4 Import preview

Before saving, show one row per selected file: title, subtitle, question counts by type, maximum marks, validation status and any backslash-repair notice. Show batch totals (files, questions, marks). The user can deselect files, cancel, or import all valid files; invalid files are clearly marked and skipped. After the import, show a per-file result summary (`imported`, `skipped with reason`).

---

## 11. Design guidelines

### Visual

- Minimal Material 3, neutral surfaces, one restrained accent colour.
- No gradients, decorative illustrations or dense chrome; content and whitespace carry the layout.
- Typography-led hierarchy; large quiz titles, quiet metadata.
- Lists use simple rows with generous touch targets; folders and quizzes are visually distinct.
- Light and dark themes follow the system setting.
- Mobile-first: single column, thumb-reachable primary actions. On wider screens the content is centred with a readable max width; no separate desktop layout in MVP.

### Math

- Inline LaTeX in prompts and options is rendered with `flutter_math_fork`; surrounding prose remains normal text.
- Supported delimiters: `\(...\)` inline and `\[...\]` display (display math is unusual in quiz prompts).
- Math inherits text colour, size and text scaling, and wraps with the paragraph.
- If a formula fails to parse, show the raw TeX inline rather than an error box or blank space.

### Interaction

- Start and End are the only prominent actions during an attempt; End is always reachable.
- The timer is visible but visually quiet.
- Answer selection gives immediate visual feedback; no auto-advance.
- End confirmation summarises unanswered questions.
- Every screen shows loading, empty and error states rather than blank space.
- Prevent accidental back navigation while attempting.
- Animations are short and functional; respect reduced-motion settings.

### Accessibility

- Minimum 48×48 dp tap targets.
- WCAG AA contrast in both themes.
- Text scales without clipping; quiz questions wrap.
- Timer and timer state are announced via semantics, and status is not conveyed by colour alone.

---

## 12. Non-functional requirements

| Area | Requirement |
|---|---|
| Offline | 100% functional with no network connection; no HTTP client or network calls at runtime |
| Storage | Local SQLite via Drift; repositories access Drift directly; schema migrations versioned |
| Startup | Folder tree usable within ~2 s on a mid-range device |
| Import | A 50-file / 20 MB batch is validated and saved within ~15 s; a 1,000-question single file within ~3 s, including backslash repair |
| Math | Inline formulas render with the surrounding text and fall back to raw TeX on parse failure |
| Scrolling | Lists remain smooth with hundreds of rows (lazy lists) |
| Reliability | No partial imports per file (a failed file never rolls back successful files); saved attempts survive restarts; back navigation cannot corrupt an attempt |
| Privacy | No accounts, analytics or telemetry; all data stays on the device |
| Time accuracy | Duration derived from timestamps, unaffected by UI ticks or backgrounding |
| Localisation | English only in MVP; date/time formatted with `intl` |
| Error handling | Failures surface as friendly messages; no unhandled exceptions in normal flows |

---

## 13. Acceptance criteria

1. A new user can create a folder, open it, and import one or more valid quiz JSON files in under a minute.
2. A folder can contain folders and quizzes to at least five levels, and every level is reachable via breadcrumb and back.
3. Folder names that are blank, too long, or duplicate siblings are rejected inline.
4. Deleting a non-empty folder shows counts and removes the whole subtree only after confirmation.
5. An invalid JSON file in a batch is rejected with per-question reasons; nothing from that file is created, and valid files in the same batch can still import.
6. A valid MCQ, MSQ and Numerical quiz imports with the correct prompt, options, marks and answers.
7. The attempt screen hides questions until Start.
8. The timer starts exactly on Start, keeps elapsed time while the app is backgrounded, and stops on End.
9. Ending an attempt saves exactly one history row with the correct score, duration and timestamp.
10. MSQ scores full marks only for the exact correct set.
11. A numerical answer exactly equal to the stored answer is correct; any other value is incorrect (the current format has no tolerance).
12. Backing out of a running attempt after confirmation leaves no history row.
13. Attempt history is newest-first and shows score, time taken and date; it persists across restarts.
14. **Review answers** on any attempt shows every question with the user's answer, the correct answer, a correct/incorrect/unanswered status, and the explanation when present.
15. Deleting a quiz removes its questions, options and attempts, and other quizzes are untouched.
16. All screens render usable loading, empty and error states.
17. The app works fully offline.
18. `flutter analyze` is clean and the full test suite passes at the end of each delivery phase.
19. `docs/quiz.json` imports as a 35-question quiz worth 35 marks: 15 MCQ, 10 MSQ and 10 NAT.
20. A file containing unescaped `\(...\)` LaTeX, including `\times` and `\text`, imports with the math intact after repair and shows the regeneration notice.
21. Inline math in prompts and options renders without raw backslashes or error boxes.
22. Selecting multiple JSON files imports one quiz per valid file in a single flow and shows a per-file result summary.
23. A batch containing an unreadable or invalid file skips that file with a reason and still imports the remaining valid files.

---

## 14. Decisions recorded

| Date | Decision | Source |
|---|---|---|
| 2026-11-22 | App/package name: `quiz_app` | User |
| 2026-11-22 | Storage: Drift + SQLite | User |
| 2026-11-22 | Folder management: create, rename, delete (no move/reorder) | User |
| 2026-11-22 | MSQ scoring: all-or-nothing | User |
| 2026-11-22 | Mobile-first responsive UI | User |
| 2026-11-22 | Import format: the compact `t`/`q`/`o`/`a`/`e` format sampled in `docs/quiz.json` | User |
| 2026-11-22 | Multiple JSON files can be imported in one batch (multi-select, per-file atomicity) | User |
| 2026-11-22 | Math rendered with a Flutter TeX renderer (`flutter_math_fork`), not plain text | User |
| 2026-11-22 | `key` stored but ignored for duplicate detection; re-imports always create a new quiz | User |
| 2026-11-22 | GitHub repository `RanjanKiran707/quiz_app`, public | User |
| 2026-11-22 | Timing derived from timestamps; attempt saved only on End | Spec assumption |
| 2026-11-22 | No HTTP/API layer; every read and write goes through Drift repositories directly (the mockup calls a local repository facade) | User |
| 2026-11-22 | Quizzes only inside folders; root holds folders only | Derived from PRD |
| 2026-11-22 | Answers stored per attempt for future review | Spec assumption |
| 2026-11-22 | Per-attempt answer review is part of the MVP: every question, both answers, status and explanation | User |

---

## 15. Open questions

| # | Question | Impact |
|---|---|---|
| 1 | Should quizzes ever be allowed at the root? Current spec says no | Navigation and import entry points |
| 2 | Initial app icon and accent colour, or use defaults for now? | Assets and theme |
| 3 | Should the importer keep the backslash repair permanently, or only until the quiz generator emits valid JSON? | Import maintenance and test fixtures |

---

## 16. Delivery plan

The Flutter workflow documents in `Flutter/` govern delivery.

### Phase 0 — Setup
1. Git initialisation and push to `github.com/RanjanKiran707/quiz_app` (public).
2. `docs/dependencies.html` — Drift, `drift_flutter`, `file_picker`, `intl`, `uuid`, `flutter_math_fork`; dev: `drift_dev`, `build_runner`, `integration_test`.
3. `docs/data_model.html` — interactive ER diagram.
4. `docs/mockup/index.html` + `screens.md` — complete clickable prototype, mock data, local repository (no HTTP), `localStorage`; bundle KaTeX under `docs/mockup/assets/` for offline math rendering; approval required.
5. `flutter create . --project-name quiz_app`, add packages, `flutter analyze`.

### Phase 1 — Data
Models, Drift schema, repositories, in-memory tests, `docs/progress/data_layer_progress.md`.

### Phase 2 — Use cases
Business use cases (folder CRUD, import validation, quiz delete, complete attempt/scoring) and UI use cases (folder contents, quiz detail, attempt history, attempt review), tests and progress file.

### Phase 3 — Features
Agreed order: folder browser → folder actions → JSON import → quiz detail/history → attempt runner → result → attempt review. ViewModel and widget tests per feature, integration test for the main journey, progress file.

---

## 17. Glossary

| Term | Meaning |
|---|---|
| Folder | Organisational container that can hold sub-folders and quizzes |
| Quiz | Imported set of questions with a title and attempt history |
| MCQ | Multiple Choice Question — exactly one correct option |
| MSQ | Multiple Select Question — one or more correct options, all-or-nothing scoring |
| NAT | The import format's numerical question (`t: "NAT"`), stored as Numerical |
| Numerical | Question answered by typing a number, optionally within a tolerance |
| TeX / LaTeX | Math markup used inside prompts and options, e.g. `\(2^{29}\)` |
| Attempt | One timed run through a quiz, saved on End |
| Pre-start | Attempt state after opening the quiz but before pressing Start |
| Score | Sum of marks earned; displayed with the maximum possible marks |

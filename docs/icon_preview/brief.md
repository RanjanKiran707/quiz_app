# Icon brief

- **App name:** Quiz (display name; internal package remains `quiz_app`)
- **Purpose:** An offline quiz-practice app: folders hold quizzes, JSON imports bring in MCQ/MSQ/Numerical questions, attempts are timed, and every answer can be reviewed.
- **Platforms:** Android and iOS launcher icons; Windows `.ico` generated from the chosen master as well.
- **Brand colours:** forest green `#3A5A40`, warm off-white `#F8F8F4`, sage `#A9C7AF`, ink `#1B1C18`.
- **Style:** minimal, flat, softly geometric, strong silhouette, no fine detail, readable at 48 px.
- **Must include:** a centred mark with about 22% padding; opaque background; high contrast; works in circle, rounded-square and squircle masks.
- **Must avoid:** words or slogans, tiny detail, thin lines, photos, device frames, shadows spilling outside the mark, busy patterns, mathematical symbols.
- **Chosen concept:** (empty until approved)

## Concepts

| # | Name | Mark | Files |
|---|---|---|---|
| A | Monogram Q | A single bold Q: one round bowl with a short diagonal tail, forest green on cream | `concepts/concept_a_q.svg`, `concepts/concept_a_q_1024.png` |
| B | Folder check | A forest-green folder holding a white quiz card with a bold check | `concepts/concept_b_folder_check.svg`, `concepts/concept_b_folder_check_1024.png` |
| C | Nested frames | Three concentric rounded frames, the innermost filled sage, drifting slightly down-right | `concepts/concept_c_nested_frames.svg`, `concepts/concept_c_nested_frames_1024.png` |

All three are hand-built vectors (SVG sources kept beside the PNGs), so they stay sharp when exported at any size. Preview them in `index.html`.

## What happens after approval

1. The chosen PNG becomes the single master.
2. Generate Android legacy, adaptive (foreground/background) and monochrome icons, iOS `AppIcon`, and Windows `.ico`.
3. Rebuild the Android APK and Windows app, then check the launcher and taskbar.
4. Record the choice here and in the progress log.

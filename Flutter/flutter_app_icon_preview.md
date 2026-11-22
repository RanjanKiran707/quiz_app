# Flutter App Icon Preview

How an app icon is designed, previewed and installed. Whenever the user asks for an app icon, produce **three distinct previews** from their design request, show them side by side, and install only the one they choose.

Never install or overwrite the launcher icon without an explicit choice.

---

## 1. When it runs

- The user asks for an app icon, launcher icon, or app logo.
- The app is approaching a release and has no icon yet.
- The user asks to change an existing icon.

It can run at any time. It does not block the Data, Use case or Feature phases, except that the chosen icon must be installed before a release build.

---

## 2. Inputs

Ask for anything missing before generating. Do not guess silently.

| Input | Why it matters |
|---|---|
| App name | Used for the monogram concept and the preview |
| What the app does | Drives the literal and abstract concepts |
| Brand colours | Keep all three concepts in the same family |
| Style words | Flat, soft gradient, glassy, playful, serious, minimal |
| Things to avoid | Symbols or colours that mean something else in the user's market |
| Platforms | Android, iOS, both; adaptive and themed icons only apply to Android |
| Existing assets | Logo, brand mark, fonts that must be reused |

Save the answers to `docs/icon_preview/brief.md`:

```markdown
# Icon brief

- App name:
- Purpose:
- Platforms:
- Brand colours:
- Style:
- Must include:
- Must avoid:
- Chosen concept: (empty until approved)
```

---

## 3. The three concepts

The three previews must be **genuinely different ideas**, not the same mark in three colours. Use these three directions:

| # | Concept | What it is | Example |
|---|---|---|---|
| A | **Monogram** | One letter or a two-letter mark, custom-drawn, no font defaults | `S` built from two rounded strokes |
| B | **Literal** | A simple object or action from the app's purpose | A notebook for a notes app |
| C | **Abstract** | A geometric metaphor for the product's benefit | Overlapping rings for connection |

Rules:
- All three use the same palette family, so the choice is about the idea, not the colour.
- Each concept gets a one-sentence rationale, written for the user.
- Flat or softly shaded, centred, with 20–25% padding.
- No text except a single monogram letter.
- No device frame, no drop shadow spilling outside the artwork, no photo, no mockup background.
- Strong silhouette that still reads at 48 px.

---

## 4. Generate the masters

Generate **one 1024 × 1024 PNG per concept**, on an opaque background (iOS does not allow transparency). Use the session's image generation tool, one call per concept.

Prompt template:

```
A mobile app icon, 1024x1024, square, for "<app name>", a <purpose>.
Concept <A|B|C>: <one-line idea>.
Style: <flat / soft gradient / ...>, palette <hex codes>, centred mark with 22% padding,
simple strong silhouette, readable at 48px, no text (except a single monogram letter),
no device frame, no mockup background, no drop shadow outside the mark,
opaque background, crisp edges, high contrast.
```

Then save:

```
docs/icon_preview/
├── index.html
├── brief.md
└── concepts/
    ├── concept_a_<slug>_1024.png
    ├── concept_b_<slug>_1024.png
    └── concept_c_<slug>_1024.png
```

Rules:
- Keep the 1024 px masters. Every platform size is derived from them.
- Never upscale a small preview.
- If a concept fails the checks in section 5, regenerate that concept only; keep the other two.
- Do not generate a fourth concept unless the user rejects all three.

---

## 5. Validate before showing

Check each master:

- [ ] Reads clearly at 48 px and 96 px.
- [ ] Still recognisable in greyscale.
- [ ] Works on light and dark home screens.
- [ ] Survives a circle, rounded-square and squircle mask without clipping the mark.
- [ ] The mark sits inside the central 66% (Android adaptive safe zone).
- [ ] Contrast between mark and background is at least 3:1.
- [ ] No thin lines, small details or gradients that band at small sizes.
- [ ] No transparency on the iOS master.

Fix failures before building the preview page.

---

## 6. The preview page

Create `docs/icon_preview/index.html`: one self-contained page that opens from `file://` and loads the three PNGs by relative path.

It must show:

1. **Header:** app name, the brief in one line, and the date.
2. **Three concept cards side by side**, each with:
   - the 512 px icon;
   - concept letter, name and one-line rationale;
   - a **Choose this icon** button that marks it selected and writes the choice to `brief.md` (the agent does this after the user replies; the page can only highlight the selection).
3. **Size ladder** per concept: 512, 192, 96, 48 px, labelled, so small-size legibility is obvious.
4. **Mask row** per concept: circle, rounded square (22%), and iOS squircle.
5. **Background row** per concept: white, near-black, and the brand colour.
6. **Home screen mock:** one small iOS-style grid and one Android-style grid, each with the icon among neutral placeholder apps.
7. **Comparison strip:** the three 96 px icons in a row, for a quick side-by-side.
8. **Notes:** palette, safe-zone check, and any known limitation.

Rules:
- Same page layout for all three; the only differences are the icons and their rationale.
- No external libraries. Inline CSS and a few lines of vanilla JS for selection.
- Label sizes in pixels; do not resize the browser window to prove a point.
- The page is a review tool, not a deliverable asset.

---

## 7. Present and choose

1. Open `docs/icon_preview/index.html` for the user.
2. Summarise the three ideas in one line each and recommend one, with the reason (legibility, distinctiveness, fit with the product).
3. The user picks A, B or C, or asks for changes.
4. If they ask for changes, change only the chosen concept and re-run section 5. Keep the other two untouched until the choice changes.
5. Record the choice in `brief.md` under **Chosen concept**.
6. Only then continue to section 8.

---

## 8. Export and install

Copy the chosen master to `assets/icon/app_icon_1024.png` (create the folder). Derive every size from it.

### iOS

Create `ios/Runner/Assets.xcassets/AppIcon.appiconset/` with an opaque PNG for each slot and a `Contents.json`:

| Size (pt) | Scales | Pixels |
|---|---|---|
| 20 | 2x, 3x | 40, 60 |
| 29 | 2x, 3x | 58, 87 |
| 40 | 2x, 3x | 80, 120 |
| 60 | 2x, 3x | 120, 180 |
| 1024 | 1x (marketing) | 1024 |

Rules: no alpha channel, no rounded corners baked in (iOS applies the mask), sRGB.

### Android

| Density | Launcher PNG |
|---|---|
| mdpi | 48 × 48 |
| hdpi | 72 × 72 |
| xhdpi | 96 × 96 |
| xxhdpi | 144 × 144 |
| xxxhdpi | 192 × 192 |

Adaptive icon (Android 8+):
- `res/mipmap-anydpi-v26/ic_launcher.xml` and `ic_launcher_round.xml` referencing `@drawable/ic_launcher_foreground` and `@color/ic_launcher_background`.
- Foreground layer: 432 × 432 px, with the mark inside the central 264 × 264 px (66 dp safe zone).
- Background layer: solid colour or gradient, 432 × 432 px.
- Optional monochrome layer for themed icons, same safe zone, single colour.

### Flutter (recommended)

Add `flutter_launcher_icons` as a dev dependency and configure `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon_1024.png"
  adaptive_icon_background: "#0F172A"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground_432.png"
  adaptive_icon_monochrome: "assets/icon/app_icon_monochrome_432.png"
  remove_alpha_ios: true
```

Then run:

```
dart run flutter_launcher_icons
```

Keep the generated files in version control. If the project must not use the package, write the platform files directly from the masters.

### Web (only if the app ships a web build)

Add `web/favicon.png` at 32 × 32 and `web/icons/Icon-192.png` / `Icon-512.png`. Maskable icons need the same 66% safe zone.

---

## 9. Verify the install

- [ ] The launcher shows the new icon on a real device or emulator, both platforms.
- [ ] No transparency on iOS; App Store validation accepts the 1024 marketing icon.
- [ ] Android adaptive icon is not clipped in circle, squircle or rounded-square launchers.
- [ ] Themed/monochrome icon looks correct if enabled.
- [ ] Splash screen (if any) uses the same mark and background.
- [ ] Old icon files are removed or replaced, not left beside the new ones.
- [ ] `flutter analyze` still passes and the app still builds.

---

## 10. Do not

- Do not generate a single icon and call it a preview.
- Do not show three colour swaps of the same mark.
- Do not install an icon before the user chooses.
- Do not overwrite an existing icon without asking.
- Do not use transparency for iOS.
- Do not put the mark outside the Android safe zone.
- Do not upscale a small PNG to make a large one.
- Do not add text, slogans or tiny details that vanish at 48 px.

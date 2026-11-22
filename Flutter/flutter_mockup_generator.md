# Flutter Mockup Generator

A high-fidelity, fully working clickable prototype of the whole app, built **before** any Flutter code. It runs in a browser, uses mock data for the database, and sends every request through a fake HTTP layer. Nothing is static and nothing is a dead end: every screen, button, form, list and state works.

It is the visual and behavioural source of truth for Phase 3 (Features). The real app is built to match it.

Run it after `docs/data_model.html` exists and before `flutter create` (step 4 of `flutter_initial_setup.md`).

---

## 1. Inputs and outputs

**Read first:**
- the product spec (the only source of features and copy);
- `docs/data_model.html` (entities, fields, keys, relationships);
- `docs/dependencies.html` (which platform features the app needs).

**Produce:**

```
docs/mockup/
├── index.html        one self-contained file: styles, mock DB, fake HTTP, screens
├── screens.md        screen inventory, states and endpoint map
└── assets/           optional local fonts, photos, icons
```

- `index.html` must open by double-clicking it. No server, no build step, no package install.
- Keep it a **single file** unless assets make it unwieldy. If you split it, use plain `<script src="...">`, never ES modules or `fetch()` of local JSON, because browsers block those on `file://`.
- The mockup is disposable. It lives in `docs/` and is never imported by `lib/`.

---

## 2. Non-negotiable rules

1. **Everything works.** No dead buttons, no "coming soon", no links to `#`. If a control exists, it changes state or navigates.
2. **No real backend.** No real database, no real API, no Firebase, no Supabase. All data lives in the mock DB in memory, persisted to `localStorage`.
3. **No screen reads the mock DB directly.** Screens call the fake HTTP layer only. This keeps the mockup honest and makes the mapping to repositories mechanical.
4. **High fidelity.** Real typography, spacing, colour, icons and imagery. No lorem ipsum, no grey placeholder boxes, no default browser form controls.
5. **Every state is reachable.** Loading, empty, error, offline, success and validation states are implemented, not just the happy path.
6. **Data survives reload.** Create, edit and delete persist in `localStorage` until the user resets the mock data.
7. **Realistic data.** Seed at least 8–12 rows per main list, with believable names, dates, amounts and relationships. Seed data must respect every foreign key and enum in `docs/data_model.html`.
8. **No console errors or warnings.** Check the browser console before presenting.

---

## 3. Screen inventory

List every screen in `docs/mockup/screens.md` before building. Use this table:

| # | Screen | Route | Purpose | States | Endpoints used |
|---|---|---|---|---|---|
| 1 | Student list | `#/students` | Browse and search students | loading, empty, error, loaded | `GET /api/students` |
| 2 | Student details | `#/students/:id` | View one student | loading, error, loaded | `GET /api/students/:id` |
| 3 | Add student | `#/students/new` | Create a student | idle, saving, error, success | `POST /api/students` |

Rules:
- Every screen in the product spec appears in the table. Nothing is skipped because it "looks hard".
- Include the secondary screens: settings, profile, auth, onboarding, paywall, dialogs, bottom sheets and confirmation prompts.
- Add the states the spec implies, even if it does not name them (an empty search result, a failed save, a slow network).
- One route per screen, so the browser back button and deep links work.

---

## 4. Mock database

Mirror `docs/data_model.html` exactly: same entity names, field names, types, primary keys, foreign keys and relationships. The mock DB is the future database, not a simplified sketch.

```js
// 1. MOCK DB — mirrors docs/data_model.html
const SEED = {
  classes: [
    { id: 'c1', classNumber: 10, section: 'A' },
    { id: 'c2', classNumber: 10, section: 'B' },
  ],
  students: [
    { id: 's1', name: 'Aarav Sharma', age: 15, classId: 'c1' },
    { id: 's2', name: 'Meera Iyer',   age: 14, classId: 'c2' },
  ],
};

const DB_KEY = 'mockup_db_v1';
let db = JSON.parse(localStorage.getItem(DB_KEY) || 'null') || structuredClone(SEED);
const changeListeners = new Set();

function commit() {
  localStorage.setItem(DB_KEY, JSON.stringify(db));
  changeListeners.forEach((fn) => fn());
}

/** Re-runs a query whenever the given table changes — the mock version of a Stream. */
function watchTable(table, callback) {
  changeListeners.add(callback);
  return () => changeListeners.delete(callback);
}

function resetDb() {
  db = structuredClone(SEED);
  commit();
}
```

Rules:
- IDs are stable strings (`s1`, `c1`). New records use `crypto.randomUUID()` or a counter.
- Deleting a parent handles its children the way the data model says (cascade, block, or set null). Show the matching confirmation dialog.
- Bump `DB_KEY` when the seed shape changes, so old local data does not break the mockup.
- `resetDb()` is exposed in the developer toolbar (section 8).

---

## 5. Fake HTTP layer

All app data goes through HTTP-shaped calls with a real request/response contract. Override `window.fetch` once, so screens can be written exactly as they will be in the real client:

```js
// 2. FAKE HTTP — real fetch semantics, no network
window.__mock = { latencyMs: 350, errorRate: 0, offline: false };

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });

const routes = [
  {
    method: 'GET',
    path: /^\/api\/students(\?.*)?$/,
    handler: ({ query }) => {
      const search = (query.get('q') || '').toLowerCase();
      const rows = db.students.filter((s) => s.name.toLowerCase().includes(search));
      return { status: 200, body: { data: rows, total: rows.length } };
    },
  },
  {
    method: 'POST',
    path: /^\/api\/students$/,
    handler: ({ body }) => {
      if (!body?.name?.trim()) {
        return { status: 422, body: { error: { code: 'name_required', message: 'Name is required.' } } };
      }
      const row = { id: crypto.randomUUID(), name: body.name.trim(), age: body.age, classId: body.classId };
      db.students.push(row);
      commit();
      return { status: 201, body: { data: row } };
    },
  },
];

window.fetch = async (input, init = {}) => {
  const raw = typeof input === 'string' ? input : input.url;
  const url = new URL(raw, location.href);
  const method = (init.method || 'GET').toUpperCase();
  const body = init.body ? JSON.parse(init.body) : null;

  await sleep(window.__mock.latencyMs);

  if (window.__mock.offline) {
    return json({ error: { code: 'offline', message: 'No connection.' } }, 503);
  }
  if (Math.random() < window.__mock.errorRate) {
    return json({ error: { code: 'server_error', message: 'Something went wrong.' } }, 500);
  }

  const route = routes.find((r) => r.method === method && r.path.test(url.pathname + url.search));
  if (!route) {
    return json({ error: { code: 'not_found', message: 'Not found.' } }, 404);
  }
  const result = route.handler({ url, query: url.searchParams, body });
  return json(result.body, result.status);
};
```

Contract rules:
- JSON in, JSON out. Success is `{ data: ... }` (plus `page`, `total`, `nextCursor` where needed). Failure is `{ error: { code, message } }`.
- Status codes are real: `200`, `201`, `204` (no body), `400`, `401`, `403`, `404`, `409`, `422`, `500`, `503`.
- Latency is 150–700 ms and visible: every call shows a loading state.
- Pagination, search, sort and filter are implemented **in the handler**, not in the screen.
- Mutations call `commit()`, so lists update live through `watchTable`.
- Never use `fetch` for anything except `/api/...`. Fonts and images are assets, not API calls.

Map each endpoint to the Flutter layer it becomes, at the bottom of `screens.md`:

| Mock endpoint | Future Flutter code |
|---|---|
| `GET /api/students` | `StudentRepositoryInterface.watchStudents()` |
| `POST /api/students` | `StudentRepositoryInterface.addStudent(StudentModel)` |
| `PATCH /api/students/:id` | `StudentRepositoryInterface.updateStudent(...)` |
| `DELETE /api/students/:id` | `StudentRepositoryInterface.deleteStudent(id)` |

If an endpoint has no clean repository match, the data model or the feature boundary is wrong. Fix it now, and update `docs/data_model.html` if entities change.

---

## 6. High fidelity

Build it to look like a shipped app, not a wireframe.

- **Design direction:** take colours, type and tone from the product spec. If the spec has none, propose a small style tile (palette, two typefaces, one component sample) and get the user's approval before building all screens.
- **Device frame:** a 390 × 844 phone frame with status bar, safe areas, scroll and a home indicator. On narrow windows the frame fills the viewport instead.
- **Typography:** a real font pair from Google Fonts (for example Inter + a display face), with a proper type scale. Bundle the fonts in `assets/` if the mockup must work offline.
- **Icons:** one icon set throughout (Lucide or Material Symbols). Never mix sets.
- **Imagery:** real photos (Unsplash/Picsum) or locally bundled images. Crop them properly; no stretched or grey boxes.
- **Components:** build the app's real components once (button, card, list row, chip, input, sheet, snackbar) and reuse them. No default `<input>` or `<select>` styling.
- **Motion:** 150–250 ms transitions for navigation, sheets, toasts and pressed states. Respect `prefers-reduced-motion`.
- **Copy:** realistic labels, empty-state text and error messages from the spec. No lorem ipsum.
- **Theme:** support light and dark if the spec asks for it; otherwise pick one and use it consistently.

---

## 7. States and interactions

Implement all of these, for every screen where they apply:

| State | What the user sees |
|---|---|
| Loading | Skeleton or spinner that matches the final layout; controls disabled |
| Empty | Illustration or icon, one line of explanation, one action |
| Error | Failure message chosen from the error `code`, plus a retry button |
| Offline | A persistent banner and retry; writes are blocked |
| Validation | Inline field errors; submit disabled until valid |
| Saving | Button shows a spinner and is disabled; back is blocked |
| Success | Toast or inline confirmation, then the expected navigation |
| Not found | Friendly message and a way back |

Interaction rules:
- Forms validate on submit and clear their error when the field changes.
- Submitting twice does nothing (the mock of the blocking rule in `flutter_arch_general.md`).
- Back and browser-back work everywhere. Unsaved-changes prompts appear where the spec requires them.
- Search is debounced; filters and sort persist while the screen is open.
- Lists update after a create, edit or delete without a manual refresh.
- Destructive actions ask for confirmation and name the item.
- Long lists scroll; pull-to-refresh can be simulated with a button or gesture.

---

## 8. Developer toolbar

Outside the phone frame, add a small toolbar (hidden in a screenshot mode) with:

- **Screen jump:** a dropdown of every route.
- **Reset data:** calls `resetDb()` and reloads the current screen.
- **Latency:** 0 / 150 / 350 / 700 ms.
- **Error rate:** 0% / 10% / 30%, to demo error states.
- **Offline:** toggle.
- **Theme:** light / dark.
- **Network log:** the last 50 requests as `method path → status (ms)`, so the HTTP layer is visible.
- **Screenshot mode:** hides the toolbar and frame chrome for clean captures.

The toolbar is for review only. It must not be reachable from inside the app UI.

---

## 9. Definition of done

The mockup is ready to show when all of these are true:

- [ ] Every screen in `screens.md` exists and opens from the app itself, not only from the toolbar.
- [ ] Every button, tab, link, row, icon and menu item does something.
- [ ] Create, read, update and delete all work and survive a page reload.
- [ ] Loading, empty, error, offline and validation states are reachable from the toolbar.
- [ ] All seed data is realistic and respects every foreign key.
- [ ] No `fetch` reaches the network; the network log shows only `/api/...` routes.
- [ ] No console errors or warnings.
- [ ] It looks correct at 360, 390 and 430 px widths, and in light and dark if both are supported.
- [ ] It opens from `file://` with no server.
- [ ] `screens.md` lists every screen, state and endpoint, with the Flutter mapping table filled in.

---

## 10. Review and handoff

1. Present `docs/mockup/index.html` and a short summary: screens built, flows covered, decisions taken, anything deliberately left out.
2. The user reviews and requests changes. Update the mockup and `screens.md` together.
3. Do not start Phase 1 until the mockup is approved.
4. In Phase 3, each feature's View and ViewModel reproduce the approved mockup: same layout, copy, states and navigation. The mock endpoint becomes the repository method from the mapping table.
5. If a feature needs a screen or state the mockup does not have, update the mockup first, get it approved, then build it.

---

## 11. Do not

- Do not use Flutter, React or any framework for the mockup.
- Do not connect to a real API, database or auth provider.
- Do not hardcode data inside screens; it must come from the fake HTTP layer.
- Do not leave dead controls or placeholder screens.
- Do not use lorem ipsum or grey image boxes.
- Do not skip the empty, error or offline states.
- Do not copy the mockup HTML into `lib/`. Only its design and behaviour carry over.

# Flutter Initial Setup

Run these steps once, after reviewing the product spec provided by the user and before any app code is written. Afterwards the user will ask you to build the app based on `flutter_arch_general.md`.

Ask the user for anything missing: the product spec, the app name (snake_case), and the git `origin` URL.

1. **Initialize git and push to origin**
   - `git init -b main`, add the `origin` remote, commit, and `git push -u origin main`.
   - If the push fails, report the error and ask the user. Never force-push.

2. **Analyse the dependencies**
   - List every third-party Flutter package (pub.dev) the product spec needs, such as storage, networking, UI, device features and dev tools.
   - Do not add packages for what `flutter_arch_general.md` already provides: Result, ViewState, state management and dependency wiring.
   - Save the list to `docs/dependencies.html`, with each package's purpose, and get the user's approval before installing.

3. **Create the data modelling for the data layer**
   - Identify the entities, fields, primary and foreign keys, and relationships from the spec.
   - Create an interactive ER diagram using Cytoscape.js and save it to `docs/data_model.html`.
   - Get the user's approval of the model.

4. **Build the high-fidelity mockup**
   - Follow `flutter_mockup_generator.md` and save the result to `docs/mockup/index.html`.
   - Every screen, state and flow in the spec must work, using mock data and fake HTTP calls.
   - Get the user's approval before writing any app code.

5. **Run `flutter create`**
   - `flutter create . --project-name <app_name>` inside the repository.
   - Add the approved packages with `flutter pub add`, then run `flutter analyze`.
   - Commit and push.
   - Do not write any `lib/` code yet.

When the user asks for an app icon, follow `flutter_app_icon_preview.md`.

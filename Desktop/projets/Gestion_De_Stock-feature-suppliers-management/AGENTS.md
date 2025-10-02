# Repository Guidelines

## Project Structure & Module Organization
- Entry: `lib/main.dart`.
- Domain: `lib/models`, `lib/providers`, `lib/services`.
- UI: screens in `lib/screens/`, reusable widgets in `lib/widgets/`.
- Utilities: `lib/helpers/`; enums/constants in `lib/constants/`; seed data in `lib/data/`.
- Assets: icons in `assets/`, larger media in `resources/`.
- Platform scaffolding: `android/`, `ios/`, `macos/`, etc.
- Tests mirror `lib/` under `test/` (e.g., `test/screens/supplier_overview_screen_test.dart`).

## Build, Test, and Development Commands
- `flutter pub get` — install/update dependencies.
- `flutter run -d macos` — run desktop app; use `-d chrome` for web.
- `flutter analyze` — static analysis; keep zero warnings.
- `dart format lib test` — format source and tests.
- `flutter test` — run unit/widget tests; add `--coverage` for coverage data.
- `flutter build macos` — build production macOS binary.

## Coding Style & Naming Conventions
- Lints via `analysis_options.yaml` (derived from `flutter_lints`).
- Two-space indent; trailing commas in widget trees for clean diffs.
- Naming: Classes `PascalCase`; variables/functions `lowerCamelCase`; files `snake_case` (e.g., `supplier_overview_screen.dart`).
- Organize UI by feature; keep UI state in providers, not local singletons.

## Testing Guidelines
- Place tests by feature under `test/` with `*_test.dart` suffix.
- Mock DB calls touching `sqflite` using `sqflite_common_ffi` to stay platform-agnostic.
- Include at least one golden or widget smoke test for new screens/complex layouts.
- Run `flutter test`; add `--coverage` when updating analytics dashboards.

## Commit & Pull Request Guidelines
- Conventional commits: `feat:`, `fix:`, `refactor:`, `chore:`; subject ≤ 72 chars.
- Describe motivation in the body when helpful.
- PRs: link related issues, summarize functional changes, attach screenshots/screencasts for UI.
- Ensure CI-ready state: `flutter analyze` clean, tests pass, and new config files document any manual steps.

## Agent & Contributor Notes
- Scope applies repo-wide. Prefer minimal, surgical changes; avoid unrelated refactors.
- Follow the structure and naming above to keep diffs small and reviews fast.
- Update documentation alongside behavior changes.


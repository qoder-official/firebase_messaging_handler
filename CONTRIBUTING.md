# Contributing

Thanks for contributing to `firebase_messaging_handler`.

## Scope

This package is trying to be the most practical open source FCM layer for Flutter. Changes should improve reliability, package ergonomics, documentation quality, or platform coverage without creating avoidable API churn.

## Ground Rules

- Keep public API changes additive unless a breaking change is explicitly planned.
- Match existing package structure under `lib/src/` rather than introducing ad hoc files.
- Add or update tests for behavior changes.
- Prefer physical-device validation notes for FCM, APNs, or browser push changes.
- Keep README and docs aligned with any user-facing behavior change.

## Local Setup

1. Install a recent stable Flutter SDK.
2. Run `flutter pub get` in the package root.
3. Run `flutter analyze`.
4. Run `flutter test`.
5. If your change touches the example app, run it on the relevant platform before opening a PR.

## Project Layout

- `lib/`: public API and implementation
- `example/`: showcase app and manual validation surface
- `test/`: package unit and widget coverage
- `integration_test/`: higher-level behavior checks
- `documentation/`: internal planning and status notes
- `docs/`: public GitHub Pages documentation

## Pull Requests

Please include:

- A concise problem statement
- The behavior change or API change
- Test coverage added or updated
- Manual validation performed
- Screenshots or recordings for UI changes

Small focused PRs are easier to review than large mixed refactors.

## Release-Sensitive Changes

Be careful when changing:

- Background message handling and isolate entry points
- Token retrieval and refresh behavior
- Platform declarations in `pubspec.yaml`
- Example app setup instructions
- Any API used in README snippets

## Style

- Follow `flutter_lints`
- Prefer clear names over clever abstractions
- Add brief comments only where code is non-obvious
- Do not commit generated noise unrelated to the task

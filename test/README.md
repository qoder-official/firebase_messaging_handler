# Tests

How to run everything:
```
flutter test
```

What’s covered now:
- `initial_click_queue_test.dart`: verifies click events queue until listeners attach (auto-initial flow).
- `inbox_golden_test.dart`: golden for inbox view (alchemist).

Notes:
- Goldens live under `test/` (alchemist). Update with `flutter test --update-goldens` when visual diffs are intentional.
- Ensure `uses-material-design: true` is set (already in the root pubspec) so alchemist icon fonts resolve.


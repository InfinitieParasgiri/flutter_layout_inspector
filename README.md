# flutter_layout_inspector

A zero-dependency Flutter layout inspector. Drop it into any project and tap widgets to instantly see their type, screen, file path, size and position — all without leaving the app.

> **Auto-disabled in release builds. Zero overhead in production.**

---

## Preview

```
┌─── 🔍 Layout Inspector ────────────────────────
│  Widget  : ElevatedButton
│  Screen  : HomeScreen
│  File    : lib/**/elevated_button.dart
│  Size    : 160 × 48 px
│  Position: (108, 342)
└────────────────────────────────────────────────
```

---

## Installation

### Option A — GitHub (recommended before pub.dev publish)

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_layout_inspector:
    git:
      url: https://github.com/YOUR_USERNAME/flutter_layout_inspector.git
      ref: main   # or a tag like v1.0.0
```

Then run:

```bash
flutter pub get
```

### Option B — pub.dev (after publishing)

```yaml
dependencies:
  flutter_layout_inspector: ^1.0.0
```

### Option C — Local path (monorepo / side-by-side)

```yaml
dependencies:
  flutter_layout_inspector:
    path: ../flutter_layout_inspector
```

---

## Usage

Wrap your root widget (or `MaterialApp`) with `LayoutInspector`:

```dart
import 'package:flutter_layout_inspector/flutter_layout_inspector.dart';

void main() {
  runApp(
    LayoutInspector(child: const MyApp()),
  );
}
```

**That's it.** No other setup needed.

### How to use

1. Run your app in **debug mode**.
2. Tap the **🔍 FAB** in the bottom-right corner to activate.
3. Tap **any widget** on screen.
4. An info panel appears showing:
   - **Widget** type
   - **Screen** / Page name
   - **File** path (best-effort)
   - **Size** in pixels
   - **Position** on screen
5. Full details + filtered stack trace are printed to the **debug console**.
6. Tap **✕** on the panel or tap the FAB again to deactivate.

---

## Release builds

`LayoutInspector` checks `kReleaseMode` and renders **only** the child widget — no FAB, no overlay, no listeners. It is completely safe to ship in production.

---

## API

| Parameter | Type     | Description                        |
|-----------|----------|------------------------------------|
| `child`   | `Widget` | Your app or root widget. Required. |

```dart
LayoutInspector({
  Key? key,
  required Widget child,
})
```

---

## Project structure

```
flutter_layout_inspector/
├── lib/
│   ├── flutter_layout_inspector.dart   ← public export
│   └── src/
│       └── layout_inspector.dart       ← full implementation
├── example/
│   └── lib/
│       └── main.dart                   ← demo app
├── test/
│   └── layout_inspector_test.dart
├── pubspec.yaml
├── CHANGELOG.md
└── README.md
```

---

## Publishing to pub.dev (optional)

```bash
flutter pub publish --dry-run   # check for issues first
flutter pub publish             # publish
```

---

## License

MIT — see [LICENSE](LICENSE).

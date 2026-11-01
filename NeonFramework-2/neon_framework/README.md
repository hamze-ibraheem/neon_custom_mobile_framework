# neon_framework ⚡

> **A standalone, Flutter-free Dart SDK for building true native mobile applications on Android & iOS.**

[![Dart SDK](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![Tests](https://img.shields.io/badge/Tests-403%20Passing-brightgreen?style=flat)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## What is `neon_framework`?

`neon_framework` is a complete mobile application development SDK written entirely in Dart. It empowers developers to build mobile apps using declarative widgets, reactive signals, and native components without requiring Flutter, Skia, or Impeller.

### Core Highlights

- **100% Native Views**: Widgets map directly to genuine native platform components (`android.widget.*` on Android, UIKit `UIView` on iOS).
- **HTTP UI Server & Bridge**: The Dart runtime runs an embedded HTTP server serving the widget tree over JSON (`/api/tree`) and handling actions (`/action`).
- **High-Speed Tree Diffing**: In-place native view property updates with up to **98% payload compression**, keeping focus, keyboard, and scroll state intact.
- **Modern Material 3 Suite**: 40+ widgets including `FilledButton`, `SegmentedButton`, `NeonTextField`, `NeonSearchBar`, `Switch`, `Slider`, `Card`, `Dialog`, `BottomSheet`, `ListView`, and slivers.
- **Signals State Management**: SolidJS-inspired reactive signals (`NeonSignal`, `NeonComputed`, `NeonEffect`) and `NeonAsyncValue`.
- **Declarative Navigation**: Full router with parameter matching, query params, route guards, and history management.
- **Built-in Offline Data Layer**: Type-safe Key-Value store, SQLite with versioned migrations, REST HTTP Client with interceptors, WebSocket with auto-reconnect, and 5 caching policies.
- **Extensible Plugin System**: Dual-mode (Dart and Native) plugins with semantic versioning and dependency validation.

---

## Installation

Add `neon_framework` to your `pubspec.yaml`:

```yaml
dependencies:
  neon_framework:
    path: path/to/neon_framework # or git URL
```

Then run:
```bash
dart pub get
```

---

## Basic Usage

```dart
import 'package:neon_framework/neon.dart';

void main() {
  NeonApp.run(
    const MyCounterApp(),
    config: const NeonConfig(
      environment: NeonEnvironment.development,
      port: 8080,
      enableDiffing: true,
    ),
  );
}

class MyCounterApp extends StatefulWidget {
  const MyCounterApp({super.key});

  @override
  NeonState<MyCounterApp> createState() => _MyCounterAppState();
}

class _MyCounterAppState extends NeonState<MyCounterApp> {
  int _counter = 0;

  @override
  NeonWidget build(NeonBuildContext context) {
    return Container(
      padding: const NeonEdgeInsets.all(24),
      color: NeonColors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Count: $_counter',
            style: const NeonTextStyle(fontSize: 22, color: NeonColors.indigo),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: 'btn_increment',
            onPressed: () {
              setState(() {
                _counter++;
              });
            },
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
```

---

## Architectural Breakdown

```
neon_framework/
├── bin/
│   └── neon.dart                  # Neon developer CLI
├── lib/
│   ├── neon.dart                  # Public barrel export
│   └── src/
│       ├── core/                  # NeonApp, lifecycle, error handlers, config
│       ├── widgets/               # Widget system, Material 3 catalog, tree diff
│       ├── navigation/            # Router, path matcher, guards, controller
│       ├── rendering/             # Constraints, canvas, display lists, animation
│       ├── state/                 # Reactive signals, computed, effects, async values
│       ├── platform/              # Platform channels, bridge, filesystem
│       ├── data/                  # Key-value store, SQLite, HTTP, WebSocket, cache
│       └── plugins/               # Plugin model, registry, semver, hooks
└── test/                          # 403 automated unit and integration tests
```

---

## State Management with Signals

In addition to traditional `setState()`, Neon provides reactive signals:

```dart
final count = NeonSignal<int>(0);
final doubleCount = NeonComputed<int>(() => count.value * 2);

NeonEffect(() {
  print('Current count: ${count.value}, doubled: ${doubleCount.value}');
});

count.value++;
```

---

## Declarative Routing

```dart
final router = NeonRouter(
  initialLocation: '/home',
  routes: [
    NeonRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    NeonRoute(
      path: '/details/:id',
      builder: (context, state) => DetailScreen(id: state.param('id')),
    ),
  ],
);
```

---

## Native Platform Integration

1. Start your Dart application with `dart run lib/main.dart`.
2. Connect your Android app (`MainActivity.kt`) using `adb reverse tcp:8080 tcp:8080`.
3. Connect your iOS app (`ViewController.swift`) pointing to `http://localhost:8080/api/tree`.
4. Open `http://localhost:8080` in your browser for the instant Web Preview.

---

## Testing

Run the full automated test suite:

```bash
dart test
```

All 403 tests pass cleanly.

---

## License

MIT License. See [LICENSE](LICENSE) for details.


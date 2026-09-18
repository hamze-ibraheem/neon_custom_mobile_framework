# neon_mobile_framework

cross platform android and ios mobile application development dart SDK


Neon Framework
Overview
Neon Framework is a custom Dart-based UI framework for building native mobile apps (Android & iOS) without any Flutter dependency. It is a standalone SDK that owns its own runtime, widget system, rendering pipeline, state management, and platform bridges. The framework communicates with native apps via an HTTP-based bridge — the Dart backend runs a local HTTP server that serves a JSON widget tree, and native apps (Android/iOS) fetch this tree, render native UI components, and send user actions back via POST requests.

The project has completed 8 development phases: Vision → Core Runtime → Widget System → Rendering Layer → State Management → Platform Layer → Tooling (CLI) → Storage & Networking → Plugins & Extensibility.

The main framework code lives in neon_framework/ and a test app lives in neon_framework/my_2nd_test_app/ with both Android (Kotlin) and iOS (Swift) native shells.

User Preferences
Preferred communication style: Simple, everyday language.

System Architecture
Core Framework (neon_framework/lib/src/)
The framework follows a layered architecture:

Core Runtime (core/): NeonApp.run() entry point, lifecycle management (onInit, onPause, onResume, onDispose, onHotReload), environment-aware error handling, and configuration via NeonConfig, NeonBuildFlavor, and NeonFeatureFlags.

Widget System (widgets/): Inspired by Flutter's composition model. Includes NeonWidget, StatelessWidget, StatefulWidget, and NeonState. Widgets build a tree (NeonWidgetTree / NeonElement) and serialize to JSON for native rendering. Includes primitives (Text, Button, Container) and layouts (Column, Row, Stack). Material 3 widgets (Switch, Checkbox, Radio, Slider, Chips, Badge, Card, Dialog, BottomSheet, TextField, SearchBar, SearchAnchor, MenuAnchor, MenuBar) are also supported.

Rendering Layer (rendering/): Custom layout engine with constraints, render objects, canvas abstractions, and a render pipeline (Layout → Paint → Composite). Includes animation foundations with curves and spring physics.

State Management (state/): Reactive primitives — NeonSignal (observable values), NeonComputed (derived values), NeonEffect (side effects), and NeonAsyncValue (loading/success/error/cached states). setState() triggers widget tree rebuilds and re-serialization.

Data Layer (storage/, networking/): Key-value store, SQLite database with migrations, HTTP client with interceptors, WebSocket client with auto-reconnect, and a cache policy system (cache-first, network-first, stale-while-revalidate, etc.).

Plugin System (plugins/): Dual-mode architecture supporting Dart-only and native plugins. Includes a plugin registry with dependency resolution, capability conflict detection, lifecycle management, and a hook system. Semantic versioning and SDK constraints are enforced.

CLI Tooling (bin/neon.dart, tooling/): Commands for create, run, build, doctor, clean. Hot reload engine with file watching, debounce, and three reload tiers (UI-only, state-preserving, full).

Platform Bridge Architecture
This is the most important architectural pattern to understand:

Dart side runs an HTTP server (typically on localhost:8080)
GET / returns the full widget tree as JSON
POST /action receives user interactions (widget ID, index, value) and returns the updated widget tree as JSON
Native apps (Android MainActivity.kt, iOS ViewController.swift) fetch the JSON tree, recursively render native UI components, and send actions back when users interact
State updates flow: User taps → native sends POST → Dart finds widget by ID → calls callback → setState() → tree rebuilds → new JSON sent back → native re-renders
Key Design Decisions
No Flutter: This is intentional. The framework owns its entire stack. Don't add Flutter dependencies.
JSON-based rendering: Widgets serialize to JSON maps. The native side interprets these maps to create native Android/iOS views. This is the bridge between Dart logic and native UI.
Widget keys: Interactive widgets must have stable string keys so the native apps can target them for action events. Missing keys was a recurring bug source.
double.infinity handling: JSON doesn't support infinity values. These must be clamped or replaced before serialization.
Microtask timing: setState() is async — the action handler must await Future.delayed(Duration.zero) before rebuilding the tree, to let the microtask queue flush.
Test App Structure
my_2nd_test_app/ contains:

lib/ — Dart app code using the Neon Framework (8 screens: Dashboard, Interaction, Controls, Values, Advanced, Containment, Input, Info & Progress)
android/ — Gradle-based Android project with MainActivity.kt that renders the JSON widget tree
NeonApp/ — Xcode project with ViewController.swift that renders the JSON widget tree on iOS
Recent Changes (Phase 10 - Information & Progress Widgets)
Added 8 new Material 3 widget types: ListTile, LinearProgressIndicator, CircularProgressIndicator, Tooltip, SnackBar, SingleChildScrollView, ListView (with builder/separated variants), CustomScrollView with sliver support (SliverList, SliverAppBar)
Full JSON serialization, action handling, and HTML/CSS/JS web renderer for all new widgets
Native Android (Kotlin) and iOS (Swift) rendering support for all new widgets
New Info & Progress showcase screen demonstrating all new widget types
Navigation bar expanded to 8 tabs
Fixed Radio button generic type crash: added selectValue() method to bypass Dart generic type erasure issue with onChanged callback
Previous phase 9 changes preserved: Card, Dialog, BottomSheet, TextField, SearchBar, MenuAnchor/MenuBar
Fixed web renderer Button click bug: Container type check was matching before Button check in the JS renderer, preventing buttons (whose type is Container but sourceType is Button) from being clickable. Moved isButton/Button check before Container check. Native renderers (Android/iOS) already handled this via isButton flag.
Fixed nested AppBar/NavigationBar rendering: When ShowcaseApp is embedded inside AppLauncher, the AppBar and NavigationBar were nested inside Expanded/ShowcaseApp rather than at root level. Added inline rendering for both widget types in renderWidget() so they display correctly at any nesting depth. Also added NavigationBar, TabBar, and AppBar to the interactable widget list in widget_tree.dart for proper action routing.
Flutter-to-Neon Transpiler (tools/transpiler/)
Purpose: Source-to-source converter that transforms Flutter widget code into Neon-compatible code
Entry point: tools/transpiler/main.dart — runs before the main app in the workflow
Input: Place Flutter .dart files in flutter_input/ directory
Output: Converted files go to lib/neon_compat/ with a barrel export neon_compat.dart
Widget mapping (tools/transpiler/widget_mapping.dart): Maps ~50 Flutter widgets/types to Neon equivalents
Key transformations:
Flutter imports → package:neon_framework/neon.dart
StatelessWidget/StatefulWidget → Neon base classes
State<T> → NeonState<T>
Widget build(BuildContext) → NeonWidget build(NeonBuildContext)
ElevatedButton → FilledButton, TextStyle → NeonTextStyle, EdgeInsets → NeonEdgeInsets, etc.
Key? key → String? key
Removes Flutter-specific imports, handles Scaffold removal
Usage: dart run tools/transpiler/main.dart [input_dir] [output_dir]
Uses: analyzer package for Dart AST parsing to find widget classes
External Dependencies
Dart Packages (from pubspec)
analyzer — Dart AST parsing for the transpiler
args — CLI argument parsing
path — File path manipulation
watcher — File system watching for hot reload
test (dev) — Unit testing
Native Platform Dependencies
Android: Standard Android SDK (API 21+), Kotlin, Gradle. Uses java.net.URL for HTTP communication with the Dart backend. Native widgets include android.widget.Switch, CheckBox, RadioButton, SeekBar, etc.
iOS: UIKit-based (not SwiftUI). Uses URLSession for HTTP communication. Native widgets include UISwitch, UIButton, UISlider, etc. Xcode project targets iOS simulator (arm64).
No Database or External Services
The framework includes its own storage abstractions (key-value store, SQLite) with in-memory backends for testing. There is no external database dependency like Postgres. The HTTP client and WebSocket client are built-in with mock backends available.
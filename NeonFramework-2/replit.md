# Neon Framework

## Overview
Neon Framework is a Dart-based UI framework for building mobile apps (Android & iOS). It is a standalone SDK — no Flutter dependency. Built iteratively in phases following real SDK development patterns.

## Current State
- **Phase 0 (Vision)**: Locked. See `neon_framework/PHASE_0_VISION.md`
- **Phase 1 (Core Runtime)**: Complete.
- **Phase 2 (Widget System)**: Complete.
- **Phase 3 (Rendering Layer)**: Complete.
- **Phase 4 (State Management)**: Complete.
- **Phase 5 (Platform Layer)**: Complete.
- **Phase 6 (Tooling)**: Complete.
- **Phase 7 (Storage & Networking)**: Complete.
- **Phase 8 (Plugins & Extensibility)**: Complete.

## Project Architecture

### Directory Structure
```
neon_framework/
  bin/
    neon.dart                         # CLI entry point (executable)
  lib/
    neon.dart                         # Barrel export
    src/
      core/
        neon_app.dart                 # NeonApp.run() entry point
        lifecycle.dart                # Lifecycle manager (onInit, onPause, onResume, onDispose, onHotReload)
        error_handler.dart            # Environment-aware error handling
        environment.dart              # NeonConfig, NeonBuildFlavor, NeonFeatureFlags
      widgets/
        widget.dart                   # NeonWidget, StatelessWidget, StatefulWidget, NeonState
        build_context.dart            # NeonBuildContext with inherited data
        primitives.dart               # NeonColor, NeonTextStyle, NeonEdgeInsets, enums
        text.dart                     # Text widget
        button.dart                   # Button widget with tap handling
        container.dart                # Container widget (box model)
        layout.dart                   # Column, Row, Stack layout widgets
        widget_tree.dart              # NeonWidgetTree, NeonElement tree builder
      rendering/
        constraints.dart              # NeonSize, NeonOffset, NeonRect, NeonConstraints
        render_object.dart            # NeonRenderObject base class
        canvas.dart                   # NeonCanvas, NeonPaintCommand, NeonDeviceInfo
        render_widgets.dart           # RenderText, RenderContainer, RenderColumn, RenderRow, RenderStack
        render_pipeline.dart          # NeonRenderPipeline (Layout → Paint → Composite)
        animation.dart                # Animation foundation (values, curves, spring, duration)
      state/
        signal.dart                   # NeonSignal, NeonComputed, NeonEffect (reactive primitives)
        async_value.dart              # NeonAsyncValue (loading/success/error/cached)
        state_widget.dart             # SignalMixin, NeonSignalProvider (widget integration)
      platform/
        platform_channel.dart         # NeonPlatformChannel, NeonPlatformDispatcher (message passing)
        platform_bridge.dart          # NeonPlatformBridge singleton (manages all platform services)
        native_renderer.dart          # NeonNativeRenderer (sends paint commands to native canvas)
        platform_info.dart            # NeonPlatformInfo (device info, OS, safe areas)
        file_system.dart              # NeonFileSystem (sandboxed file I/O)
        platform_lifecycle.dart       # NeonPlatformLifecycle (bridges native lifecycle to Neon)
      tooling/
        cli.dart                      # NeonCli runner, NeonLogger
        command_create.dart           # neon create — project scaffolding
        command_run.dart              # neon run — compile and launch with hot reload
        command_build.dart            # neon build — release build for Android/iOS
        command_doctor.dart           # neon doctor — environment checks
        command_clean.dart            # neon clean — wipe build artifacts
        project_template.dart         # NeonProjectTemplate (app/minimal scaffolding)
        neon_project.dart             # NeonProject loader (pubspec + neon.yaml)
        hot_reload.dart               # HotReloadEngine, HotReloadSession
      data/
        kv_store.dart                 # NeonKeyValueStore, NeonKVBackend, NeonMemoryKVBackend
        database.dart                 # NeonDatabase, NeonTableSchema, NeonColumn, NeonMigration
        http_client.dart              # NeonHttpClient, NeonHttpRequest/Response, mock backend
        web_socket.dart               # NeonWebSocket, NeonWebSocketMessage, mock backend
        cache_policy.dart             # NeonCachePolicy, NeonCacheStore, NeonCacheEntry
      plugins/
        plugin.dart                       # NeonPlugin, NeonDartPlugin, NeonNativePlugin, NeonPluginManifest
        plugin_registry.dart              # NeonPluginRegistry, NeonPluginHook, NeonPluginException
        example_plugins.dart              # NeonLoggerPlugin, NeonDeviceInfoPlugin
  example/
    main.dart                         # Example app demonstrating full pipeline
  test/
    core_test.dart                    # Unit tests (307 tests)
  pubspec.yaml
  analysis_options.yaml
  PHASE_0_VISION.md
  PHASE_6_TOOLING.md
  PHASE_7_DATA.md
```

### Key Decisions
- **App Entry**: `NeonApp.run(MyApp())` — clean, namespaced
- **Lifecycle**: Full lifecycle events via observer pattern (onInit, onPause, onResume, onDispose, onHotReload)
- **Error Handling**: Configurable per environment (crash in dev, recover+log in staging/prod)
- **Environment**: Supports Dev/Staging/Prod configs, build flavors, runtime feature flags
- **Widget Model**: StatelessWidget / StatefulWidget split with NeonState
- **Build Method**: `NeonWidget build(NeonBuildContext context)` returns widget tree nodes
- **Immutability**: Hybrid — widget descriptions immutable, state objects mutable with controlled rebuilds
- **Core Widgets**: Text, Button, Container, Column, Row, Stack
- **Widget Tree**: NeonWidgetTree builds NeonElement tree from root widget
- **BuildContext**: Supports inherited data via provide/findAncestor pattern
- **Layout System**: Constraints-based (Flutter-like) — parent passes constraints down, child returns size
- **Render Pipeline**: Layout → Paint → Composite with display list
- **Coordinate System**: Logical pixels + device pixel ratio support
- **Render Objects**: RenderText, RenderContainer, RenderColumn, RenderRow, RenderStack
- **Canvas**: NeonCanvas emits paint commands (drawRect, drawText, drawCircle, drawLine, etc.)
- **Animation Foundation**: NeonAnimationValue, curves (linear, easeIn, easeOut, easeInOut), spring simulation
- **State Management**: Custom reactive signals (NeonSignal, NeonComputed, NeonEffect)
- **Async State**: NeonAsyncValue with loading/success/error/cached states and pattern matching (when/maybeWhen)
- **Signal Integration**: SignalMixin for NeonState auto-rebuilds, NeonSignalProvider for context-based signal sharing
- **Dependency Tracking**: Automatic tracking via _NeonDependencyTracker stack; effects and computeds re-track on each run
- **Platform Bridge**: Method channels + FFI hybrid; singleton NeonPlatformBridge manages all platform services
- **Platform Channels**: Typed bidirectional message passing (NeonPlatformChannel) with mock dispatcher for testing
- **Native Renderer**: NeonNativeRenderer serializes paint commands and submits frames with performance tracking
- **Platform Info**: NeonPlatformInfo provides device info, OS version, safe area insets, dark mode detection
- **File System**: NeonFileSystem with sandboxed storage locations (appDocuments, appCache, appSupport, temp)
- **Platform Lifecycle**: NeonPlatformLifecycle bridges native lifecycle events (Android Activity / iOS AppDelegate) to Neon's lifecycle manager
- **CLI**: `neon` command with create/run/build/doctor/clean subcommands, powered by `args` package
- **Project Scaffolding**: App and minimal templates with neon.yaml project config
- **Hot Reload**: Three-tier strategy (UI-only, state-preserving, full fallback) with file watcher and debounce
- **Key-Value Store**: Typed KV store with backend abstraction and prefix-based namespace isolation
- **SQLite Database**: Schema-based table definitions, migrations, and query builder with mock backend
- **HTTP Client**: REST client with interceptors, base URL resolution, mock backend for testing
- **WebSocket**: Real-time client with auto-reconnect, JSON messaging, and event hooks
- **Cache Policy**: Five strategies (cache-first, network-first, cache-only, network-only, stale-while-revalidate) with TTL-based cache store
- **Plugin Model**: Dual-mode (Dart-only + Native) with NeonPlugin base class, manifest-driven registration
- **Plugin Registry**: Singleton with dependency resolution, capability conflict detection, SDK version validation
- **Plugin Hooks**: Named hook system for loose coupling between plugins and app code
- **Plugin Distribution**: Git-based primary, manual import, registry deferred
- **Philosophy**: Custom hybrid (Flutter tree + Compose functions + SwiftUI diffing)

### Phase Plan
| Phase | Name | Status |
|-------|------|--------|
| 0 | Vision & Constraints | Locked |
| 1 | Core Runtime | Complete |
| 2 | Widget System | Complete |
| 3 | Rendering Layer | Complete |
| 4 | State Management | Complete |
| 5 | Platform Layer | Complete |
| 6 | Tooling | Complete |
| 7 | Storage & Networking | Complete |
| 8 | Plugins & Extensibility | Complete |
| 9 | Optimization & Stability | Pending |

## User Preferences
- Building iteratively with `.md` prompt files per phase
- VS Code support for building apps with Neon SDK
- Final output: downloadable Neon SDK (Dart package)
- Target platforms: Android & iOS only

## Recent Changes
- 2026-02-09: Phase 0 vision locked, Phase 1 core runtime implemented and tested
- 2026-02-09: Phase 2 widget system implemented — StatelessWidget/StatefulWidget, core widgets, widget tree builder, 45 tests passing
- 2026-02-09: Phase 3 rendering layer implemented — constraints-based layout, render pipeline, canvas with paint commands, animation foundation, 72 tests passing
- 2026-02-09: Phase 4 state management implemented — NeonSignal, NeonComputed, NeonEffect, NeonAsyncValue, SignalMixin, NeonSignalProvider, 102 tests passing
- 2026-02-09: Phase 5 platform integration implemented — NeonPlatformChannel, NeonPlatformBridge, NeonNativeRenderer, NeonPlatformInfo, NeonFileSystem, NeonPlatformLifecycle, 131 tests passing
- 2026-02-09: Phase 6 tooling implemented — CLI (create/run/build/doctor/clean), project templates, hot reload engine, 169 tests passing
- 2026-02-09: Phase 7 storage & networking implemented — KV store, SQLite database, HTTP client, WebSocket, cache policies, 250 tests passing
- 2026-02-09: Phase 8 plugins & extensibility implemented — Plugin model (Dart-only + Native), plugin registry with dependency/capability validation, hooks, logger & device-info example plugins, 307 tests passing

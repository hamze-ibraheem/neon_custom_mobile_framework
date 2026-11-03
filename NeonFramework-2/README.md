# Neon Framework Project Workspace ⚡

<p align="center">
  <img src="../assets/neon_hero_banner.jpg" alt="Neon Framework" width="460" />
</p>

Welcome to the **Neon Framework** workspace.

Neon Framework is a standalone, Flutter-free Dart mobile UI framework for Android & iOS.

## Workspace Layout

- **[`neon_framework/`](file:///Users/hamzaalsarsour/Untitled/neon_custom_mobile_framework/NeonFramework-2/neon_framework/)**: The core Neon Framework SDK package containing the runtime, **`NeonLang` (`.neon`) compiler (`neonc`)**, **Universal Cross-OS `.apk`/`.bundle`/`.app`/`.ipa` builder**, **`Neon Studio IDE` workbench**, **`neon-lsp`**, **`neon-mcp-server`**, **Google Antigravity Agent Hub**, widget catalog, rendering pipeline, tree diffing, signals state management, routing, storage, and CLI tooling (**431/431 tests passing**).
- **[`neon_framework/neon_studio/`](file:///Users/hamzaalsarsour/Untitled/neon_custom_mobile_framework/NeonFramework-2/neon_framework/neon_studio/)**: The **Neon Studio IDE Workbench** (`http://localhost:9090`), Desktop IDE Packager (`.exe`, `.dmg`, `.deb`), and **Google Antigravity SDK Multi-Agent Orchestrator**.
- **[`neon_framework/examples/`](file:///Users/hamzaalsarsour/Untitled/neon_custom_mobile_framework/NeonFramework-2/neon_framework/examples/)**: Reference showcase screens written in declarative **`NeonLang` (`.neon`)** (`task_studio.neon`, `create_task.neon`, `analytics_screen.neon`, `settings_diagnostics.neon`).
- **[`neon_framework/my_2nd_test_app/`](file:///Users/hamzaalsarsour/Untitled/neon_custom_mobile_framework/NeonFramework-2/neon_framework/my_2nd_test_app/)**: The reference showcase app with native Android (Kotlin) and iOS (Swift) shells.
- **[`neon_framework/sample_flutter_app/`](file:///Users/hamzaalsarsour/Untitled/neon_custom_mobile_framework/NeonFramework-2/neon_framework/sample_flutter_app/)**: A sample app showing transpiled Flutter code running on Neon.
- **[Featured Demo App: Neon Task Studio](https://github.com/hamze-ibraheem/neon_to_do_list_app.git)**: Real-world task management application built with Neon Framework v0.2.0.

## Getting Started

To launch **Neon Studio IDE** (`http://localhost:9090`) or run the reference application:

```bash
cd neon_framework
dart pub get

# Launch Neon Studio IDE Workbench
dart run bin/neon.dart studio

# Compile a .neon file or build Cross-OS mobile packages (.apk, .bundle, .app, .ipa)
dart run bin/neon.dart compile examples/task_studio.neon
dart run bin/neon.dart build -t apk
dart run bin/neon.dart build -t ipa
```

<p align="center">
  🌐 <a href="https://neonframework.dev"><strong>neonframework.dev</strong></a> &nbsp;&bull;&nbsp; 
  📚 <a href="https://docs.neonframework.dev/docs/quick-start"><strong>Official Documentation & Quick Start</strong></a>
</p>

For comprehensive documentation, see the [Root README](../README.md) and [SDK Package README](neon_framework/README.md).


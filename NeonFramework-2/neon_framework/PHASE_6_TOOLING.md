# Neon Framework — Phase 6: Tooling (CLI & Hot Reload)

## Status: Complete

## What Was Built

### CLI Tool (`neon`)
A full command-line interface for Neon Framework development:

| Command | Description |
|---------|-------------|
| `neon create <name>` | Scaffold a new Neon project (app or minimal template) |
| `neon run` | Compile and launch with hot reload active |
| `neon build` | Produce release builds (Android APK / iOS IPA) |
| `neon doctor` | Check development environment setup |
| `neon clean` | Wipe build artifacts and caches |
| `neon --version` | Print CLI version |
| `neon --help` | Show available commands |

### Project Scaffolding
Two project templates:
- **app** — Full starter app with screens directory, StatefulWidget example, counter demo
- **minimal** — Single-file starter with StatelessWidget

Generated files include:
- `pubspec.yaml` with neon_framework dependency
- `neon.yaml` project configuration (platforms, build, hot reload settings)
- `analysis_options.yaml`
- `.gitignore`
- Entry point and widget files

### Hot Reload Engine
Three-tier reload strategy:
1. **UI-only reload** — Re-runs build methods, fastest option
2. **State-preserving reload** (default) — Keeps signal values and widget state intact
3. **Full reload fallback** — Triggered on structural changes (new imports, class hierarchy changes)

Features:
- File watcher with 300ms debounce
- Automatic structural change detection
- Reload history tracking
- Session statistics (uptime, reload count)
- Filters out test files, build artifacts, .dart_tool

### Architecture
```
neon_framework/
  bin/
    neon.dart                         # CLI entry point (executable)
  lib/src/tooling/
    cli.dart                          # NeonCli runner, NeonLogger
    command_create.dart               # neon create implementation
    command_run.dart                  # neon run implementation
    command_build.dart                # neon build implementation
    command_doctor.dart               # neon doctor implementation
    command_clean.dart                # neon clean implementation
    project_template.dart             # NeonProjectTemplate scaffolding
    neon_project.dart                 # NeonProject loader (pubspec + neon.yaml)
    hot_reload.dart                   # HotReloadEngine, HotReloadSession
```

### Dependencies Added
- `args` — Command-line argument parsing
- `path` — Cross-platform path manipulation
- `watcher` — File system change monitoring

## Tests
38 new tests added (169 total passing):
- NeonCli instantiation, version flag, unknown command handling
- NeonLogger output methods
- NeonProjectTemplate: app and minimal generation, file contents, project name injection
- HotReloadMode parsing
- HotReloadEvent creation and tracking
- HotReloadEngine lifecycle (start/stop/mode)
- HotReloadSession statistics
- NeonProject loading and error handling

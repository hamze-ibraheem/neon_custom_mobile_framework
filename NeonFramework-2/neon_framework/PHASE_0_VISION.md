# Neon Framework — Phase 0: Vision & Constraints (LOCKED)

## Framework Identity
- **Mobile-first** (Android & iOS)
- Web (WASM/Canvas) is a future possibility, not a current goal
- VS Code is the primary development environment

## Dart Usage
- **Pure Dart + custom engine**
- No Flutter dependency — Neon owns its runtime
- Dart handles the API surface; a lightweight custom engine handles rendering via platform bridges

## Rendering Strategy
- **Hybrid** (custom layout + native paint)
- Neon defines its own layout system
- Delegates painting to platform canvas (Android Canvas / iOS Core Graphics)
- Custom renderer can be swapped in later

## Design Philosophy
- **Custom hybrid** combining the best of:
  - Flutter: widget tree structure, composition over inheritance
  - Compose: functions as UI building blocks, scoped state
  - SwiftUI: declarative syntax, diffing for efficient updates

## Non-Goals
- No web-first design
- No no-code / visual builder tooling
- No Flutter dependency or compatibility layer
- No desktop support in initial release
- No server-side rendering
- No backward compatibility with Flutter widgets/plugins

## Target Platforms
- Android (via Dart + platform bridge)
- iOS (via Dart + platform bridge)

## SDK Distribution
- Downloadable Dart package (Neon SDK)
- Usable in VS Code as a standard Dart project
- Future: publishable to pub.dev

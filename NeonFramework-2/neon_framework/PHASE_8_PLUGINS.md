# Neon Framework — Phase 8: Plugins & Extensibility

## Status: Complete

## What Was Built

### Plugin Model (`NeonPlugin`)
Dual-mode plugin architecture supporting both Dart-only and native plugins:

- **NeonPlugin**: Abstract base class with `onRegister`/`onDispose` lifecycle hooks
- **NeonDartPlugin**: Simplified base for Dart-only plugins (no native channel needed)
- **NeonNativePlugin**: Base for native plugins that auto-creates a `NeonPlatformChannel` and registers it with the platform dispatcher
- **NeonPluginManifest**: Declares plugin identity (id, name, version), metadata (description, author, homepage, license), SDK constraints, capabilities, dependencies, and type

### Semantic Versioning (`NeonSemanticVersion`)
Full semver implementation:
- Parses `major.minor.patch[-preRelease]` with optional `v` prefix
- Comparison operators (`<`, `>`, `<=`, `>=`, `==`)
- Pre-release ordering (pre-release < release at same version)

### SDK Constraints (`NeonSdkConstraint`)
Version compatibility checking:
- **any**: Accepts all SDK versions
- **exact**: Matches one specific version
- **range**: Min/max with inclusive/exclusive boundaries
- Validated at registration time — incompatible plugins are rejected

### Plugin Registry (`NeonPluginRegistry`)
Singleton registry managing the full plugin lifecycle:
- **Register/Unregister**: With validation for duplicates, SDK compatibility, dependency ordering, and capability conflicts
- **Dependency Resolution**: Plugins can declare dependencies; missing deps are rejected, and dependents prevent unregistration
- **Capability Conflict Detection**: Two plugins cannot declare the same capability
- **Hook System**: Plugins can register named hooks; any code can execute hooks across all registered plugins
- **Lifecycle Management**: Dispose runs in reverse registration order
- **Plugin Context**: Shared data store accessible by all plugins for inter-plugin communication
- **Stats**: Registry statistics (total, dart-only, native, hooks, registration order)

### Example Plugins

**NeonLoggerPlugin** (Dart-only):
- Structured logging with 5 levels (debug, info, warning, error, fatal)
- Configurable minimum log level
- Tag-based filtering and level-based filtering
- Log callback for custom handlers
- Stats reporting and log clearing
- Exposes itself via plugin context as `logger`

**NeonDeviceInfoPlugin** (Native):
- Auto-creates `neon/plugin/neon_device_info` platform channel
- Handles native messages: `updateDeviceInfo`, `updateBattery`
- Can invoke native methods: `getDeviceInfo`, `getBatteryInfo`
- Tracks device model, OS version, app version, battery level, charging state
- Exposes itself via plugin context as `device_info`

### Architecture
```
neon_framework/lib/src/plugins/
  plugin.dart             # NeonPlugin, NeonDartPlugin, NeonNativePlugin, NeonPluginManifest,
                          # NeonSdkConstraint, NeonSemanticVersion, NeonPluginContext
  plugin_registry.dart    # NeonPluginRegistry, NeonPluginHook, NeonPluginException
  example_plugins.dart    # NeonLoggerPlugin, NeonDeviceInfoPlugin
```

## Design Decisions
- **Dual plugin types**: Dart-only for logic/utility plugins, Native for platform access — unified by common base class
- **Capability uniqueness**: Prevents two plugins from providing the same capability (e.g., two loggers)
- **Dependency ordering**: Registration order matters — dependencies must be registered first
- **Reverse disposal**: Plugins are disposed in reverse registration order to respect dependency chains
- **Hook system**: Loose coupling — plugins register hooks, any code can trigger them
- **Plugin context**: Shared mutable data store enables inter-plugin communication without tight coupling
- **Distribution**: Git-based (primary) + manual import; registry deferred to future phase

## Tests
57 new tests added (307 total passing):
- Semantic version parsing, comparison, pre-release ordering
- SDK constraint validation (any, exact, range)
- Plugin manifest fields and JSON serialization
- Plugin context data storage and plugin tracking
- Registry: register, unregister, duplicate rejection, SDK incompatibility, dependency validation, capability conflicts
- Hook registration, execution, and edge cases
- Logger plugin: levels, filtering, callbacks, stats, context access
- Device info plugin: native channel, message handling, lifecycle, context access
- Plugin exception formatting

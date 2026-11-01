import 'package:neon_framework/src/state/signal.dart';

/// Options governing the widget tree diffing and patch update engine.
class DiffingOptions {
  /// Whether widget tree diffing and incremental patch responses are enabled.
  final bool enabled;

  /// Maximum number of patch operations allowed before falling back to full tree.
  final int maxPatchBatchSize;

  /// Whether to automatically fall back to full tree on client revision mismatch.
  final bool enableRecoveryFallback;

  /// Whether native view state (focus, cursor, selection) is preserved during updates.
  final bool preserveNativeFocus;

  /// Protocol version for atomic JSON patch operations.
  final int patchVersion;

  const DiffingOptions({
    this.enabled = true,
    this.maxPatchBatchSize = 150,
    this.enableRecoveryFallback = true,
    this.preserveNativeFocus = true,
    this.patchVersion = 1,
  });

  DiffingOptions copyWith({
    bool? enabled,
    int? maxPatchBatchSize,
    bool? enableRecoveryFallback,
    bool? preserveNativeFocus,
    int? patchVersion,
  }) {
    return DiffingOptions(
      enabled: enabled ?? this.enabled,
      maxPatchBatchSize: maxPatchBatchSize ?? this.maxPatchBatchSize,
      enableRecoveryFallback:
          enableRecoveryFallback ?? this.enableRecoveryFallback,
      preserveNativeFocus: preserveNativeFocus ?? this.preserveNativeFocus,
      patchVersion: patchVersion ?? this.patchVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'maxPatchBatchSize': maxPatchBatchSize,
        'enableRecoveryFallback': enableRecoveryFallback,
        'preserveNativeFocus': preserveNativeFocus,
        'patchVersion': patchVersion,
      };

  factory DiffingOptions.fromJson(Map<String, dynamic> json) {
    return DiffingOptions(
      enabled: json['enabled'] as bool? ?? true,
      maxPatchBatchSize: json['maxPatchBatchSize'] as int? ?? 150,
      enableRecoveryFallback:
          json['enableRecoveryFallback'] as bool? ?? true,
      preserveNativeFocus: json['preserveNativeFocus'] as bool? ?? true,
      patchVersion: json['patchVersion'] as int? ?? 1,
    );
  }

  @override
  String toString() => 'DiffingOptions(${toJson()})';
}

/// Options governing navigation, deep linking, and route resolution.
class NavigationOptions {
  /// Whether navigation events record breadcrumbs in memory for analytics.
  final bool enableTelemetry;

  /// Whether deep link navigation reconstructs synthetic parent backstacks.
  final bool enableSyntheticBackstack;

  /// Whether route matching enforces strict trailing slash compliance.
  final bool strictPathMatching;

  /// Maximum permitted redirect loop depth for route guards.
  final int maxRedirectDepth;

  const NavigationOptions({
    this.enableTelemetry = true,
    this.enableSyntheticBackstack = true,
    this.strictPathMatching = false,
    this.maxRedirectDepth = 5,
  });

  NavigationOptions copyWith({
    bool? enableTelemetry,
    bool? enableSyntheticBackstack,
    bool? strictPathMatching,
    int? maxRedirectDepth,
  }) {
    return NavigationOptions(
      enableTelemetry: enableTelemetry ?? this.enableTelemetry,
      enableSyntheticBackstack:
          enableSyntheticBackstack ?? this.enableSyntheticBackstack,
      strictPathMatching: strictPathMatching ?? this.strictPathMatching,
      maxRedirectDepth: maxRedirectDepth ?? this.maxRedirectDepth,
    );
  }

  Map<String, dynamic> toJson() => {
        'enableTelemetry': enableTelemetry,
        'enableSyntheticBackstack': enableSyntheticBackstack,
        'strictPathMatching': strictPathMatching,
        'maxRedirectDepth': maxRedirectDepth,
      };

  factory NavigationOptions.fromJson(Map<String, dynamic> json) {
    return NavigationOptions(
      enableTelemetry: json['enableTelemetry'] as bool? ?? true,
      enableSyntheticBackstack:
          json['enableSyntheticBackstack'] as bool? ?? true,
      strictPathMatching: json['strictPathMatching'] as bool? ?? false,
      maxRedirectDepth: json['maxRedirectDepth'] as int? ?? 5,
    );
  }

  @override
  String toString() => 'NavigationOptions(${toJson()})';
}

/// Options governing rendering constraints, animation, and frame logging.
class RenderingOptions {
  /// Whether to use physics spring simulations for animated values.
  final bool enableSpringAnimations;

  /// Whether container constraints strictly assert against infinite dimensions.
  final bool strictConstraintValidation;

  /// Whether to print ASCII render frames to stdout on build/rebuild.
  final bool frameRenderLogging;

  const RenderingOptions({
    this.enableSpringAnimations = true,
    this.strictConstraintValidation = true,
    this.frameRenderLogging = true,
  });

  RenderingOptions copyWith({
    bool? enableSpringAnimations,
    bool? strictConstraintValidation,
    bool? frameRenderLogging,
  }) {
    return RenderingOptions(
      enableSpringAnimations:
          enableSpringAnimations ?? this.enableSpringAnimations,
      strictConstraintValidation:
          strictConstraintValidation ?? this.strictConstraintValidation,
      frameRenderLogging: frameRenderLogging ?? this.frameRenderLogging,
    );
  }

  Map<String, dynamic> toJson() => {
        'enableSpringAnimations': enableSpringAnimations,
        'strictConstraintValidation': strictConstraintValidation,
        'frameRenderLogging': frameRenderLogging,
      };

  factory RenderingOptions.fromJson(Map<String, dynamic> json) {
    return RenderingOptions(
      enableSpringAnimations: json['enableSpringAnimations'] as bool? ?? true,
      strictConstraintValidation:
          json['strictConstraintValidation'] as bool? ?? true,
      frameRenderLogging: json['frameRenderLogging'] as bool? ?? true,
    );
  }

  @override
  String toString() => 'RenderingOptions(${toJson()})';
}

/// Options governing networking, cache timeouts, and WebSocket behavior.
class DataOptions {
  /// Default HTTP timeout in milliseconds.
  final int networkTimeoutMs;

  /// Whether WebSockets automatically reconnect when disconnected.
  final bool webSocketAutoReconnect;

  /// Maximum number of cached responses in the local cache store.
  final int maxCacheEntries;

  /// Default cache expiration TTL in seconds.
  final int defaultCacheTtlSeconds;

  const DataOptions({
    this.networkTimeoutMs = 15000,
    this.webSocketAutoReconnect = true,
    this.maxCacheEntries = 200,
    this.defaultCacheTtlSeconds = 300,
  });

  DataOptions copyWith({
    int? networkTimeoutMs,
    bool? webSocketAutoReconnect,
    int? maxCacheEntries,
    int? defaultCacheTtlSeconds,
  }) {
    return DataOptions(
      networkTimeoutMs: networkTimeoutMs ?? this.networkTimeoutMs,
      webSocketAutoReconnect:
          webSocketAutoReconnect ?? this.webSocketAutoReconnect,
      maxCacheEntries: maxCacheEntries ?? this.maxCacheEntries,
      defaultCacheTtlSeconds:
          defaultCacheTtlSeconds ?? this.defaultCacheTtlSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'networkTimeoutMs': networkTimeoutMs,
        'webSocketAutoReconnect': webSocketAutoReconnect,
        'maxCacheEntries': maxCacheEntries,
        'defaultCacheTtlSeconds': defaultCacheTtlSeconds,
      };

  factory DataOptions.fromJson(Map<String, dynamic> json) {
    return DataOptions(
      networkTimeoutMs: json['networkTimeoutMs'] as int? ?? 15000,
      webSocketAutoReconnect: json['webSocketAutoReconnect'] as bool? ?? true,
      maxCacheEntries: json['maxCacheEntries'] as int? ?? 200,
      defaultCacheTtlSeconds: json['defaultCacheTtlSeconds'] as int? ?? 300,
    );
  }

  @override
  String toString() => 'DataOptions(${toJson()})';
}

/// Options governing diagnostics, time-travel snapshots, and developer tooling.
class DiagnosticsOptions {
  /// Whether to serve the live HTML/JS web renderer on GET /.
  final bool enableWebInspector;

  /// Whether to maintain an in-memory history of widget tree snapshots.
  final bool enableTimeTravelSnapshots;

  /// Maximum number of tree snapshots retained in history.
  final int maxSnapshotHistory;

  /// Whether to output detailed logs for each received user action.
  final bool verboseActionLogging;

  const DiagnosticsOptions({
    this.enableWebInspector = true,
    this.enableTimeTravelSnapshots = true,
    this.maxSnapshotHistory = 20,
    this.verboseActionLogging = true,
  });

  DiagnosticsOptions copyWith({
    bool? enableWebInspector,
    bool? enableTimeTravelSnapshots,
    int? maxSnapshotHistory,
    bool? verboseActionLogging,
  }) {
    return DiagnosticsOptions(
      enableWebInspector: enableWebInspector ?? this.enableWebInspector,
      enableTimeTravelSnapshots:
          enableTimeTravelSnapshots ?? this.enableTimeTravelSnapshots,
      maxSnapshotHistory: maxSnapshotHistory ?? this.maxSnapshotHistory,
      verboseActionLogging:
          verboseActionLogging ?? this.verboseActionLogging,
    );
  }

  Map<String, dynamic> toJson() => {
        'enableWebInspector': enableWebInspector,
        'enableTimeTravelSnapshots': enableTimeTravelSnapshots,
        'maxSnapshotHistory': maxSnapshotHistory,
        'verboseActionLogging': verboseActionLogging,
      };

  factory DiagnosticsOptions.fromJson(Map<String, dynamic> json) {
    return DiagnosticsOptions(
      enableWebInspector: json['enableWebInspector'] as bool? ?? true,
      enableTimeTravelSnapshots:
          json['enableTimeTravelSnapshots'] as bool? ?? true,
      maxSnapshotHistory: json['maxSnapshotHistory'] as int? ?? 20,
      verboseActionLogging: json['verboseActionLogging'] as bool? ?? true,
    );
  }

  @override
  String toString() => 'DiagnosticsOptions(${toJson()})';
}

/// Comprehensive, strongly-typed feature configuration for Neon Framework v1.0.0.
class NeonFeatureOptions {
  final DiffingOptions diffing;
  final NavigationOptions navigation;
  final RenderingOptions rendering;
  final DataOptions data;
  final DiagnosticsOptions diagnostics;

  const NeonFeatureOptions({
    this.diffing = const DiffingOptions(),
    this.navigation = const NavigationOptions(),
    this.rendering = const RenderingOptions(),
    this.data = const DataOptions(),
    this.diagnostics = const DiagnosticsOptions(),
  });

  NeonFeatureOptions copyWith({
    DiffingOptions? diffing,
    NavigationOptions? navigation,
    RenderingOptions? rendering,
    DataOptions? data,
    DiagnosticsOptions? diagnostics,
  }) {
    return NeonFeatureOptions(
      diffing: diffing ?? this.diffing,
      navigation: navigation ?? this.navigation,
      rendering: rendering ?? this.rendering,
      data: data ?? this.data,
      diagnostics: diagnostics ?? this.diagnostics,
    );
  }

  Map<String, dynamic> toJson() => {
        'diffing': diffing.toJson(),
        'navigation': navigation.toJson(),
        'rendering': rendering.toJson(),
        'data': data.toJson(),
        'diagnostics': diagnostics.toJson(),
      };

  factory NeonFeatureOptions.fromJson(Map<String, dynamic> json) {
    return NeonFeatureOptions(
      diffing: json['diffing'] is Map<String, dynamic>
          ? DiffingOptions.fromJson(json['diffing'] as Map<String, dynamic>)
          : const DiffingOptions(),
      navigation: json['navigation'] is Map<String, dynamic>
          ? NavigationOptions.fromJson(
              json['navigation'] as Map<String, dynamic>)
          : const NavigationOptions(),
      rendering: json['rendering'] is Map<String, dynamic>
          ? RenderingOptions.fromJson(json['rendering'] as Map<String, dynamic>)
          : const RenderingOptions(),
      data: json['data'] is Map<String, dynamic>
          ? DataOptions.fromJson(json['data'] as Map<String, dynamic>)
          : const DataOptions(),
      diagnostics: json['diagnostics'] is Map<String, dynamic>
          ? DiagnosticsOptions.fromJson(
              json['diagnostics'] as Map<String, dynamic>)
          : const DiagnosticsOptions(),
    );
  }

  @override
  String toString() => 'NeonFeatureOptions(${toJson()})';
}

/// Reactive manager for runtime observation and dynamic modification of feature options.
class NeonFeatureOptionsManager {
  final NeonSignal<NeonFeatureOptions> _optionsSignal;
  final List<void Function(NeonFeatureOptions)> _listeners = [];

  NeonFeatureOptionsManager([NeonFeatureOptions initial = const NeonFeatureOptions()])
      : _optionsSignal = NeonSignal<NeonFeatureOptions>(initial);

  /// Current feature options.
  NeonFeatureOptions get current => _optionsSignal.value;

  /// Reactive signal wrapping feature options.
  NeonSignal<NeonFeatureOptions> get signal => _optionsSignal;

  /// Registers a change listener notified whenever feature options are updated.
  void addListener(void Function(NeonFeatureOptions) listener) {
    _listeners.add(listener);
  }

  /// Removes a registered change listener.
  void removeListener(void Function(NeonFeatureOptions) listener) {
    _listeners.remove(listener);
  }

  /// Updates current feature options and notifies observers.
  void update(NeonFeatureOptions newOptions) {
    _optionsSignal.value = newOptions;
    for (final listener in List.of(_listeners)) {
      listener(newOptions);
    }
  }

  /// Mutates current options using a transformation callback.
  void mutate(NeonFeatureOptions Function(NeonFeatureOptions current) mutator) {
    update(mutator(current));
  }

  /// Updates options from a JSON map (e.g. from an HTTP API or config file).
  void updateFromJson(Map<String, dynamic> json) {
    final merged = NeonFeatureOptions.fromJson({
      ...current.toJson(),
      ...json,
    });
    update(merged);
  }
}


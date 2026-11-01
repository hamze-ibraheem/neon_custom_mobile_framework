import 'feature_options.dart';

/// Represents the deployment environment for the Neon application.
enum NeonEnvironment {
  development,
  staging,
  production,
}

/// Defines a build flavor with a name and associated configuration.
class NeonBuildFlavor {
  /// The name of this build flavor.
  final String name;

  /// Key-value configuration associated with this flavor.
  final Map<String, dynamic> config;

  /// Creates a build flavor with the given [name] and optional [config].
  const NeonBuildFlavor({
    required this.name,
    this.config = const {},
  });

  /// Returns the config value for the given [key].
  dynamic operator [](String key) => config[key];

  @override
  String toString() => 'NeonBuildFlavor($name)';
}

/// A set of named boolean feature flags.
class NeonFeatureFlags {
  final Map<String, bool> _flags;

  /// Creates feature flags from an optional map of flag names to values.
  const NeonFeatureFlags([this._flags = const {}]);

  /// Returns whether the given [flag] is enabled, defaulting to false.
  bool isEnabled(String flag) => _flags[flag] ?? false;

  /// Returns a copy with the given [overrides] applied.
  NeonFeatureFlags copyWith(Map<String, bool> overrides) {
    return NeonFeatureFlags({..._flags, ...overrides});
  }

  /// Iterates over all flag entries.
  void forEach(void Function(String key, bool value) fn) {
    _flags.forEach(fn);
  }

  @override
  String toString() => 'NeonFeatureFlags($_flags)';
}

/// Configuration for a Neon application including environment, flavor, and flags.
class NeonConfig {
  /// The target environment for this configuration.
  final NeonEnvironment environment;

  /// An optional build flavor for this configuration.
  final NeonBuildFlavor? buildFlavor;

  /// Feature flags for this configuration.
  final NeonFeatureFlags featureFlags;

  /// Subsystem feature options for Neon Framework v1.0.0.
  final NeonFeatureOptions featureOptions;

  /// The port for the UI server.
  final int port;

  /// Whether widget tree diffing and incremental patch responses are enabled.
  final bool enableDiffing;

  /// Custom key-value configuration data.
  final Map<String, dynamic> custom;

  /// Creates a Neon configuration with the given parameters.
  const NeonConfig({
    this.environment = NeonEnvironment.development,
    this.buildFlavor,
    this.featureFlags = const NeonFeatureFlags(),
    this.featureOptions = const NeonFeatureOptions(),
    this.port = 8080,
    this.enableDiffing = true,
    this.custom = const {},
  });

  /// Whether the environment is development.
  bool get isDev => environment == NeonEnvironment.development;

  /// Whether the environment is staging.
  bool get isStaging => environment == NeonEnvironment.staging;

  /// Whether the environment is production.
  bool get isProd => environment == NeonEnvironment.production;

  /// Returns a copy of this config with the given fields replaced.
  NeonConfig copyWith({
    NeonEnvironment? environment,
    NeonBuildFlavor? buildFlavor,
    NeonFeatureFlags? featureFlags,
    NeonFeatureOptions? featureOptions,
    int? port,
    bool? enableDiffing,
    Map<String, dynamic>? custom,
  }) {
    return NeonConfig(
      environment: environment ?? this.environment,
      buildFlavor: buildFlavor ?? this.buildFlavor,
      featureFlags: featureFlags ?? this.featureFlags,
      featureOptions: featureOptions ?? this.featureOptions,
      port: port ?? this.port,
      enableDiffing: enableDiffing ?? this.enableDiffing,
      custom: custom ?? this.custom,
    );
  }

  @override
  String toString() =>
      'NeonConfig(env: $environment, flavor: $buildFlavor, flags: $featureFlags, options: $featureOptions, diffing: $enableDiffing)';
}

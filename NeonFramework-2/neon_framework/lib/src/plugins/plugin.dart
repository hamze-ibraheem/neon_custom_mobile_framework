import 'package:neon_framework/src/platform/platform_channel.dart';

class NeonPluginManifest {
  final String id;
  final String name;
  final String version;
  final String? description;
  final String? author;
  final String? homepage;
  final String? license;
  final NeonSdkConstraint sdkConstraint;
  final Set<String> capabilities;
  final List<String> dependencies;
  final NeonPluginType type;

  const NeonPluginManifest({
    required this.id,
    required this.name,
    required this.version,
    this.description,
    this.author,
    this.homepage,
    this.license,
    this.sdkConstraint = const NeonSdkConstraint.any(),
    this.capabilities = const {},
    this.dependencies = const [],
    this.type = NeonPluginType.dartOnly,
  });

  bool get isNativePlugin => type == NeonPluginType.native;
  bool get isDartOnlyPlugin => type == NeonPluginType.dartOnly;

  NeonSemanticVersion get parsedVersion => NeonSemanticVersion.parse(version);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        if (description != null) 'description': description,
        if (author != null) 'author': author,
        if (homepage != null) 'homepage': homepage,
        if (license != null) 'license': license,
        'sdk_constraint': sdkConstraint.toString(),
        'capabilities': capabilities.toList(),
        'dependencies': dependencies,
        'type': type.name,
      };

  @override
  String toString() => 'NeonPluginManifest($id@$version, ${type.name})';
}

enum NeonPluginType { dartOnly, native }

class NeonSdkConstraint {
  final String? minVersion;
  final String? maxVersion;
  final bool minInclusive;
  final bool maxInclusive;

  const NeonSdkConstraint({
    this.minVersion,
    this.maxVersion,
    this.minInclusive = true,
    this.maxInclusive = false,
  });

  const NeonSdkConstraint.any()
      : minVersion = null,
        maxVersion = null,
        minInclusive = true,
        maxInclusive = false;

  const NeonSdkConstraint.exact(String version)
      : minVersion = version,
        maxVersion = version,
        minInclusive = true,
        maxInclusive = true;

  bool isSatisfiedBy(String sdkVersion) {
    final sdk = NeonSemanticVersion.parse(sdkVersion);

    if (minVersion != null) {
      final min = NeonSemanticVersion.parse(minVersion!);
      final cmp = sdk.compareTo(min);
      if (minInclusive && cmp < 0) return false;
      if (!minInclusive && cmp <= 0) return false;
    }

    if (maxVersion != null) {
      final max = NeonSemanticVersion.parse(maxVersion!);
      final cmp = sdk.compareTo(max);
      if (maxInclusive && cmp > 0) return false;
      if (!maxInclusive && cmp >= 0) return false;
    }

    return true;
  }

  @override
  String toString() {
    if (minVersion == null && maxVersion == null) return 'any';
    if (minVersion != null && maxVersion != null && minVersion == maxVersion) {
      return '=$minVersion';
    }
    final parts = <String>[];
    if (minVersion != null) {
      parts.add('${minInclusive ? ">=" : ">"}$minVersion');
    }
    if (maxVersion != null) {
      parts.add('${maxInclusive ? "<=" : "<"}$maxVersion');
    }
    return parts.join(' ');
  }
}

class NeonSemanticVersion implements Comparable<NeonSemanticVersion> {
  final int major;
  final int minor;
  final int patch;
  final String? preRelease;

  const NeonSemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease,
  });

  factory NeonSemanticVersion.parse(String version) {
    final cleaned = version.replaceFirst(RegExp(r'^v'), '');
    String? pre;
    var core = cleaned;
    final dashIndex = cleaned.indexOf('-');
    if (dashIndex != -1) {
      pre = cleaned.substring(dashIndex + 1);
      core = cleaned.substring(0, dashIndex);
    }
    final parts = core.split('.');
    return NeonSemanticVersion(
      major: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0,
      minor: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      patch: parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
      preRelease: pre,
    );
  }

  @override
  int compareTo(NeonSemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    if (preRelease == null && other.preRelease != null) return 1;
    if (preRelease != null && other.preRelease == null) return -1;
    if (preRelease != null && other.preRelease != null) {
      return preRelease!.compareTo(other.preRelease!);
    }
    return 0;
  }

  bool operator >=(NeonSemanticVersion other) => compareTo(other) >= 0;
  bool operator <=(NeonSemanticVersion other) => compareTo(other) <= 0;
  bool operator >(NeonSemanticVersion other) => compareTo(other) > 0;
  bool operator <(NeonSemanticVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is NeonSemanticVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch &&
      preRelease == other.preRelease;

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease);

  @override
  String toString() {
    final base = '$major.$minor.$patch';
    return preRelease != null ? '$base-$preRelease' : base;
  }
}

abstract class NeonPlugin {
  NeonPluginManifest get manifest;

  bool registeredInternal = false;
  bool get isRegistered => registeredInternal;

  void onRegister(NeonPluginContext context);
  void onDispose();

  NeonPlatformChannel? get nativeChannel => null;

  void registerNativeHandlers(NeonPlatformChannel channel) {}

  @override
  String toString() => 'NeonPlugin(${manifest.id}@${manifest.version})';
}

abstract class NeonDartPlugin extends NeonPlugin {}

abstract class NeonNativePlugin extends NeonPlugin {
  late NeonPlatformChannel _channel;

  @override
  NeonPlatformChannel get nativeChannel => _channel;

  String get channelName => 'neon/plugin/${manifest.id}';

  @override
  void onRegister(NeonPluginContext context) {
    _channel = NeonPlatformChannel(name: channelName);
    NeonPlatformDispatcher.instance.registerChannel(_channel);
    registerNativeHandlers(_channel);
    onNativeRegister(context, _channel);
  }

  void onNativeRegister(NeonPluginContext context, NeonPlatformChannel channel);

  @override
  void onDispose() {
    _channel.close();
    NeonPlatformDispatcher.instance.unregisterChannel(channelName);
    onNativeDispose();
  }

  void onNativeDispose() {}
}

class NeonPluginContext {
  final String sdkVersion;
  final Map<String, dynamic> _sharedData = {};
  final List<String> _registeredPluginIds = [];

  NeonPluginContext({required this.sdkVersion});

  T? get<T>(String key) => _sharedData[key] as T?;
  void set<T>(String key, T value) => _sharedData[key] = value;
  bool has(String key) => _sharedData.containsKey(key);
  void remove(String key) => _sharedData.remove(key);

  List<String> get registeredPluginIds =>
      List.unmodifiable(_registeredPluginIds);

  bool isPluginRegistered(String pluginId) =>
      _registeredPluginIds.contains(pluginId);

  void trackRegistration(String pluginId) {
    _registeredPluginIds.add(pluginId);
  }

  void trackUnregistration(String pluginId) {
    _registeredPluginIds.remove(pluginId);
  }
}

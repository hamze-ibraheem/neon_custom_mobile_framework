import 'package:neon_framework/src/plugins/plugin.dart';

class NeonPluginRegistry {
  static NeonPluginRegistry? _instance;
  static NeonPluginRegistry get instance {
    _instance ??= NeonPluginRegistry._();
    return _instance!;
  }

  NeonPluginRegistry._();

  final Map<String, NeonPlugin> _plugins = {};
  final Map<String, List<NeonPluginHook>> _hooks = {};
  final List<String> _registrationOrder = [];
  late NeonPluginContext _context;
  bool _initialized = false;
  String _sdkVersion = '0.8.0';

  bool get isInitialized => _initialized;
  String get sdkVersion => _sdkVersion;
  int get pluginCount => _plugins.length;
  List<String> get pluginIds => List.unmodifiable(_registrationOrder);

  NeonPluginContext get context {
    _ensureInit();
    return _context;
  }

  void initialize({String sdkVersion = '0.8.0'}) {
    if (_initialized) return;
    _sdkVersion = sdkVersion;
    _context = NeonPluginContext(sdkVersion: sdkVersion);
    _initialized = true;
  }

  void register(NeonPlugin plugin) {
    _ensureInit();

    final id = plugin.manifest.id;

    if (_plugins.containsKey(id)) {
      throw NeonPluginException(
        'Plugin "$id" is already registered.',
        pluginId: id,
        code: NeonPluginErrorCode.alreadyRegistered,
      );
    }

    if (!plugin.manifest.sdkConstraint.isSatisfiedBy(_sdkVersion)) {
      throw NeonPluginException(
        'Plugin "$id" requires SDK ${plugin.manifest.sdkConstraint}, '
        'but current SDK is $_sdkVersion.',
        pluginId: id,
        code: NeonPluginErrorCode.sdkIncompatible,
      );
    }

    for (final dep in plugin.manifest.dependencies) {
      if (!_plugins.containsKey(dep)) {
        throw NeonPluginException(
          'Plugin "$id" depends on "$dep", which is not registered. '
          'Register "$dep" first.',
          pluginId: id,
          code: NeonPluginErrorCode.missingDependency,
        );
      }
    }

    for (final cap in plugin.manifest.capabilities) {
      final conflict = _findCapabilityConflict(cap, id);
      if (conflict != null) {
        throw NeonPluginException(
          'Plugin "$id" declares capability "$cap" which conflicts with '
          'plugin "$conflict".',
          pluginId: id,
          code: NeonPluginErrorCode.capabilityConflict,
        );
      }
    }

    plugin.onRegister(_context);
    plugin.registeredInternal = true;
    _plugins[id] = plugin;
    _registrationOrder.add(id);
    _context.trackRegistration(id);
  }

  void unregister(String pluginId) {
    _ensureInit();

    final plugin = _plugins[pluginId];
    if (plugin == null) {
      throw NeonPluginException(
        'Plugin "$pluginId" is not registered.',
        pluginId: pluginId,
        code: NeonPluginErrorCode.notRegistered,
      );
    }

    final dependents = _findDependents(pluginId);
    if (dependents.isNotEmpty) {
      throw NeonPluginException(
        'Cannot unregister "$pluginId" because these plugins depend on it: '
        '${dependents.join(", ")}. Unregister them first.',
        pluginId: pluginId,
        code: NeonPluginErrorCode.hasDependents,
      );
    }

    _hooks.remove(pluginId);
    plugin.onDispose();
    plugin.registeredInternal = false;
    _plugins.remove(pluginId);
    _registrationOrder.remove(pluginId);
    _context.trackUnregistration(pluginId);
  }

  T? getPlugin<T extends NeonPlugin>(String pluginId) {
    return _plugins[pluginId] as T?;
  }

  bool hasPlugin(String pluginId) => _plugins.containsKey(pluginId);

  NeonPlugin? operator [](String pluginId) => _plugins[pluginId];

  List<NeonPlugin> getPluginsWithCapability(String capability) {
    return _plugins.values
        .where((p) => p.manifest.capabilities.contains(capability))
        .toList();
  }

  void registerHook(String pluginId, String hookName, NeonPluginHookCallback callback) {
    _ensureInit();
    if (!_plugins.containsKey(pluginId)) {
      throw NeonPluginException(
        'Plugin "$pluginId" is not registered.',
        pluginId: pluginId,
        code: NeonPluginErrorCode.notRegistered,
      );
    }

    final hook = NeonPluginHook(
      pluginId: pluginId,
      name: hookName,
      callback: callback,
    );

    _hooks.putIfAbsent(hookName, () => []).add(hook);
  }

  Future<List<dynamic>> executeHook(String hookName, [dynamic argument]) async {
    final hooks = _hooks[hookName];
    if (hooks == null || hooks.isEmpty) return [];

    final results = <dynamic>[];
    for (final hook in hooks) {
      results.add(await hook.callback(argument));
    }
    return results;
  }

  List<NeonPluginHook> getHooks(String hookName) {
    return List.unmodifiable(_hooks[hookName] ?? []);
  }

  Map<String, dynamic> getRegistryStats() {
    final dartOnly = _plugins.values
        .where((p) => p.manifest.type == NeonPluginType.dartOnly)
        .length;
    final native = _plugins.values
        .where((p) => p.manifest.type == NeonPluginType.native)
        .length;

    return {
      'total_plugins': _plugins.length,
      'dart_only': dartOnly,
      'native': native,
      'sdk_version': _sdkVersion,
      'hooks': _hooks.keys.toList(),
      'registration_order': List.from(_registrationOrder),
    };
  }

  String? _findCapabilityConflict(String capability, String excludeId) {
    for (final entry in _plugins.entries) {
      if (entry.key == excludeId) continue;
      if (entry.value.manifest.capabilities.contains(capability)) {
        return entry.key;
      }
    }
    return null;
  }

  List<String> _findDependents(String pluginId) {
    return _plugins.entries
        .where((e) => e.value.manifest.dependencies.contains(pluginId))
        .map((e) => e.key)
        .toList();
  }

  void dispose() {
    for (final id in _registrationOrder.reversed) {
      final plugin = _plugins[id];
      if (plugin != null) {
        plugin.onDispose();
        plugin.registeredInternal = false;
      }
    }
    _plugins.clear();
    _hooks.clear();
    _registrationOrder.clear();
    _initialized = false;
  }

  static void reset() {
    _instance?.dispose();
    _instance = null;
  }

  void _ensureInit() {
    if (!_initialized) {
      throw StateError(
        'NeonPluginRegistry has not been initialized. Call initialize() first.',
      );
    }
  }
}

typedef NeonPluginHookCallback = Future<dynamic> Function(dynamic argument);

class NeonPluginHook {
  final String pluginId;
  final String name;
  final NeonPluginHookCallback callback;

  const NeonPluginHook({
    required this.pluginId,
    required this.name,
    required this.callback,
  });

  @override
  String toString() => 'NeonPluginHook($pluginId:$name)';
}

enum NeonPluginErrorCode {
  alreadyRegistered,
  notRegistered,
  sdkIncompatible,
  missingDependency,
  capabilityConflict,
  hasDependents,
  hookError,
}

class NeonPluginException implements Exception {
  final String message;
  final String? pluginId;
  final NeonPluginErrorCode code;

  const NeonPluginException(
    this.message, {
    this.pluginId,
    required this.code,
  });

  @override
  String toString() => 'NeonPluginException($code): $message';
}

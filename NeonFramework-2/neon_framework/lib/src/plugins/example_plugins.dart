import 'dart:async';
import 'package:neon_framework/src/plugins/plugin.dart';
import 'package:neon_framework/src/platform/platform_channel.dart';

class NeonLoggerPlugin extends NeonDartPlugin {
  final List<NeonLogEntry> _entries = [];
  NeonLogLevel _minLevel;
  void Function(NeonLogEntry)? _onLog;

  NeonLoggerPlugin({
    NeonLogLevel minLevel = NeonLogLevel.debug,
    void Function(NeonLogEntry)? onLog,
  })  : _minLevel = minLevel,
        _onLog = onLog;

  @override
  NeonPluginManifest get manifest => const NeonPluginManifest(
        id: 'neon_logger',
        name: 'Neon Logger',
        version: '1.0.0',
        description: 'Structured logging plugin for Neon apps',
        author: 'Neon Team',
        capabilities: {'logging'},
        type: NeonPluginType.dartOnly,
      );

  List<NeonLogEntry> get entries => List.unmodifiable(_entries);
  NeonLogLevel get minLevel => _minLevel;

  set minLevel(NeonLogLevel level) => _minLevel = level;

  @override
  void onRegister(NeonPluginContext context) {
    context.set<NeonLoggerPlugin>('logger', this);
    log(NeonLogLevel.info, 'NeonLoggerPlugin registered');
  }

  @override
  void onDispose() {
    log(NeonLogLevel.info, 'NeonLoggerPlugin disposing');
    _entries.clear();
    _onLog = null;
  }

  void log(NeonLogLevel level, String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (level.index < _minLevel.index) return;

    final entry = NeonLogEntry(
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );

    _entries.add(entry);
    _onLog?.call(entry);
  }

  void debug(String message, {String? tag}) =>
      log(NeonLogLevel.debug, message, tag: tag);

  void info(String message, {String? tag}) =>
      log(NeonLogLevel.info, message, tag: tag);

  void warning(String message, {String? tag}) =>
      log(NeonLogLevel.warning, message, tag: tag);

  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) =>
      log(NeonLogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);

  void fatal(String message, {String? tag, Object? error, StackTrace? stackTrace}) =>
      log(NeonLogLevel.fatal, message, tag: tag, error: error, stackTrace: stackTrace);

  List<NeonLogEntry> getByLevel(NeonLogLevel level) =>
      _entries.where((e) => e.level == level).toList();

  List<NeonLogEntry> getByTag(String tag) =>
      _entries.where((e) => e.tag == tag).toList();

  void clear() => _entries.clear();

  Map<String, dynamic> get stats => {
        'total': _entries.length,
        'debug': getByLevel(NeonLogLevel.debug).length,
        'info': getByLevel(NeonLogLevel.info).length,
        'warning': getByLevel(NeonLogLevel.warning).length,
        'error': getByLevel(NeonLogLevel.error).length,
        'fatal': getByLevel(NeonLogLevel.fatal).length,
      };
}

enum NeonLogLevel { debug, info, warning, error, fatal }

class NeonLogEntry {
  final NeonLogLevel level;
  final String message;
  final String? tag;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  const NeonLogEntry({
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    required this.timestamp,
  });

  @override
  String toString() {
    final prefix = '[${level.name.toUpperCase()}]';
    final tagStr = tag != null ? '[$tag] ' : '';
    return '$prefix $tagStr$message';
  }
}

class NeonDeviceInfoPlugin extends NeonNativePlugin {
  String _deviceModel = 'Unknown';
  String _osVersion = 'Unknown';
  String _appVersion = '0.0.0';
  double _batteryLevel = -1;
  bool _isCharging = false;
  final Map<String, dynamic> _extraInfo = {};

  String get deviceModel => _deviceModel;
  String get osVersion => _osVersion;
  String get appVersion => _appVersion;
  double get batteryLevel => _batteryLevel;
  bool get isCharging => _isCharging;
  Map<String, dynamic> get extraInfo => Map.unmodifiable(_extraInfo);

  @override
  NeonPluginManifest get manifest => const NeonPluginManifest(
        id: 'neon_device_info',
        name: 'Neon Device Info',
        version: '1.0.0',
        description: 'Native device information plugin',
        author: 'Neon Team',
        capabilities: {'device_info'},
        type: NeonPluginType.native,
      );

  @override
  void onNativeRegister(NeonPluginContext context, NeonPlatformChannel channel) {
    context.set<NeonDeviceInfoPlugin>('device_info', this);
  }

  @override
  void registerNativeHandlers(NeonPlatformChannel channel) {
    channel.setMessageHandler((method, arguments) async {
      switch (method) {
        case 'updateDeviceInfo':
          final data = arguments as Map<String, dynamic>?;
          if (data != null) {
            _deviceModel = data['model'] as String? ?? _deviceModel;
            _osVersion = data['os_version'] as String? ?? _osVersion;
            _appVersion = data['app_version'] as String? ?? _appVersion;
          }
          return true;
        case 'updateBattery':
          final data = arguments as Map<String, dynamic>?;
          if (data != null) {
            _batteryLevel = (data['level'] as num?)?.toDouble() ?? _batteryLevel;
            _isCharging = data['charging'] as bool? ?? _isCharging;
          }
          return true;
        default:
          return null;
      }
    });
  }

  Future<Map<String, dynamic>?> fetchDeviceInfo() async {
    final result = await nativeChannel.invokeMethod<Map<String, dynamic>>('getDeviceInfo');
    if (result != null) {
      _deviceModel = result['model'] as String? ?? _deviceModel;
      _osVersion = result['os_version'] as String? ?? _osVersion;
      _appVersion = result['app_version'] as String? ?? _appVersion;
      _extraInfo.addAll(result);
    }
    return result;
  }

  Future<Map<String, dynamic>?> fetchBatteryInfo() async {
    final result = await nativeChannel.invokeMethod<Map<String, dynamic>>('getBatteryInfo');
    if (result != null) {
      _batteryLevel = (result['level'] as num?)?.toDouble() ?? _batteryLevel;
      _isCharging = result['charging'] as bool? ?? _isCharging;
    }
    return result;
  }

  @override
  void onNativeDispose() {
    _extraInfo.clear();
  }

  Map<String, dynamic> toJson() => {
        'device_model': _deviceModel,
        'os_version': _osVersion,
        'app_version': _appVersion,
        'battery_level': _batteryLevel,
        'is_charging': _isCharging,
        'extra': _extraInfo,
      };

  @override
  String toString() =>
      'NeonDeviceInfoPlugin(model: $_deviceModel, os: $_osVersion)';
}

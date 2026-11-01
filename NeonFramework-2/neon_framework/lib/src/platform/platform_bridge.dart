import 'package:neon_framework/src/platform/platform_channel.dart';
import 'package:neon_framework/src/platform/platform_info.dart';
import 'package:neon_framework/src/platform/native_renderer.dart';
import 'package:neon_framework/src/platform/file_system.dart';
import 'package:neon_framework/src/platform/platform_lifecycle.dart';

enum NeonTargetPlatform { android, ios }

class NeonPlatformBridge {
  static NeonPlatformBridge? _instance;
  static NeonPlatformBridge get instance {
    _instance ??= NeonPlatformBridge._();
    return _instance!;
  }

  NeonPlatformBridge._();

  NeonTargetPlatform? _platform;
  bool _initialized = false;

  late final NeonPlatformChannel _systemChannel;
  late final NeonPlatformChannel _renderChannel;
  late final NeonPlatformChannel _lifecycleChannel;
  late final NeonPlatformChannel _fileChannel;

  late final NeonPlatformInfo _platformInfo;
  late final NeonNativeRenderer _nativeRenderer;
  late final NeonFileSystem _fileSystem;
  late final NeonPlatformLifecycle _platformLifecycle;

  bool get isInitialized => _initialized;
  NeonTargetPlatform? get platform => _platform;

  NeonPlatformInfo get platformInfo {
    _ensureInit();
    return _platformInfo;
  }

  NeonNativeRenderer get nativeRenderer {
    _ensureInit();
    return _nativeRenderer;
  }

  NeonFileSystem get fileSystem {
    _ensureInit();
    return _fileSystem;
  }

  NeonPlatformLifecycle get platformLifecycle {
    _ensureInit();
    return _platformLifecycle;
  }

  NeonPlatformChannel get systemChannel {
    _ensureInit();
    return _systemChannel;
  }

  NeonPlatformChannel get renderChannel {
    _ensureInit();
    return _renderChannel;
  }

  void initialize({NeonTargetPlatform? platform}) {
    if (_initialized) return;

    _platform = platform;

    _systemChannel = NeonPlatformChannel(name: 'neon/system');
    _renderChannel = NeonPlatformChannel(name: 'neon/render', codec: NeonChannelCodec.binary);
    _lifecycleChannel = NeonPlatformChannel(name: 'neon/lifecycle');
    _fileChannel = NeonPlatformChannel(name: 'neon/file');

    final dispatcher = NeonPlatformDispatcher.instance;
    dispatcher.registerChannel(_systemChannel);
    dispatcher.registerChannel(_renderChannel);
    dispatcher.registerChannel(_lifecycleChannel);
    dispatcher.registerChannel(_fileChannel);

    _platformInfo = NeonPlatformInfo(channel: _systemChannel, platform: _platform);
    _nativeRenderer = NeonNativeRenderer(channel: _renderChannel);
    _fileSystem = NeonFileSystem(channel: _fileChannel);
    _platformLifecycle = NeonPlatformLifecycle(channel: _lifecycleChannel);

    _initialized = true;
  }

  void _ensureInit() {
    if (!_initialized) {
      throw StateError('NeonPlatformBridge has not been initialized. Call initialize() first.');
    }
  }

  void dispose() {
    if (!_initialized) return;
    _platformLifecycle.dispose();
    _nativeRenderer.dispose();
    _systemChannel.close();
    _renderChannel.close();
    _lifecycleChannel.close();
    _fileChannel.close();
    NeonPlatformDispatcher.instance.dispose();
    _initialized = false;
  }

  static void reset() {
    _instance?.dispose();
    _instance = null;
    NeonPlatformDispatcher.reset();
  }
}

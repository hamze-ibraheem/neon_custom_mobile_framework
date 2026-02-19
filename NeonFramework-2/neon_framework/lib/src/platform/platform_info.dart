import 'dart:async';
import 'package:neon_framework/src/platform/platform_channel.dart';
import 'package:neon_framework/src/platform/platform_bridge.dart';
import 'package:neon_framework/src/rendering/constraints.dart';

class NeonPlatformInfo {
  final NeonPlatformChannel channel;
  final NeonTargetPlatform? platform;

  String _osVersion = 'unknown';
  String _deviceModel = 'unknown';
  double _devicePixelRatio = 1.0;
  NeonSize _screenSize = const NeonSize(360, 800);
  NeonEdgeInsetsData _safeArea = const NeonEdgeInsetsData();
  String _locale = 'en_US';
  bool _isDarkMode = false;
  bool _isLoaded = false;

  NeonPlatformInfo({
    required this.channel,
    this.platform,
  });

  bool get isLoaded => _isLoaded;
  String get osVersion => _osVersion;
  String get deviceModel => _deviceModel;
  double get devicePixelRatio => _devicePixelRatio;
  NeonSize get screenSize => _screenSize;
  NeonEdgeInsetsData get safeArea => _safeArea;
  String get locale => _locale;
  bool get isDarkMode => _isDarkMode;

  bool get isAndroid => platform == NeonTargetPlatform.android;
  bool get isIOS => platform == NeonTargetPlatform.ios;

  String get platformName {
    switch (platform) {
      case NeonTargetPlatform.android:
        return 'Android';
      case NeonTargetPlatform.ios:
        return 'iOS';
      case null:
        return 'Unknown';
    }
  }

  Future<void> load() async {
    final result = await channel.invokeMethod<Map>('system.getDeviceInfo');
    if (result != null) {
      _osVersion = result['osVersion'] as String? ?? _osVersion;
      _deviceModel = result['deviceModel'] as String? ?? _deviceModel;
      _devicePixelRatio = (result['devicePixelRatio'] as num?)?.toDouble() ?? _devicePixelRatio;
      _screenSize = NeonSize(
        (result['screenWidth'] as num?)?.toDouble() ?? _screenSize.width,
        (result['screenHeight'] as num?)?.toDouble() ?? _screenSize.height,
      );
      _locale = result['locale'] as String? ?? _locale;
      _isDarkMode = result['isDarkMode'] as bool? ?? _isDarkMode;

      final safeAreaMap = result['safeArea'] as Map?;
      if (safeAreaMap != null) {
        _safeArea = NeonEdgeInsetsData(
          top: (safeAreaMap['top'] as num?)?.toDouble() ?? 0,
          right: (safeAreaMap['right'] as num?)?.toDouble() ?? 0,
          bottom: (safeAreaMap['bottom'] as num?)?.toDouble() ?? 0,
          left: (safeAreaMap['left'] as num?)?.toDouble() ?? 0,
        );
      }
    }
    _isLoaded = true;
  }

  void setMockValues({
    String? osVersion,
    String? deviceModel,
    double? devicePixelRatio,
    NeonSize? screenSize,
    NeonEdgeInsetsData? safeArea,
    String? locale,
    bool? isDarkMode,
  }) {
    _osVersion = osVersion ?? _osVersion;
    _deviceModel = deviceModel ?? _deviceModel;
    _devicePixelRatio = devicePixelRatio ?? _devicePixelRatio;
    _screenSize = screenSize ?? _screenSize;
    _safeArea = safeArea ?? _safeArea;
    _locale = locale ?? _locale;
    _isDarkMode = isDarkMode ?? _isDarkMode;
    _isLoaded = true;
  }

  @override
  String toString() =>
      'NeonPlatformInfo($platformName, $deviceModel, $_osVersion, dpr: $_devicePixelRatio)';
}

class NeonEdgeInsetsData {
  final double top;
  final double right;
  final double bottom;
  final double left;

  const NeonEdgeInsetsData({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });

  double get horizontal => left + right;
  double get vertical => top + bottom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeonEdgeInsetsData &&
          top == other.top &&
          right == other.right &&
          bottom == other.bottom &&
          left == other.left;

  @override
  int get hashCode => Object.hash(top, right, bottom, left);

  @override
  String toString() =>
      'NeonEdgeInsetsData(top: $top, right: $right, bottom: $bottom, left: $left)';
}

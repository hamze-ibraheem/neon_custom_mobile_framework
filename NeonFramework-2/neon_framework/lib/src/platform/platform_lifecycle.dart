import 'dart:async';
import 'package:neon_framework/src/platform/platform_channel.dart';
import 'package:neon_framework/src/core/lifecycle.dart';

enum NeonNativeLifecycleEvent {
  onCreate,
  onStart,
  onResume,
  onPause,
  onStop,
  onDestroy,
  onLowMemory,
  onTrimMemory,
  willEnterForeground,
  didEnterBackground,
  willResignActive,
  didBecomeActive,
  willTerminate,
}

class NeonPlatformLifecycle {
  final NeonPlatformChannel channel;
  NeonLifecycleManager? _lifecycleManager;
  final StreamController<NeonNativeLifecycleEvent> _eventController =
      StreamController<NeonNativeLifecycleEvent>.broadcast();
  final List<NeonNativeLifecycleEvent> _eventLog = [];

  NeonPlatformLifecycle({required this.channel}) {
    channel.setMessageHandler(_handleLifecycleMessage);
  }

  Stream<NeonNativeLifecycleEvent> get events => _eventController.stream;
  List<NeonNativeLifecycleEvent> get eventLog => List.unmodifiable(_eventLog);

  void bindLifecycleManager(NeonLifecycleManager manager) {
    _lifecycleManager = manager;
  }

  Future<dynamic> _handleLifecycleMessage(String method, dynamic arguments) async {
    if (method == 'lifecycle.event') {
      final eventName = arguments as String?;
      if (eventName != null) {
        final event = _parseEvent(eventName);
        if (event != null) {
          _onNativeEvent(event);
        }
      }
    }
    return null;
  }

  void _onNativeEvent(NeonNativeLifecycleEvent event) {
    _eventLog.add(event);
    _eventController.add(event);
    _bridgeToNeonLifecycle(event);
  }

  void _bridgeToNeonLifecycle(NeonNativeLifecycleEvent event) {
    if (_lifecycleManager == null) return;

    switch (event) {
      case NeonNativeLifecycleEvent.onResume:
      case NeonNativeLifecycleEvent.didBecomeActive:
      case NeonNativeLifecycleEvent.willEnterForeground:
        _lifecycleManager!.resume();
        break;

      case NeonNativeLifecycleEvent.onPause:
      case NeonNativeLifecycleEvent.willResignActive:
      case NeonNativeLifecycleEvent.didEnterBackground:
        _lifecycleManager!.pause();
        break;

      case NeonNativeLifecycleEvent.onDestroy:
      case NeonNativeLifecycleEvent.willTerminate:
        _lifecycleManager!.dispose();
        break;

      default:
        break;
    }
  }

  void simulateNativeEvent(NeonNativeLifecycleEvent event) {
    _onNativeEvent(event);
  }

  NeonNativeLifecycleEvent? _parseEvent(String name) {
    for (final event in NeonNativeLifecycleEvent.values) {
      if (event.name == name) return event;
    }
    return null;
  }

  void dispose() {
    _eventController.close();
    _eventLog.clear();
    _lifecycleManager = null;
  }
}

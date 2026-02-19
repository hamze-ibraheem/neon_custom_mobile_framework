import 'dart:async';
import 'package:neon_framework/src/platform/platform_channel.dart';
import 'package:neon_framework/src/rendering/canvas.dart';
import 'package:neon_framework/src/rendering/constraints.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

abstract class NeonRenderSurface {
  NeonSize get size;
  double get devicePixelRatio;
  bool get isReady;
}

class NeonNativeRenderer {
  final NeonPlatformChannel channel;
  bool _isReady = false;
  int _frameCount = 0;
  final List<NeonFrameRecord> _frameHistory = [];
  static const int _maxFrameHistory = 60;

  NeonNativeRenderer({required this.channel});

  bool get isReady => _isReady;
  int get frameCount => _frameCount;
  List<NeonFrameRecord> get frameHistory => List.unmodifiable(_frameHistory);

  Future<void> initialize(NeonSize surfaceSize, double devicePixelRatio) async {
    await channel.invokeMethod('renderer.init', {
      'width': surfaceSize.width,
      'height': surfaceSize.height,
      'devicePixelRatio': devicePixelRatio,
    });
    _isReady = true;
  }

  Future<void> submitFrame(NeonCanvas canvas) async {
    if (!_isReady) {
      throw StateError('Renderer is not initialized.');
    }

    final stopwatch = Stopwatch()..start();

    final serialized = _serializeCommands(canvas.commands);
    await channel.invokeMethod('renderer.submitFrame', {
      'frameNumber': _frameCount,
      'commands': serialized,
      'commandCount': canvas.commandCount,
    });

    stopwatch.stop();
    _frameCount++;

    final record = NeonFrameRecord(
      frameNumber: _frameCount - 1,
      commandCount: canvas.commandCount,
      renderTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
      timestamp: DateTime.now(),
    );
    _frameHistory.add(record);
    if (_frameHistory.length > _maxFrameHistory) {
      _frameHistory.removeAt(0);
    }
  }

  Future<void> clear() async {
    await channel.invokeMethod('renderer.clear');
  }

  List<Map<String, dynamic>> _serializeCommands(List<NeonPaintCommand> commands) {
    return commands.map((cmd) {
      final params = <String, dynamic>{};
      for (final entry in cmd.params.entries) {
        params[entry.key] = _serializeValue(entry.value);
      }
      return {
        'type': cmd.type.name,
        'params': params,
      };
    }).toList();
  }

  dynamic _serializeValue(dynamic value) {
    if (value is NeonRect) {
      return {'left': value.left, 'top': value.top, 'width': value.width, 'height': value.height};
    }
    if (value is NeonOffset) {
      return {'dx': value.dx, 'dy': value.dy};
    }
    if (value is NeonSize) {
      return {'width': value.width, 'height': value.height};
    }
    if (value is NeonColor) {
      return value.value;
    }
    if (value is NeonTextStyle) {
      return {
        'fontSize': value.fontSize,
        'fontWeight': value.fontWeight.name,
        'color': value.color.value,
      };
    }
    return value;
  }

  double get averageFrameTimeMs {
    if (_frameHistory.isEmpty) return 0;
    final total = _frameHistory.fold<double>(0, (sum, r) => sum + r.renderTimeMs);
    return total / _frameHistory.length;
  }

  void dispose() {
    _isReady = false;
    _frameHistory.clear();
  }
}

class NeonFrameRecord {
  final int frameNumber;
  final int commandCount;
  final double renderTimeMs;
  final DateTime timestamp;

  const NeonFrameRecord({
    required this.frameNumber,
    required this.commandCount,
    required this.renderTimeMs,
    required this.timestamp,
  });

  @override
  String toString() =>
      'Frame #$frameNumber: $commandCount cmds in ${renderTimeMs.toStringAsFixed(2)}ms';
}

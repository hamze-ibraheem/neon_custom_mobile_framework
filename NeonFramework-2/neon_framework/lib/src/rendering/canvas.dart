import 'package:neon_framework/src/rendering/constraints.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

/// Types of paint commands that can be recorded on a canvas.
enum NeonPaintCommandType {
  drawRect,
  drawText,
  drawCircle,
  drawLine,
  clipRect,
  transform,
  save,
  restore,
}

/// A recorded paint command with its type and parameters.
class NeonPaintCommand {
  final NeonPaintCommandType type;
  final Map<String, dynamic> params;

  const NeonPaintCommand(this.type, this.params);

  @override
  String toString() => 'NeonPaintCommand($type, $params)';
}

/// A recording canvas that captures paint commands for later replay.
class NeonCanvas {
  final List<NeonPaintCommand> _commands = [];

  /// Device information used for physical pixel conversions.
  final NeonDeviceInfo deviceInfo;

  NeonCanvas({this.deviceInfo = const NeonDeviceInfo()});

  /// Returns an unmodifiable list of recorded paint commands.
  List<NeonPaintCommand> get commands => List.unmodifiable(_commands);

  /// Draws a filled rectangle with the given color.
  void drawRect(NeonRect rect, {NeonColor color = NeonColor.black}) {
    _commands.add(NeonPaintCommand(
      NeonPaintCommandType.drawRect,
      {
        'rect': rect,
        'color': color,
        'physicalRect': _toPhysical(rect),
      },
    ));
  }

  /// Draws text at the given position with the specified style.
  void drawText(
    String text,
    NeonOffset position, {
    NeonTextStyle style = const NeonTextStyle(),
  }) {
    _commands.add(NeonPaintCommand(
      NeonPaintCommandType.drawText,
      {
        'text': text,
        'position': position,
        'style': style,
        'physicalPosition': _toPhysicalOffset(position),
      },
    ));
  }

  /// Draws a circle at the given center with the specified radius and color.
  void drawCircle(
    NeonOffset center,
    double radius, {
    NeonColor color = NeonColor.black,
  }) {
    _commands.add(NeonPaintCommand(
      NeonPaintCommandType.drawCircle,
      {
        'center': center,
        'radius': radius,
        'color': color,
        'physicalRadius': radius * deviceInfo.devicePixelRatio,
      },
    ));
  }

  /// Draws a line between two points with the given color and stroke width.
  void drawLine(
    NeonOffset start,
    NeonOffset end, {
    NeonColor color = NeonColor.black,
    double strokeWidth = 1.0,
  }) {
    _commands.add(NeonPaintCommand(
      NeonPaintCommandType.drawLine,
      {
        'start': start,
        'end': end,
        'color': color,
        'strokeWidth': strokeWidth,
      },
    ));
  }

  /// Clips subsequent drawing to the given rectangle.
  void clipRect(NeonRect rect) {
    _commands.add(NeonPaintCommand(
      NeonPaintCommandType.clipRect,
      {'rect': rect},
    ));
  }

  /// Saves the current canvas state onto the state stack.
  void save() {
    _commands.add(
        const NeonPaintCommand(NeonPaintCommandType.save, {}));
  }

  /// Restores the most recently saved canvas state.
  void restore() {
    _commands.add(
        const NeonPaintCommand(NeonPaintCommandType.restore, {}));
  }

  /// Translates the canvas origin by the given offsets.
  void translate(double dx, double dy) {
    _commands.add(NeonPaintCommand(
      NeonPaintCommandType.transform,
      {'dx': dx, 'dy': dy},
    ));
  }

  NeonRect _toPhysical(NeonRect rect) {
    final ratio = deviceInfo.devicePixelRatio;
    return NeonRect(
      rect.left * ratio,
      rect.top * ratio,
      rect.width * ratio,
      rect.height * ratio,
    );
  }

  NeonOffset _toPhysicalOffset(NeonOffset offset) {
    final ratio = deviceInfo.devicePixelRatio;
    return NeonOffset(offset.dx * ratio, offset.dy * ratio);
  }

  /// Clears all recorded paint commands.
  void clear() {
    _commands.clear();
  }

  /// The number of recorded paint commands.
  int get commandCount => _commands.length;
}

/// Describes the device's display properties for rendering calculations.
class NeonDeviceInfo {
  /// The ratio of physical pixels to logical pixels.
  final double devicePixelRatio;

  /// The logical screen size.
  final NeonSize screenSize;

  /// The physical screen size in device pixels.
  final NeonSize physicalSize;

  const NeonDeviceInfo({
    this.devicePixelRatio = 1.0,
    this.screenSize = const NeonSize(360, 800),
    this.physicalSize = const NeonSize(1080, 2400),
  });

  /// The logical size of the display (alias for screenSize).
  NeonSize get logicalSize => screenSize;

  @override
  String toString() =>
      'NeonDeviceInfo(dpr: $devicePixelRatio, screen: $screenSize)';
}

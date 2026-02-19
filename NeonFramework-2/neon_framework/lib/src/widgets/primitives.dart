import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';

/// Represents an ARGB color value.
class NeonColor {
  /// The 32-bit ARGB color value.
  final int value;

  /// Creates a color from a 32-bit ARGB [value].
  const NeonColor(this.value);

  /// Fully transparent color.
  static const NeonColor transparent = NeonColor(0x00000000);

  /// Opaque black.
  static const NeonColor black = NeonColor(0xFF000000);

  /// Opaque white.
  static const NeonColor white = NeonColor(0xFFFFFFFF);

  /// Opaque red.
  static const NeonColor red = NeonColor(0xFFFF0000);

  /// Opaque green.
  static const NeonColor green = NeonColor(0xFF00FF00);

  /// Opaque blue.
  static const NeonColor blue = NeonColor(0xFF0000FF);

  /// Opaque grey.
  static const NeonColor grey = NeonColor(0xFF808080);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NeonColor && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() =>
      'NeonColor(0x${value.toRadixString(16).padLeft(8, '0').toUpperCase()})';
}

/// Represents font weight options for text rendering.
enum NeonFontWeight {
  normal,
  bold,
}

/// Defines the visual style for text rendering.
class NeonTextStyle {
  /// The font size in logical pixels.
  final double fontSize;

  /// The text color.
  final NeonColor color;

  /// The font weight (normal or bold).
  final NeonFontWeight fontWeight;

  /// Creates a text style with optional font size, color, and weight.
  const NeonTextStyle({
    this.fontSize = 14.0,
    this.color = NeonColor.black,
    this.fontWeight = NeonFontWeight.normal,
  });

  @override
  String toString() =>
      'NeonTextStyle(size: $fontSize, color: $color, weight: $fontWeight)';
}

/// Represents padding or margin insets on all four sides.
class NeonEdgeInsets {
  /// The top inset.
  final double top;

  /// The right inset.
  final double right;

  /// The bottom inset.
  final double bottom;

  /// The left inset.
  final double left;

  /// Creates edge insets with the same [value] on all sides.
  const NeonEdgeInsets.all(double value)
      : top = value,
        right = value,
        bottom = value,
        left = value;

  /// Creates edge insets with symmetric vertical and horizontal values.
  const NeonEdgeInsets.symmetric({
    double vertical = 0.0,
    double horizontal = 0.0,
  })  : top = vertical,
        bottom = vertical,
        left = horizontal,
        right = horizontal;

  /// Creates edge insets with individually specified sides.
  const NeonEdgeInsets.only({
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
    this.left = 0.0,
  });

  /// Zero insets on all sides.
  static const NeonEdgeInsets zero = NeonEdgeInsets.all(0);

  @override
  bool operator ==(Object other) =>
      other is NeonEdgeInsets &&
      top == other.top &&
      right == other.right &&
      bottom == other.bottom &&
      left == other.left;

  @override
  int get hashCode => Object.hash(top, right, bottom, left);

  @override
  String toString() => 'NeonEdgeInsets($top, $right, $bottom, $left)';
}

/// Defines how children are aligned along the main axis.
enum MainAxisAlignment {
  start,
  end,
  center,
  spaceBetween,
  spaceAround,
  spaceEvenly,
}

/// Defines how children are aligned along the cross axis.
enum CrossAxisAlignment {
  start,
  end,
  center,
  stretch,
}

/// Defines how a stack sizes its non-positioned children.
enum StackFit {
  loose,
  expand,
}

/// A terminal widget with no children, representing a primitive element.
class LeafWidget extends NeonWidget {
  /// The type identifier for this leaf widget.
  final String type;

  /// Creates a leaf widget of the given [type].
  const LeafWidget({super.key, required this.type});

  @override
  NeonWidget build(NeonBuildContext context) => this;

  @override
  String toString() => 'LeafWidget($type)';
}

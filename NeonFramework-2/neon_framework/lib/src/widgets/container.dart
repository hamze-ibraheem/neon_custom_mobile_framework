import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

/// A box widget with optional sizing, color, padding, margin, and a child.
class Container extends NeonWidget {
  /// The child widget rendered inside this container.
  final NeonWidget? child;

  /// The fixed width of the container, or null for unconstrained.
  final double? width;

  /// The fixed height of the container, or null for unconstrained.
  final double? height;

  /// The background color of the container.
  final NeonColor? color;

  /// The padding inside the container around the child.
  final NeonEdgeInsets padding;

  /// The margin outside the container.
  final NeonEdgeInsets margin;

  /// Creates a container with optional sizing, color, padding, margin, and child.
  const Container({
    super.key,
    this.child,
    this.width,
    this.height,
    this.color,
    this.padding = NeonEdgeInsets.zero,
    this.margin = NeonEdgeInsets.zero,
  });

  @override
  NeonWidget build(NeonBuildContext context) => this;

  @override
  String toString() =>
      'Container(${width}x$height, color: $color)';
}

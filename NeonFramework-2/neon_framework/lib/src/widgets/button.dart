import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/container.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

/// A callback with no arguments and no return value.
typedef NeonVoidCallback = void Function();

/// A tappable button widget that wraps a child widget.
class Button extends NeonWidget {
  /// The widget displayed inside the button.
  final NeonWidget child;

  /// Called when the button is tapped, if enabled.
  final NeonVoidCallback? onPressed;

  /// The padding around the button content.
  final NeonEdgeInsets padding;

  /// The background color of the button.
  final NeonColor? color;

  /// Whether the button responds to taps.
  final bool enabled;

  /// Creates a button with a required [child] and optional tap handling.
  const Button({
    super.key,
    required this.child,
    this.onPressed,
    this.padding = const NeonEdgeInsets.symmetric(
      vertical: 8.0,
      horizontal: 16.0,
    ),
    this.color,
    this.enabled = true,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return Container(
      padding: padding,
      color: color ?? NeonColor.blue,
      child: child,
    );
  }

  /// Simulates a tap on the button, invoking [onPressed] if enabled.
  void tap() {
    if (enabled && onPressed != null) {
      onPressed!();
    }
  }

  @override
  String toString() => 'Button(enabled: $enabled)';
}

import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';
import 'package:neon_framework/src/widgets/layout.dart';

/// A Material 3 Badge widget.
///
/// Badges are used to decorate icons or buttons with supplemental information,
/// typically a count or a status dot.
class Badge extends StatelessWidget {
  /// The widget that the badge will be attached to.
  final NeonWidget child;

  /// The widget to display within the badge (e.g., a [Text] widget for counts).
  /// If null, a small "dot" badge is shown.
  final NeonWidget? label;

  /// The background color of the badge.
  final NeonColor backgroundColor;

  /// The color of the label text.
  final NeonColor labelColor;

  const Badge({
    super.key,
    required this.child,
    this.label,
    this.backgroundColor = NeonColor.red,
    this.labelColor = NeonColor.white,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    // We return a Stack to position the badge over the child.
    // However, since placement over an icon depends on the icon size,
    // we use a specific primitive 'BadgeLabel' that the native renderer knows how to anchor.
    return Stack(
      children: [
        child,
        BadgeLabel(
          label: label,
          backgroundColor: backgroundColor,
          labelColor: labelColor,
        ),
      ],
    );
  }
}

/// Primitive for the badge label anchored to its parent or rendered inline.
class BadgeLabel extends LeafWidget {
  final NeonWidget? label;
  final NeonColor backgroundColor;
  final NeonColor labelColor;

  const BadgeLabel({
    this.label,
    required this.backgroundColor,
    required this.labelColor,
  }) : super(type: 'BadgeLabel');
}

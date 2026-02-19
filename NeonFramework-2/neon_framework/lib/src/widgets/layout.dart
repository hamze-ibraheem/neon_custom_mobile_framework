import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

/// A widget that arranges its children vertically.
class Column extends MultiChildWidget {
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const Column({
    super.key,
    required super.children, // ✅ MUST use super.children
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  NeonWidget? build(NeonBuildContext context) {
    return null; // ✅ MUST return null
  }

  @override
  String toString() =>
      'Column(children: ${children.length}, main: $mainAxisAlignment, cross: $crossAxisAlignment)';
}

/// A widget that arranges its children horizontally.
class Row extends MultiChildWidget {
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const Row({
    super.key,
    required super.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  NeonWidget? build(NeonBuildContext context) {
    return null;
  }

  @override
  String toString() =>
      'Row(children: ${children.length}, main: $mainAxisAlignment, cross: $crossAxisAlignment)';
}

/// A widget that layers its children on top of each other.
class Stack extends MultiChildWidget {
  final StackFit fit;

  const Stack({
    super.key,
    required super.children,
    this.fit = StackFit.loose,
  });

  @override
  NeonWidget? build(NeonBuildContext context) {
    return null;
  }

  @override
  String toString() => 'Stack(children: ${children.length}, fit: $fit)';
}

/// A widget that expands a child of a [Row], [Column], or [Flex].
class Expanded extends NeonWidget {
  final NeonWidget child;
  final int flex;

  const Expanded({
    super.key,
    required this.child,
    this.flex = 1,
  });

  @override
  NeonWidget? build(NeonBuildContext context) => null;
}

/// A widget that centers its child within itself.
class Center extends NeonWidget {
  final NeonWidget child;

  const Center({
    super.key,
    required this.child,
  });

  @override
  NeonWidget? build(NeonBuildContext context) => null;
}

/// A box with a specified size.
class SizedBox extends NeonWidget {
  final double? width;
  final double? height;
  final NeonWidget? child;

  const SizedBox({
    super.key,
    this.width,
    this.height,
    this.child,
  });

  @override
  NeonWidget? build(NeonBuildContext context) => null;
}

/// A flexible space that can be used in a [Row] or [Column].
class Spacer extends NeonWidget {
  final int flex;

  const Spacer({
    super.key,
    this.flex = 1,
  });

  @override
  NeonWidget? build(NeonBuildContext context) => null;
}

/// A widget that controls where a child of a [Stack] is positioned.
class Positioned extends NeonWidget {
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final NeonWidget child;

  const Positioned({
    super.key,
    this.left,
    this.top,
    this.right,
    this.bottom,
    required this.child,
  });

  @override
  NeonWidget? build(NeonBuildContext context) => null;
}

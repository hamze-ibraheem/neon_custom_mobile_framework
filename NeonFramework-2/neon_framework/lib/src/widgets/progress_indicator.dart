import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

class LinearProgressIndicator extends NeonWidget {
  final double? value;
  final NeonColor? color;
  final NeonColor? backgroundColor;
  final double minHeight;
  final double borderRadius;

  const LinearProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.minHeight = 4.0,
    this.borderRadius = 2.0,
  });

  bool get isIndeterminate => value == null;

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'LinearProgressIndicator', key: key);
  }
}

class CircularProgressIndicator extends NeonWidget {
  final double? value;
  final NeonColor? color;
  final NeonColor? backgroundColor;
  final double strokeWidth;
  final double size;

  const CircularProgressIndicator({
    super.key,
    this.value,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 4.0,
    this.size = 36.0,
  });

  bool get isIndeterminate => value == null;

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'CircularProgressIndicator', key: key);
  }
}

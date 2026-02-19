import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

enum CardVariant { elevated, filled, outlined }

class Card extends NeonWidget {
  final NeonWidget child;
  final CardVariant variant;
  final NeonEdgeInsets padding;
  final double borderRadius;
  final NeonColor? color;
  final void Function()? onTap;

  const Card({
    super.key,
    required this.child,
    this.variant = CardVariant.elevated,
    this.padding = const NeonEdgeInsets.all(16.0),
    this.borderRadius = 12.0,
    this.color,
    this.onTap,
  });

  const Card.filled({
    super.key,
    required this.child,
    this.padding = const NeonEdgeInsets.all(16.0),
    this.borderRadius = 12.0,
    this.color,
    this.onTap,
  }) : variant = CardVariant.filled;

  const Card.outlined({
    super.key,
    required this.child,
    this.padding = const NeonEdgeInsets.all(16.0),
    this.borderRadius = 12.0,
    this.color,
    this.onTap,
  }) : variant = CardVariant.outlined;

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'Card', key: key);
  }
}

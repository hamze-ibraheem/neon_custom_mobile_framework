import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

class BottomSheet extends NeonWidget {
  final NeonWidget child;
  final bool showDragHandle;
  final bool visible;
  final double borderRadius;
  final NeonColor? backgroundColor;
  final void Function()? onDismiss;

  const BottomSheet({
    super.key,
    required this.child,
    this.showDragHandle = true,
    this.visible = false,
    this.borderRadius = 28.0,
    this.backgroundColor,
    this.onDismiss,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'BottomSheet', key: key);
  }
}

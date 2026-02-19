import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

class Tooltip extends NeonWidget {
  final String message;
  final NeonWidget child;
  final bool preferBelow;
  final double verticalOffset;

  const Tooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = true,
    this.verticalOffset = 24.0,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'Tooltip', key: key);
  }
}

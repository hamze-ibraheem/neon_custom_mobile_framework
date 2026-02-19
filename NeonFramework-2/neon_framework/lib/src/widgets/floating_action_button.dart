import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/button.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

enum FABVariant { small, regular, large, extended }

class FloatingActionButton extends NeonWidget {
  final NeonWidget child;
  final NeonVoidCallback? onPressed;
  final FABVariant variant;

  const FloatingActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = FABVariant.regular,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    double paddingValue = 16.0;
    if (variant == FABVariant.small) paddingValue = 8.0;
    if (variant == FABVariant.large) paddingValue = 24.0;

    return Button(
      onPressed: onPressed,
      color: const NeonColor(0xFFD0BCFF), // M3 FAB default color
      padding: NeonEdgeInsets.all(paddingValue),
      child: child,
    );
  }
}

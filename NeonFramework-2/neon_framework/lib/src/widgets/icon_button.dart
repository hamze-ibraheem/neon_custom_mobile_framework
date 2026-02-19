import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/button.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

enum IconButtonVariant { standard, filled, tonal, outlined }

class IconButton extends NeonWidget {
  final NeonWidget icon;
  final NeonVoidCallback? onPressed;
  final IconButtonVariant variant;

  const IconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.variant = IconButtonVariant.standard,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    NeonColor color = NeonColor.transparent;
    if (variant == IconButtonVariant.filled) color = NeonColor.blue;
    if (variant == IconButtonVariant.tonal) color = const NeonColor(0xFFEADDFF);

    return Button(
      key: key,
      onPressed: onPressed,
      color: color,
      padding: const NeonEdgeInsets.all(12.0),
      child: icon,
    );
  }
}

import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

enum AppBarVariant { centerAligned, small, medium, large }

class AppBar extends NeonWidget {
  final NeonWidget title;
  final List<NeonWidget>? actions;
  final NeonWidget? leading;
  final AppBarVariant variant;

  const AppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.variant = AppBarVariant.small,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'AppBar', key: key);
  }
}

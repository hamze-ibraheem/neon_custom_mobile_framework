import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

enum SnackBarBehavior { fixed, floating }

class SnackBar extends NeonWidget {
  final NeonWidget content;
  final NeonWidget? action;
  final String? actionLabel;
  final bool visible;
  final SnackBarBehavior behavior;
  final Duration duration;
  final bool showCloseIcon;
  final void Function()? onAction;
  final void Function()? onDismiss;

  const SnackBar({
    super.key,
    required this.content,
    this.action,
    this.actionLabel,
    this.visible = false,
    this.behavior = SnackBarBehavior.floating,
    this.duration = const Duration(seconds: 4),
    this.showCloseIcon = false,
    this.onAction,
    this.onDismiss,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'SnackBar', key: key);
  }
}

import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

enum DialogVariant { standard, fullscreen }

class Dialog extends NeonWidget {
  final NeonWidget? title;
  final NeonWidget? content;
  final List<NeonWidget>? actions;
  final DialogVariant variant;
  final double borderRadius;
  final bool visible;
  final void Function()? onDismiss;

  const Dialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.variant = DialogVariant.standard,
    this.borderRadius = 28.0,
    this.visible = false,
    this.onDismiss,
  });

  const Dialog.fullscreen({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.borderRadius = 28.0,
    this.visible = false,
    this.onDismiss,
  }) : variant = DialogVariant.fullscreen;

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'Dialog', key: key);
  }
}

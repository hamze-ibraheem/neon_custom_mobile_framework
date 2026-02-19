import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

class ListTile extends NeonWidget {
  final NeonWidget? leading;
  final NeonWidget? title;
  final NeonWidget? subtitle;
  final NeonWidget? trailing;
  final bool enabled;
  final bool selected;
  final bool dense;
  final NeonEdgeInsets contentPadding;
  final void Function()? onTap;

  const ListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.enabled = true,
    this.selected = false,
    this.dense = false,
    this.contentPadding = const NeonEdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.onTap,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'ListTile', key: key);
  }
}

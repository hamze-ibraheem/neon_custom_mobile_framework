import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

class SegmentedButton extends NeonWidget {
  final List<NeonWidget> segments;
  final int selectedIndex;
  final Function(int)? onSelectionChanged;

  const SegmentedButton({
    super.key,
    required this.segments,
    required this.selectedIndex,
    this.onSelectionChanged,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'SegmentedButton', key: key);
  }
}

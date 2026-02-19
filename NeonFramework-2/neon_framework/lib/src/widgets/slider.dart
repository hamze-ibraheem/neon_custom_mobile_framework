import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

/// A Material 3 Slider widget.
class Slider extends StatelessWidget {
  final double value;
  final void Function(double)? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final bool enabled;

  const Slider({
    super.key,
    required this.value,
    this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.enabled = true,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(
      key: key,
      type: 'Slider',
    );
  }
}

/// A Material 3 RangeSlider widget.
class RangeSlider extends StatelessWidget {
  final NeonRangeValues values;
  final void Function(NeonRangeValues)? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? labels;
  final bool enabled;

  const RangeSlider({
    super.key,
    required this.values,
    this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.labels,
    this.enabled = true,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(
      key: key,
      type: 'RangeSlider',
    );
  }
}

/// Represents a range of values for a [RangeSlider].
class NeonRangeValues {
  final double start;
  final double end;

  const NeonRangeValues(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      other is NeonRangeValues && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'NeonRangeValues($start, $end)';
}

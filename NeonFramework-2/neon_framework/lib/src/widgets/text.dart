import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

/// A widget that displays a string of text with optional styling.
class Text extends NeonWidget {
  /// The text string to display.
  final String data;

  /// The visual style applied to the text.
  final NeonTextStyle style;

  /// The maximum number of lines for the text, or null for unlimited.
  final int? maxLines;

  /// Creates a text widget displaying [data] with optional [style] and [maxLines].
  const Text(
    this.data, {
    super.key,
    this.style = const NeonTextStyle(),
    this.maxLines,
  });

  @override
  NeonWidget build(NeonBuildContext context) => this;

  @override
  String toString() => 'Text("$data", style: $style)';
}

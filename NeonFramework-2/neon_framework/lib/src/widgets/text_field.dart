import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

enum TextFieldVariant { filled, outlined }

class TextField extends NeonWidget {
  final String value;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final NeonWidget? prefixIcon;
  final NeonWidget? suffixIcon;
  final TextFieldVariant variant;
  final bool enabled;
  final bool obscureText;
  final int maxLines;
  final double borderRadius;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const TextField({
    super.key,
    this.value = '',
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.variant = TextFieldVariant.filled,
    this.enabled = true,
    this.obscureText = false,
    this.maxLines = 1,
    this.borderRadius = 4.0,
    this.onChanged,
    this.onSubmitted,
  });

  const TextField.outlined({
    super.key,
    this.value = '',
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.obscureText = false,
    this.maxLines = 1,
    this.borderRadius = 4.0,
    this.onChanged,
    this.onSubmitted,
  }) : variant = TextFieldVariant.outlined;

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'TextField', key: key);
  }
}

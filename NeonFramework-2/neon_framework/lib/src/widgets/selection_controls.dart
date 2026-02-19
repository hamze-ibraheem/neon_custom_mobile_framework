import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

/// A Material 3 Switch widget.
class Switch extends StatelessWidget {
  final bool value;
  final void Function(bool)? onChanged;
  final bool enabled;

  const Switch({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(
      key: key,
      type: 'Switch',
      // The native renderer should look for these properties in the JSON
    );
  }
}

/// A Material 3 Checkbox widget.
class Checkbox extends StatelessWidget {
  final bool? value;
  final void Function(bool?)? onChanged;
  final bool enabled;
  final bool tristate;

  const Checkbox({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.tristate = false,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(
      key: key,
      type: 'Checkbox',
    );
  }
}

/// A Material 3 Radio widget.
class Radio<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final void Function(T?)? onChanged;
  final bool enabled;

  const Radio({
    super.key,
    required this.value,
    required this.groupValue,
    this.onChanged,
    this.enabled = true,
  });

  void selectValue() {
    onChanged?.call(value);
  }

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(
      key: key,
      type: 'Radio',
    );
  }
}

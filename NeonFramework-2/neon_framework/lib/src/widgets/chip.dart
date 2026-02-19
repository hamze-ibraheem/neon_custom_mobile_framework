import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

/// A Material 3 ActionChip widget.
class ActionChip extends StatelessWidget {
  final NeonWidget label;
  final NeonWidget? avatar;
  final void Function()? onPressed;
  final bool enabled;

  const ActionChip({
    super.key,
    required this.label,
    this.avatar,
    this.onPressed,
    this.enabled = true,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return _ChipPrimitive(
      type: 'ActionChip',
      label: label,
      avatar: avatar,
      enabled: enabled,
      onPressed: onPressed,
    );
  }
}

/// A Material 3 FilterChip widget.
class FilterChip extends StatelessWidget {
  final NeonWidget label;
  final bool selected;
  final void Function(bool)? onSelected;
  final NeonWidget? avatar;

  const FilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.avatar,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return _ChipPrimitive(
      type: 'FilterChip',
      label: label,
      selected: selected,
      avatar: avatar,
      onSelected: onSelected != null ? () => onSelected!(!selected) : null,
    );
  }
}

/// A Material 3 ChoiceChip widget.
class ChoiceChip extends StatelessWidget {
  final NeonWidget label;
  final bool selected;
  final void Function(bool)? onSelected;
  final NeonWidget? avatar;

  const ChoiceChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.avatar,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return _ChipPrimitive(
      type: 'ChoiceChip',
      label: label,
      selected: selected,
      avatar: avatar,
      onSelected: onSelected != null ? () => onSelected!(true) : null,
    );
  }
}

/// A Material 3 InputChip widget.
class InputChip extends StatelessWidget {
  final NeonWidget label;
  final NeonWidget? avatar;
  final void Function()? onPressed;
  final void Function()? onDeleted;
  final bool selected;

  const InputChip({
    super.key,
    required this.label,
    this.avatar,
    this.onPressed,
    this.onDeleted,
    this.selected = false,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return _ChipPrimitive(
      type: 'InputChip',
      label: label,
      avatar: avatar,
      selected: selected,
      onPressed: onPressed,
      onDeleted: onDeleted,
    );
  }
}

/// Internal primitive for chips.
class _ChipPrimitive extends LeafWidget {
  final NeonWidget label;
  final NeonWidget? avatar;
  final bool enabled;
  final bool selected;
  final void Function()? onPressed;
  final void Function()? onSelected;
  final void Function()? onDeleted;

  const _ChipPrimitive({
    required String type,
    required this.label,
    this.avatar,
    this.enabled = true,
    this.selected = false,
    this.onPressed,
    this.onSelected,
    this.onDeleted,
  }) : super(type: type);
}

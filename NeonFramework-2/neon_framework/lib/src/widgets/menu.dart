import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

class MenuItem {
  final String label;
  final NeonWidget? leadingIcon;
  final NeonWidget? trailingIcon;
  final bool enabled;
  final List<MenuItem>? subMenu;
  final void Function()? onPressed;

  const MenuItem({
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.enabled = true,
    this.subMenu,
    this.onPressed,
  });
}

class MenuAnchor extends NeonWidget {
  final NeonWidget child;
  final List<MenuItem> menuItems;
  final bool expanded;
  final void Function()? onOpen;
  final void Function()? onClose;

  const MenuAnchor({
    super.key,
    required this.child,
    required this.menuItems,
    this.expanded = false,
    this.onOpen,
    this.onClose,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'MenuAnchor', key: key);
  }
}

class MenuBar extends NeonWidget {
  final List<MenuItem> items;
  final int? selectedIndex;
  final void Function(int)? onItemSelected;

  const MenuBar({
    super.key,
    required this.items,
    this.selectedIndex,
    this.onItemSelected,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'MenuBar', key: key);
  }
}

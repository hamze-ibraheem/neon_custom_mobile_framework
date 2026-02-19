import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

/// A Material 3 Navigation Bar destination.
class NavigationDestination {
  final NeonWidget icon;
  final String label;

  const NavigationDestination({
    required this.icon,
    required this.label,
  });
}

/// A Material 3 Navigation Bar.
class NavigationBar extends NeonWidget {
  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final Function(int)? onDestinationSelected;

  const NavigationBar({
    super.key,
    required this.destinations,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'NavigationBar', key: key);
  }
}

/// A Material 3 Navigation Drawer destination.
class NavigationDrawerDestination {
  final NeonWidget icon;
  final NeonWidget label;

  const NavigationDrawerDestination({
    required this.icon,
    required this.label,
  });
}

/// A Material 3 Navigation Drawer.
class NavigationDrawer extends NeonWidget {
  final List<NavigationDrawerDestination> children;
  final int selectedIndex;
  final Function(int)? onDestinationSelected;

  const NavigationDrawer({
    super.key,
    required this.children,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'NavigationDrawer', key: key);
  }
}

/// A Material 3 Navigation Rail destination.
class NavigationRailDestination {
  final NeonWidget icon;
  final NeonWidget label;

  const NavigationRailDestination({
    required this.icon,
    required this.label,
  });
}

/// A Material 3 Navigation Rail.
class NavigationRail extends NeonWidget {
  final List<NavigationRailDestination> destinations;
  final int selectedIndex;
  final Function(int)? onDestinationSelected;

  const NavigationRail({
    super.key,
    required this.destinations,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'NavigationRail', key: key);
  }
}

/// A Material 3 Tab.
class Tab extends NeonWidget {
  final String text;
  final NeonWidget? icon;

  const Tab({
    super.key,
    required this.text,
    this.icon,
  });

  @override
  NeonWidget build(NeonBuildContext context) => this;
}

/// A Material 3 Tab Bar.
class TabBar extends NeonWidget {
  final List<Tab> tabs;
  final int selectedIndex;
  final Function(int)? onTap;

  const TabBar({
    super.key,
    required this.tabs,
    this.selectedIndex = 0,
    this.onTap,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return LeafWidget(type: 'TabBar', key: key);
  }
}

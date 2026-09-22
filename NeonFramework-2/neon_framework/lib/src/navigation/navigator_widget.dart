import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/layout.dart';
import 'navigator_controller.dart';

/// A widget that renders the active route of a [NavigatorController] and binds it to the context.
class NeonNavigator extends StatefulWidget {
  /// The controller managing the stack for this navigator.
  final NavigatorController controller;

  /// Transition animation style for route changes (e.g. `slideHorizontal`, `fade`, `modal`).
  final String transition;

  const NeonNavigator({
    super.key,
    required this.controller,
    this.transition = 'slideHorizontal',
  });

  @override
  NeonState<NeonNavigator> createState() => _NeonNavigatorState();
}

class _NeonNavigatorState extends NeonState<NeonNavigator> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleStackChange);
  }

  void _handleStackChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleStackChange);
    super.dispose();
  }

  @override
  NeonWidget build(NeonBuildContext context) {
    context.provide<NavigatorController>(widget.controller);
    final active = widget.controller.buildActiveWidget(context);
    return active ?? const SizedBox();
  }
}

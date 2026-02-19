import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/core/neon_app.dart';

/// Base class for all Neon widgets.
abstract class NeonWidget {
  /// Creates a widget with an optional identification [key].
  const NeonWidget({this.key});

  /// An optional key used to identify this widget in the tree.
  final String? key;

  /// Builds and returns the widget tree for this widget.
  NeonWidget? build(NeonBuildContext context);

  @override
  String toString() => '$runtimeType(key: $key)';
}

/// A widget that does not hold mutable state.
abstract class StatelessWidget extends NeonWidget {
  /// Creates a stateless widget with an optional [key].
  const StatelessWidget({super.key});
}

/// A widget that has mutable state managed by a [NeonState] object.
abstract class StatefulWidget extends NeonWidget {
  /// Creates a stateful widget with an optional [key].
  const StatefulWidget({super.key});

  /// Creates the mutable state for this widget.
  NeonState createState();

  @override
  NeonWidget build(NeonBuildContext context) {
    final String? id = context.id;

    // ignore: undefined_identifier
    final Map<String, NeonState> store = NeonApp.globalStateStore;

    NeonState? state;
    if (id != null && store.containsKey(id)) {
      state = store[id];
      try {
        state!.bindWidget(this);
        state.bindContext(context);
      } catch (_) {
        state?.dispose();
        store.remove(id);
        state = null;
      }
    }
    if (state == null) {
      state = createState();
      state.bindWidget(this);
      state.bindContext(context);
      state.initState();
      if (id != null) {
        store[id] = state;
      }
    }

    return state.build(context);
  }
}

/// Manages mutable state for a [StatefulWidget].
abstract class NeonState<T extends StatefulWidget> {
  T? _widget;
  NeonBuildContext? _context;
  bool _mounted = true;

  /// The associated stateful widget.
  T get widget {
    if (_widget == null) {
      throw StateError('State has not been initialized.');
    }
    return _widget!;
  }

  /// The build context associated with this state.
  NeonBuildContext get context {
    if (_context == null) {
      throw StateError('State has no context. Was it built?');
    }
    return _context!;
  }

  /// Whether this state object is currently active in the tree.
  bool get mounted => _mounted;

  /// Binds this state to its associated [widget].
  void bindWidget(StatefulWidget widget) {
    _widget = widget as T;
  }

  /// Binds this state to the given build [context].
  void bindContext(NeonBuildContext context) {
    _context = context;
  }

  /// Called once when the state is first created.
  void initState() {}

  /// Builds the widget tree for the current state.
  NeonWidget build(NeonBuildContext context);

  /// Schedules a state update by executing [fn] and triggering a rebuild.
  void setState(void Function() fn) {
    if (!_mounted) {
      throw StateError('Cannot call setState on a disposed State.');
    }
    fn();
  }

  /// Disposes this state and marks it as unmounted.
  void dispose() {
    _mounted = false;
  }
}

/// A widget that manages a list of children (like Column, Row, Stack).
abstract class MultiChildWidget extends NeonWidget {
  /// The list of child widgets managed by this layout.
  final List<NeonWidget> children;

  const MultiChildWidget({
    required this.children,
    super.key,
  });
}

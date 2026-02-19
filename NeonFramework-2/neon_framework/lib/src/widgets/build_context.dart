import 'package:neon_framework/src/core/environment.dart';
import 'widget.dart'; // Import Widget so we can type 'NeonWidget'

/// Provides context information and inherited data during widget building.
class NeonBuildContext {
  /// The application configuration available in this context.
  final NeonConfig config;

  /// The parent context, if any.
  final NeonBuildContext? parent;

  /// The specific widget this context is tied to.
  /// (Added this so we know "where" we are in the tree).
  final NeonWidget? widget;

  /// The stable ID of the widget in the tree.
  final String? id;

  final Map<Type, dynamic> _inherited = {};

  /// Creates a build context with the given [config] and optional [parent].
  NeonBuildContext({
    required this.config,
    this.parent,
    this.widget,
    this.id,
  });

  /// ✅ THE MISSING METHOD
  /// Creates a child context for a new widget, inheriting from this context.
  NeonBuildContext spawn(NeonWidget childWidget, String childId) {
    return NeonBuildContext(
      config: config,
      parent: this,
      widget: childWidget,
      id: childId,
    );
  }

  /// Finds an inherited value of type [T] by searching up the context tree.
  T? findAncestor<T>() {
    if (_inherited.containsKey(T)) {
      return _inherited[T] as T;
    }
    return parent?.findAncestor<T>();
  }

  /// Provides a [value] of type [T] to descendant contexts.
  void provide<T>(T value) {
    _inherited[T] = value;
  }

  /// (Optional) Kept for backward compatibility if you used it elsewhere.
  NeonBuildContext createChild() {
    return NeonBuildContext(config: config, parent: this);
  }

  @override
  String toString() =>
      'NeonBuildContext(env: ${config.environment.name}, widget: ${widget.runtimeType})';
}

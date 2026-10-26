import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'route_guard.dart';

/// Cache and retention policy for routes when moved offscreen or replaced.
enum RouteCachePolicy {
  /// Default: Dispose widget state immediately when popped or moved offscreen.
  disposeImmediately,

  /// Keep the widget state in memory as long as the navigator is alive.
  keepAlive,

  /// Display cached snapshot immediately while re-evaluating data in the background.
  staleWhileRevalidate,

  /// Keep cached state in an LRU pool with a maximum retention limit.
  lru,
}

/// Holds the route state passed to the route builder and guards.
class NeonRouteState {
  /// The full path requested (e.g., `/users/42/profile?tab=posts`).
  final String location;

  /// The route path template that was matched (e.g., `/users/:id/profile`).
  final String matchedPath;

  /// Extracted dynamic path parameters (e.g., `{'id': '42'}`).
  final Map<String, String> pathParameters;

  /// Parsed query parameters from the URI (e.g., `{'tab': 'posts'}`).
  final Map<String, String> queryParameters;

  /// Extra custom arguments passed programmatically during push/replace.
  final dynamic arguments;

  /// Custom metadata map associated with the route.
  final Map<String, dynamic> meta;

  const NeonRouteState({
    required this.location,
    required this.matchedPath,
    this.pathParameters = const {},
    this.queryParameters = const {},
    this.arguments,
    this.meta = const {},
  });

  /// Retrieves a path parameter by [name].
  String? param(String name) => pathParameters[name];

  /// Retrieves a query parameter by [name].
  String? query(String name) => queryParameters[name];

  /// Serializes route state to JSON for state persistence.
  Map<String, dynamic> toJson() => {
        'location': location,
        'matchedPath': matchedPath,
        'pathParameters': pathParameters,
        'queryParameters': queryParameters,
        if (arguments is Map || arguments is String || arguments is num || arguments is bool)
          'arguments': arguments,
        'meta': meta,
      };

  /// Restores route state from a JSON map.
  factory NeonRouteState.fromJson(Map<String, dynamic> json) {
    return NeonRouteState(
      location: json['location'] as String? ?? '/',
      matchedPath: json['matchedPath'] as String? ?? '/',
      pathParameters: (json['pathParameters'] as Map?)?.cast<String, String>() ?? const {},
      queryParameters: (json['queryParameters'] as Map?)?.cast<String, String>() ?? const {},
      arguments: json['arguments'],
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  @override
  String toString() => 'NeonRouteState($location, params: $pathParameters, query: $queryParameters)';
}

/// Function signature for building a widget for a route.
typedef NeonRouteBuilder = NeonWidget Function(NeonBuildContext context, NeonRouteState state);

/// Represents a declarative route definition in the Neon navigation tree.
class NeonRoute {
  /// Path pattern (e.g. `/`, `/home`, `/users/:id`, `/orders/*rest`).
  final String path;

  /// Optional human-readable name for named routing.
  final String? name;

  /// Route builder function returning the [NeonWidget] to display.
  final NeonRouteBuilder builder;

  /// List of route guards evaluated before activation or deactivation.
  final List<NeonRouteGuard> guards;

  /// List of middlewares executed when this route is matched.
  final List<NeonMiddleware> middlewares;

  /// Nested sub-routes for hierarchical routing.
  final List<NeonRoute> children;

  /// Cache and state retention policy.
  final RouteCachePolicy cachePolicy;

  /// Optional title for native shell title bar synchronization.
  final String? title;

  /// Custom metadata map.
  final Map<String, dynamic> meta;

  const NeonRoute({
    required this.path,
    required this.builder,
    this.name,
    this.guards = const [],
    this.middlewares = const [],
    this.children = const [],
    this.cachePolicy = RouteCachePolicy.disposeImmediately,
    this.title,
    this.meta = const {},
  });

  @override
  String toString() => 'NeonRoute(path: $path, name: $name, children: ${children.length})';
}

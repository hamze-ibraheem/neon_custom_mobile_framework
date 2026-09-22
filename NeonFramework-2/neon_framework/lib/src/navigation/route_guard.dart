import 'dart:async';

/// Context provided to route guards and middlewares during navigation.
class NeonRouteContext {
  /// The current active path before navigation occurs.
  final String currentPath;

  /// The target path requested for navigation.
  final String targetPath;

  /// Path parameters extracted for the target route.
  final Map<String, String> pathParameters;

  /// Query parameters parsed from the target URI.
  final Map<String, String> queryParameters;

  /// Custom arguments passed to the route.
  final dynamic arguments;

  /// Custom metadata associated with the route.
  final Map<String, dynamic> meta;

  const NeonRouteContext({
    required this.currentPath,
    required this.targetPath,
    this.pathParameters = const {},
    this.queryParameters = const {},
    this.arguments,
    this.meta = const {},
  });

  /// Creates a copy of this context with updated properties.
  NeonRouteContext copyWith({
    String? currentPath,
    String? targetPath,
    Map<String, String>? pathParameters,
    Map<String, String>? queryParameters,
    dynamic arguments,
    Map<String, dynamic>? meta,
  }) {
    return NeonRouteContext(
      currentPath: currentPath ?? this.currentPath,
      targetPath: targetPath ?? this.targetPath,
      pathParameters: pathParameters ?? this.pathParameters,
      queryParameters: queryParameters ?? this.queryParameters,
      arguments: arguments ?? this.arguments,
      meta: meta ?? this.meta,
    );
  }

  @override
  String toString() =>
      'NeonRouteContext(from: $currentPath, to: $targetPath, params: $pathParameters)';
}

/// Result returned by route guards.
class NeonGuardResult {
  /// Whether the navigation is permitted.
  final bool allowed;

  /// If not allowed, an optional path to redirect to.
  final String? redirectPath;

  /// Optional arguments to pass to the redirected route.
  final Map<String, dynamic>? redirectArguments;

  /// Optional reason for aborting or redirecting.
  final String? reason;

  const NeonGuardResult.allow()
      : allowed = true,
        redirectPath = null,
        redirectArguments = null,
        reason = null;

  const NeonGuardResult.redirect(this.redirectPath, [this.redirectArguments])
      : allowed = false,
        reason = 'redirect';

  const NeonGuardResult.abort([this.reason])
      : allowed = false,
        redirectPath = null,
        redirectArguments = null;

  @override
  String toString() {
    if (allowed) return 'NeonGuardResult.allow()';
    if (redirectPath != null) return 'NeonGuardResult.redirect($redirectPath)';
    return 'NeonGuardResult.abort($reason)';
  }
}

/// Base contract for route guards.
abstract class NeonRouteGuard {
  const NeonRouteGuard();

  /// Evaluated before entering the target route.
  FutureOr<NeonGuardResult> canActivate(NeonRouteContext context) =>
      const NeonGuardResult.allow();

  /// Evaluated before leaving the current route (e.g. for unsaved changes confirmation).
  FutureOr<NeonGuardResult> canDeactivate(NeonRouteContext context) =>
      const NeonGuardResult.allow();
}

/// Base contract for route middlewares that can transform the context or execute side-effects.
abstract class NeonMiddleware {
  const NeonMiddleware();

  /// Intercepts and potentially transforms the route context before guards and builders execute.
  FutureOr<NeonRouteContext> handle(NeonRouteContext context) => context;
}

/// Exception thrown when navigation triggers more than the maximum permitted redirects.
class NavigationRedirectLoopException implements Exception {
  final String initialPath;
  final String currentPath;
  final int redirectCount;
  final List<String> history;

  const NavigationRedirectLoopException({
    required this.initialPath,
    required this.currentPath,
    required this.redirectCount,
    required this.history,
  });

  @override
  String toString() =>
      'NavigationRedirectLoopException: Exceeded maximum redirects ($redirectCount). '
      'Initial: "$initialPath", Last: "$currentPath". Chain: ${history.join(" -> ")}';
}

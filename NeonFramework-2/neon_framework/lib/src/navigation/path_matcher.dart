import 'route_definition.dart';

/// Result of matching a URL path against a route hierarchy.
class NeonRouteMatch {
  /// The specific matched route definition.
  final NeonRoute route;

  /// The chain of routes from root down to this leaf route.
  final List<NeonRoute> routeChain;

  /// Extracted path parameters (e.g. `{'userId': '42'}`).
  final Map<String, String> pathParameters;

  /// Parsed query parameters from the URI.
  final Map<String, String> queryParameters;

  /// The requested path location.
  final String location;

  /// The matched path template string.
  final String matchedPattern;

  const NeonRouteMatch({
    required this.route,
    required this.routeChain,
    required this.pathParameters,
    required this.queryParameters,
    required this.location,
    required this.matchedPattern,
  });

  /// Converts this match into a [NeonRouteState].
  NeonRouteState toRouteState({dynamic arguments}) {
    return NeonRouteState(
      location: location,
      matchedPath: matchedPattern,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      arguments: arguments,
      meta: route.meta,
    );
  }

  @override
  String toString() =>
      'NeonRouteMatch(path: $matchedPattern -> $location, params: $pathParameters)';
}

/// Matches URL paths and URIs against a declarative tree of [NeonRoute] definitions.
class NeonPathMatcher {
  final List<NeonRoute> routes;

  NeonPathMatcher(this.routes);

  /// Matches [rawUrl] against the registered routes. Returns null if no route matches.
  NeonRouteMatch? match(String rawUrl) {
    final uri = Uri.parse(rawUrl);
    final targetPath = _normalizePath(uri.path);
    final queryParams = uri.queryParameters;

    final targetSegments = _splitSegments(targetPath);

    return _matchRecursive(
      routes: routes,
      targetSegments: targetSegments,
      parentChain: [],
      accumulatedParams: {},
      accumulatedPattern: '',
      fullLocation: rawUrl,
      queryParams: queryParams,
    );
  }

  NeonRouteMatch? _matchRecursive({
    required List<NeonRoute> routes,
    required List<String> targetSegments,
    required List<NeonRoute> parentChain,
    required Map<String, String> accumulatedParams,
    required String accumulatedPattern,
    required String fullLocation,
    required Map<String, String> queryParams,
  }) {
    for (final route in routes) {
      final routeSegments = _splitSegments(_normalizePath(route.path));
      final Map<String, String> localParams = {};
      bool matched = false;
      int consumedCount = 0;

      // Handle root '/' path
      if (routeSegments.isEmpty) {
        if (targetSegments.isEmpty) {
          matched = true;
          consumedCount = 0;
        }
      } else {
        matched = true;
        for (int i = 0; i < routeSegments.length; i++) {
          final rSeg = routeSegments[i];

          // Wildcard match (e.g. * or *rest)
          if (rSeg == '*' || rSeg.startsWith('*')) {
            final paramName = rSeg.length > 1 ? rSeg.substring(1) : 'wildcard';
            localParams[paramName] = targetSegments.sublist(i).join('/');
            consumedCount = targetSegments.length;
            break;
          }

          if (i >= targetSegments.length) {
            matched = false;
            break;
          }

          final tSeg = targetSegments[i];

          // Parameterized segment (:id or :id(\\d+))
          if (rSeg.startsWith(':')) {
            final paramName = _extractParamName(rSeg);
            localParams[paramName] = tSeg;
          } else if (rSeg != tSeg) {
            matched = false;
            break;
          }

          consumedCount = i + 1;
        }
      }

      if (matched) {
        final newChain = [...parentChain, route];
        final newParams = {...accumulatedParams, ...localParams};
        final newPattern = accumulatedPattern.isEmpty
            ? route.path
            : (accumulatedPattern == '/' ? '' : accumulatedPattern) +
                (route.path.startsWith('/') ? route.path : '/${route.path}');

        final remainingTargetSegments = targetSegments.sublist(consumedCount);

        // If all target segments are consumed, this route is the match
        if (remainingTargetSegments.isEmpty) {
          return NeonRouteMatch(
            route: route,
            routeChain: newChain,
            pathParameters: newParams,
            queryParameters: queryParams,
            location: fullLocation,
            matchedPattern: newPattern,
          );
        }

        // Check child routes with the remaining segments
        if (route.children.isNotEmpty) {
          final childMatch = _matchRecursive(
            routes: route.children,
            targetSegments: remainingTargetSegments,
            parentChain: newChain,
            accumulatedParams: newParams,
            accumulatedPattern: newPattern,
            fullLocation: fullLocation,
            queryParams: queryParams,
          );
          if (childMatch != null) {
            return childMatch;
          }
        }
      }
    }

    return null;
  }

  /// Synthesizes parent hierarchy paths for a deep link (e.g. `/users/42/details` -> `['/', '/users', '/users/42', '/users/42/details']`).
  List<String> synthesizeHierarchy(String targetUrl) {
    final uri = Uri.parse(targetUrl);
    final segments = _splitSegments(_normalizePath(uri.path));
    final List<String> paths = ['/'];

    String current = '';
    for (final seg in segments) {
      current += '/$seg';
      if (!paths.contains(current)) {
        paths.add(current);
      }
    }

    return paths;
  }

  static String _normalizePath(String path) {
    if (path.isEmpty || path == '/') return '/';
    var clean = path.trim();
    if (!clean.startsWith('/')) clean = '/$clean';
    if (clean.endsWith('/') && clean.length > 1) {
      clean = clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  static List<String> _splitSegments(String path) {
    if (path == '/' || path.isEmpty) return [];
    return path
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String _extractParamName(String segment) {
    final raw = segment.substring(1);
    final parenIndex = raw.indexOf('(');
    if (parenIndex != -1) {
      return raw.substring(0, parenIndex);
    }
    return raw;
  }
}

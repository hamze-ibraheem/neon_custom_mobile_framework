import 'dart:async';
import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'route_definition.dart';
import 'route_guard.dart';
import 'path_matcher.dart';

/// Represents an active or historical entry on a navigator stack.
class NeonRouteEntry {
  final String routeId;
  final NeonRoute route;
  final NeonRouteState state;
  final Completer<dynamic>? completer;
  NeonWidget? cachedWidget;
  Map<String, dynamic>? stateSnapshot;

  NeonRouteEntry({
    required this.routeId,
    required this.route,
    required this.state,
    this.completer,
    this.cachedWidget,
    this.stateSnapshot,
  });

  /// A future that completes when this route is popped from the stack.
  Future<dynamic> get onPop => completer?.future ?? Future.value(null);

  /// Serializes this route entry into a JSON map for state restoration or bridge inspection.
  Map<String, dynamic> toJson() => {
        'routeId': routeId,
        'path': state.location,
        'matchedPath': state.matchedPath,
        'title': route.title,
        'state': state.toJson(),
        if (stateSnapshot != null) 'stateSnapshot': stateSnapshot,
      };

  @override
  String toString() => 'NeonRouteEntry($routeId: ${state.location})';
}

/// Manages a stack of routes for a given [navigatorId].
class NavigatorController {
  final String navigatorId;
  final NavigatorController? parent;
  final List<NeonRoute> routeRegistry;
  late final NeonPathMatcher _matcher;

  final List<NeonRouteEntry> _history = [];
  final Map<String, NavigatorController> _children = {};
  final List<void Function()> _listeners = [];
  int _sequenceCounter = 0;

  NavigatorController({
    required this.navigatorId,
    required this.routeRegistry,
    this.parent,
  }) {
    _matcher = NeonPathMatcher(routeRegistry);
    parent?.registerChild(this);
  }

  /// Looks up the nearest [NavigatorController] in the given [context].
  static NavigatorController of(NeonBuildContext context) {
    final controller = context.findAncestor<NavigatorController>();
    if (controller == null) {
      throw StateError(
          'NavigatorController.of() called with a context that does not contain a NavigatorController.');
    }
    return controller;
  }

  /// The active history stack for this navigator.
  List<NeonRouteEntry> get history => List.unmodifiable(_history);

  /// Current top-most route entry.
  NeonRouteEntry? get currentEntry => _history.isNotEmpty ? _history.last : null;

  /// Active route index.
  int get activeIndex => _history.isNotEmpty ? _history.length - 1 : 0;

  /// Child navigators hosted inside this navigator.
  Map<String, NavigatorController> get children => Map.unmodifiable(_children);

  /// Whether this navigator or any child navigator can pop a screen.
  bool get canPop {
    for (final child in _children.values) {
      if (child.canPop) return true;
    }
    return _history.length > 1;
  }

  /// Registers a child navigator under this controller.
  void registerChild(NavigatorController child) {
    _children[child.navigatorId] = child;
  }

  /// Unregisters a child navigator.
  void unregisterChild(String childId) {
    _children.remove(childId);
  }

  /// Adds a listener for navigation stack changes.
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Removes a listener.
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  /// Pushes a new route by [path] onto the stack. Resolves with the created [NeonRouteEntry] once mounted.
  Future<NeonRouteEntry?> push(String path, {dynamic arguments}) async {
    final entry = await _resolveAndBuildEntry(
      targetPath: path,
      arguments: arguments,
      initialPath: path,
      redirectCount: 0,
      redirectHistory: [],
    );

    if (entry == null) return null;

    _history.add(entry);
    _notifyListeners();

    return entry;
  }

  /// Pushes a route and waits until it is popped, returning the pop result.
  Future<T?> pushForResult<T>(String path, {dynamic arguments}) async {
    final entry = await push(path, arguments: arguments);
    if (entry == null) return null;
    final result = await entry.onPop;
    return result is T ? result : null;
  }

  /// Replaces the current top route with a new route by [path].
  Future<void> replace(String path, {dynamic arguments}) async {
    final entry = await _resolveAndBuildEntry(
      targetPath: path,
      arguments: arguments,
      initialPath: path,
      redirectCount: 0,
      redirectHistory: [],
    );

    if (entry == null) return;

    if (_history.isNotEmpty) {
      final old = _history.removeLast();
      old.completer?.complete(null);
    }

    _history.add(entry);
    _notifyListeners();
  }

  /// Pops the current top-most route from the stack and completes its future with [result].
  Future<bool> pop<T>([T? result]) async {
    if (_history.length <= 1) {
      return false;
    }

    final top = _history.last;
    final context = NeonRouteContext(
      currentPath: top.state.location,
      targetPath: _history[_history.length - 2].state.location,
      pathParameters: top.state.pathParameters,
      queryParameters: top.state.queryParameters,
      arguments: top.state.arguments,
    );

    // Evaluate canDeactivate guards
    for (final guard in top.route.guards) {
      final guardRes = await guard.canDeactivate(context);
      if (!guardRes.allowed) {
        return false;
      }
    }

    _history.removeLast();
    top.completer?.complete(result);
    _notifyListeners();
    return true;
  }

  /// Pops routes until [predicate] returns true, or until 1 entry remains.
  void popUntil(bool Function(NeonRouteEntry entry) predicate) {
    while (_history.length > 1 && !predicate(_history.last)) {
      final removed = _history.removeLast();
      removed.completer?.complete(null);
    }
    _notifyListeners();
  }

  /// Hierarchical back-button handler (Android hardware back & iOS edge swipe).
  /// Bubbles through children first, then pops locally, then delegates to parent.
  Future<bool> handleBack() async {
    // 1. Check if any child navigator can pop
    for (final child in _children.values) {
      if (child.canPop) {
        final handled = await child.handleBack();
        if (handled) return true;
      }
    }

    // 2. Try popping local stack
    if (_history.length > 1) {
      return await pop();
    }

    // 3. Delegate to parent navigator if present
    if (parent != null) {
      return await parent!.handleBack();
    }

    // Root stack with 1 entry left: delegate to native OS
    return false;
  }

  /// Builds the active widget for the current top route entry.
  NeonWidget? buildActiveWidget(NeonBuildContext context) {
    final entry = currentEntry;
    if (entry == null) return null;

    if (entry.route.cachePolicy == RouteCachePolicy.keepAlive &&
        entry.cachedWidget != null) {
      return entry.cachedWidget;
    }

    final built = entry.route.builder(context, entry.state);
    if (entry.route.cachePolicy == RouteCachePolicy.keepAlive) {
      entry.cachedWidget = built;
    }
    return built;
  }

  /// Resolves a path, runs middlewares and guards, and returns a prepared [NeonRouteEntry].
  Future<NeonRouteEntry?> _resolveAndBuildEntry<T>({
    required String targetPath,
    dynamic arguments,
    required String initialPath,
    required int redirectCount,
    required List<String> redirectHistory,
  }) async {
    if (redirectCount > 5) {
      throw NavigationRedirectLoopException(
        initialPath: initialPath,
        currentPath: targetPath,
        redirectCount: redirectCount,
        history: redirectHistory,
      );
    }

    final match = _matcher.match(targetPath);
    if (match == null) {
      throw StateError('NeonRouter: No route matched path "$targetPath".');
    }

    final currentPath = currentEntry?.state.location ?? '/';
    var routeContext = NeonRouteContext(
      currentPath: currentPath,
      targetPath: targetPath,
      pathParameters: match.pathParameters,
      queryParameters: match.queryParameters,
      arguments: arguments,
      meta: match.route.meta,
    );

    // 1. Execute middlewares
    for (final middleware in match.route.middlewares) {
      routeContext = await middleware.handle(routeContext);
    }

    // 2. Execute guards (canActivate)
    for (final guard in match.route.guards) {
      final guardResult = await guard.canActivate(routeContext);
      if (!guardResult.allowed) {
        if (guardResult.redirectPath != null) {
          final nextRedirect = guardResult.redirectPath!;
          return _resolveAndBuildEntry<T>(
            targetPath: nextRedirect,
            arguments: guardResult.redirectArguments ?? arguments,
            initialPath: initialPath,
            redirectCount: redirectCount + 1,
            redirectHistory: [...redirectHistory, targetPath],
          );
        }
        // Navigation aborted
        return null;
      }
    }

    _sequenceCounter++;
    final routeId = '${navigatorId}_r${_sequenceCounter}';
    final state = match.toRouteState(arguments: routeContext.arguments);

    return NeonRouteEntry(
      routeId: routeId,
      route: match.route,
      state: state,
      completer: Completer<dynamic>(),
    );
  }

  /// Serializes the entire navigator state to JSON for state restoration.
  Map<String, dynamic> toJson() => {
        'navigatorId': navigatorId,
        'canPop': canPop,
        'activeIndex': activeIndex,
        'history': _history.map((e) => e.toJson()).toList(),
        'children': _children.map((k, v) => MapEntry(k, v.toJson())),
      };

  /// Disposes this navigator controller and its children.
  void dispose() {
    for (final child in _children.values) {
      child.dispose();
    }
    _children.clear();
    _listeners.clear();
    for (final entry in _history) {
      entry.completer?.complete(null);
    }
    _history.clear();
    parent?.unregisterChild(navigatorId);
  }
}

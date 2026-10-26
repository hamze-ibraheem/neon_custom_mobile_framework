import 'dart:async';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/state/signal.dart';
import 'route_definition.dart';
import 'path_matcher.dart';
import 'navigator_controller.dart';

/// Central router orchestrating navigation, deep links, guards, and telemetry in Neon.
class NeonRouter {
  static NeonRouter? _instance;

  /// Global singleton instance of the router.
  static NeonRouter get instance {
    if (_instance == null) {
      throw StateError(
          'NeonRouter has not been initialized. Create a NeonRouter first.');
    }
    return _instance!;
  }

  /// Whether a global router instance has been created.
  static bool get hasInstance => _instance != null;

  /// Look up the router from build context or fallback to global instance.
  static NeonRouter of(NeonBuildContext context) {
    final fromContext = context.findAncestor<NeonRouter>();
    if (fromContext != null) return fromContext;
    return instance;
  }

  final List<NeonRoute> routes;
  final String initialLocation;
  late final NavigatorController rootNavigator;
  late final NeonPathMatcher matcher;

  final List<Map<String, dynamic>> _telemetryBreadcrumbs = [];
  final List<void Function()> _listeners = [];
  final List<NeonSignal> _boundSignals = [];

  NeonRouter({
    required this.routes,
    this.initialLocation = '/',
  }) {
    matcher = NeonPathMatcher(routes);
    rootNavigator = NavigatorController(
      navigatorId: 'root_nav',
      routeRegistry: routes,
    );

    rootNavigator.addListener(_handleNavigatorChanged);
    _instance = this;
  }

  /// Telemetry events recorded during navigation.
  List<Map<String, dynamic>> get telemetryBreadcrumbs =>
      List.unmodifiable(_telemetryBreadcrumbs);

  /// Initializes the router by pushing the initial route.
  Future<void> initialize() async {
    await rootNavigator.push(initialLocation);
    _recordTelemetry('INIT', initialLocation);
  }

  /// Adds a global router change listener.
  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  /// Removes a listener.
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _handleNavigatorChanged() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  /// Navigates to [path] on the root navigator. Resolves with the created [NeonRouteEntry] once mounted.
  Future<NeonRouteEntry?> push(String path, {dynamic arguments}) async {
    _recordTelemetry('PUSH', path);
    return await rootNavigator.push(path, arguments: arguments);
  }

  /// Navigates to [path] and waits until it is popped, returning the pop result.
  Future<T?> pushForResult<T>(String path, {dynamic arguments}) async {
    _recordTelemetry('PUSH_FOR_RESULT', path);
    return await rootNavigator.pushForResult<T>(path, arguments: arguments);
  }

  /// Replaces the current route with [path] on the root navigator.
  Future<void> replace(String path, {dynamic arguments}) async {
    _recordTelemetry('REPLACE', path);
    await rootNavigator.replace(path, arguments: arguments);
  }

  /// Pops the active route from the stack.
  Future<bool> pop<T>([T? result]) async {
    _recordTelemetry('POP', rootNavigator.currentEntry?.state.location ?? '/');
    return await rootNavigator.pop<T>(result);
  }

  /// Handles platform hardware back-button or edge-swipe gestures.
  Future<bool> handleBackButton() async {
    _recordTelemetry('BACK_BUTTON', rootNavigator.currentEntry?.state.location ?? '/');
    return await rootNavigator.handleBack();
  }

  /// Handles incoming deep links or universal links.
  /// If [synthesizeBackstack] is true, reconstructs ancestor paths for a natural back history.
  Future<void> handleDeepLink(
    String url, {
    String? source,
    bool synthesizeBackstack = true,
  }) async {
    _recordTelemetry('DEEP_LINK', url, metadata: {'source': source});

    if (synthesizeBackstack) {
      final hierarchy = matcher.synthesizeHierarchy(url);
      for (int i = 0; i < hierarchy.length; i++) {
        final path = hierarchy[i];
        if (matcher.match(path) != null) {
          if (i == 0 && rootNavigator.history.isNotEmpty) {
            continue;
          }
          if (i == hierarchy.length - 1) {
            // Target leaf: use push
            await rootNavigator.push(url);
          } else {
            // Ancestor: push as backstack foundation
            await rootNavigator.push(path);
          }
        }
      }
    } else {
      await rootNavigator.push(url);
    }
  }

  /// Binds a reactive [NeonSignal] to router redirect rules.
  /// Whenever the signal fires, [redirectRule] is evaluated; if non-null, routes automatically.
  void bindSignal(
    NeonSignal signal, {
    required String? Function() redirectRule,
  }) {
    _boundSignals.add(signal);
    signal.listen(() {
      final target = redirectRule();
      if (target != null && target != rootNavigator.currentEntry?.state.location) {
        replace(target);
      }
    });
  }

  /// Handles incoming actions dispatched across the bridge (e.g. from native shells).
  Future<bool> handleBridgeAction(Map<String, dynamic> params) async {
    final action = params['action']?.toString();
    final type = params['type']?.toString();

    if (action == 'nav_pop' || type == 'BACK_BUTTON_TRIGGERED') {
      return await handleBackButton();
    } else if (action == 'nav_push') {
      final path = params['path']?.toString();
      if (path != null) {
        await push(path, arguments: params['arguments']);
        return true;
      }
    } else if (action == 'nav_replace') {
      final path = params['path']?.toString();
      if (path != null) {
        await replace(path, arguments: params['arguments']);
        return true;
      }
    } else if (action == 'deep_link' || type == 'DEEP_LINK_TRIGGERED') {
      final url = params['url']?.toString();
      if (url != null) {
        await handleDeepLink(url, source: params['source']?.toString());
        return true;
      }
    }

    return false;
  }

  /// Exports a complete snapshot of navigation history for state restoration and time-travel.
  Map<String, dynamic> exportSnapshot() {
    return {
      'restorationVersion': 1,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'rootNavigator': rootNavigator.toJson(),
      'telemetry': _telemetryBreadcrumbs,
    };
  }

  /// Restores navigation state from a JSON snapshot.
  Future<void> restoreFromSnapshot(Map<String, dynamic> json) async {
    final rootData = json['rootNavigator'] as Map<String, dynamic>?;
    if (rootData == null) return;

    final historyList = rootData['history'] as List<dynamic>?;
    if (historyList == null || historyList.isEmpty) return;

    // Clear current history
    rootNavigator.popUntil((_) => false);

    for (int i = 0; i < historyList.length; i++) {
      final item = historyList[i] as Map<String, dynamic>;
      final path = item['path'] as String? ?? '/';
      final stateData = item['state'] as Map<String, dynamic>?;
      final args = stateData?['arguments'];

      if (i == 0 && rootNavigator.history.isNotEmpty) {
        await rootNavigator.replace(path, arguments: args);
      } else {
        await rootNavigator.push(path, arguments: args);
      }
    }
  }

  void _recordTelemetry(String event, String location, {Map<String, dynamic>? metadata}) {
    _telemetryBreadcrumbs.add({
      'event': event,
      'location': location,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      if (metadata != null) ...metadata,
    });
    // Keep last 100 breadcrumbs
    if (_telemetryBreadcrumbs.length > 100) {
      _telemetryBreadcrumbs.removeAt(0);
    }
  }

  /// Disposes the router, its navigators, and cleans up bound signal listeners.
  void dispose() {
    rootNavigator.dispose();
    _listeners.clear();
    _telemetryBreadcrumbs.clear();
    if (_instance == this) {
      _instance = null;
    }
  }
}

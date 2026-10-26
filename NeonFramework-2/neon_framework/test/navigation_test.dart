import 'package:test/test.dart';
import 'package:neon_framework/neon.dart';

void main() {
  group('NeonPathMatcher Tests', () {
    final routes = [
      NeonRoute(
        path: '/',
        name: 'root',
        builder: (ctx, state) => const Text('Root'),
      ),
      NeonRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (ctx, state) => const Text('Dashboard'),
        children: [
          NeonRoute(
            path: 'analytics',
            name: 'analytics',
            builder: (ctx, state) => const Text('Analytics'),
          ),
          NeonRoute(
            path: 'reports/:reportId',
            name: 'report_detail',
            builder: (ctx, state) => Text('Report ${state.param("reportId")}'),
          ),
        ],
      ),
      NeonRoute(
        path: '/users/:userId',
        name: 'user_detail',
        builder: (ctx, state) => Text('User ${state.param("userId")}'),
      ),
      NeonRoute(
        path: '/files/*filepath',
        name: 'files',
        builder: (ctx, state) => Text('File: ${state.param("filepath")}'),
      ),
    ];

    final matcher = NeonPathMatcher(routes);

    test('matches root path', () {
      final match = matcher.match('/');
      expect(match, isNotNull);
      expect(match!.route.name, equals('root'));
      expect(match.matchedPattern, equals('/'));
    });

    test('matches parameterized path and extracts params', () {
      final match = matcher.match('/users/42');
      expect(match, isNotNull);
      expect(match!.route.name, equals('user_detail'));
      expect(match.pathParameters['userId'], equals('42'));
    });

    test('matches nested routes and parameterized child routes', () {
      final match1 = matcher.match('/dashboard/analytics');
      expect(match1, isNotNull);
      expect(match1!.route.name, equals('analytics'));

      final match2 = matcher.match('/dashboard/reports/rpt_99');
      expect(match2, isNotNull);
      expect(match2!.route.name, equals('report_detail'));
      expect(match2.pathParameters['reportId'], equals('rpt_99'));
    });

    test('parses query parameters', () {
      final match = matcher.match('/dashboard/analytics?period=monthly&export=pdf');
      expect(match, isNotNull);
      expect(match!.queryParameters['period'], equals('monthly'));
      expect(match.queryParameters['export'], equals('pdf'));
    });

    test('matches wildcard route and captures remaining path', () {
      final match = matcher.match('/files/documents/2026/report.pdf');
      expect(match, isNotNull);
      expect(match!.route.name, equals('files'));
      expect(match.pathParameters['filepath'], equals('documents/2026/report.pdf'));
    });

    test('returns null on unknown route', () {
      final match = matcher.match('/unknown/path/here');
      expect(match, isNull);
    });

    test('synthesizes hierarchy paths for deep link', () {
      final hierarchy = matcher.synthesizeHierarchy('/dashboard/reports/rpt_99');
      expect(hierarchy, contains('/'));
      expect(hierarchy, contains('/dashboard'));
      expect(hierarchy, contains('/dashboard/reports'));
      expect(hierarchy, contains('/dashboard/reports/rpt_99'));
    });
  });

  group('NavigatorController Stack & Operations', () {
    late NavigatorController controller;
    late List<NeonRoute> routeRegistry;

    setUp(() {
      routeRegistry = [
        NeonRoute(
          path: '/',
          builder: (ctx, state) => const Text('Home'),
        ),
        NeonRoute(
          path: '/settings',
          builder: (ctx, state) => const Text('Settings'),
        ),
        NeonRoute(
          path: '/profile',
          cachePolicy: RouteCachePolicy.keepAlive,
          builder: (ctx, state) => const Text('Profile'),
        ),
        NeonRoute(
          path: '/modal',
          builder: (ctx, state) => const Text('Modal'),
        ),
      ];

      controller = NavigatorController(
        navigatorId: 'test_nav',
        routeRegistry: routeRegistry,
      );
    });

    test('initial state has empty history and canPop is false', () {
      expect(controller.history.isEmpty, isTrue);
      expect(controller.canPop, isFalse);
    });

    test('push and pop manage stack and complete with return value', () async {
      await controller.push('/');
      expect(controller.history.length, equals(1));
      expect(controller.canPop, isFalse);

      final entry = await controller.push('/modal');
      final popFuture = entry?.onPop;
      expect(controller.history.length, equals(2));
      expect(controller.canPop, isTrue);
      expect(controller.currentEntry?.state.location, equals('/modal'));

      final popSuccess = await controller.pop<String>('confirmed_result');
      expect(popSuccess, isTrue);
      expect(controller.history.length, equals(1));
      expect(controller.canPop, isFalse);

      final returnedResult = await popFuture;
      expect(returnedResult, equals('confirmed_result'));
    });

    test('replace updates current entry without growing stack', () async {
      await controller.push('/');
      await controller.replace('/settings');

      expect(controller.history.length, equals(1));
      expect(controller.currentEntry?.state.location, equals('/settings'));
      expect(controller.canPop, isFalse);
    });

    test('popUntil trims stack back to matching predicate', () async {
      await controller.push('/');
      await controller.push('/settings');
      await controller.push('/modal');
      expect(controller.history.length, equals(3));

      controller.popUntil((entry) => entry.state.location == '/');
      expect(controller.history.length, equals(1));
      expect(controller.currentEntry?.state.location, equals('/'));
    });

    test('serializes stack to JSON cleanly', () async {
      await controller.push('/');
      await controller.push('/settings', arguments: {'source': 'drawer'});

      final json = controller.toJson();
      expect(json['navigatorId'], equals('test_nav'));
      expect(json['canPop'], equals(true));
      expect(json['activeIndex'], equals(1));
      expect((json['history'] as List).length, equals(2));
    });
  });

  group('Route Guards & Middlewares', () {
    test('canActivate allows or aborts navigation', () async {
      bool allowAccess = false;

      final routes = [
        NeonRoute(
          path: '/',
          builder: (ctx, state) => const Text('Home'),
        ),
        NeonRoute(
          path: '/admin',
          guards: [
            _TestGuard(canActivateCallback: (ctx) {
              return allowAccess
                  ? const NeonGuardResult.allow()
                  : const NeonGuardResult.abort('Unauthorized');
            }),
          ],
          builder: (ctx, state) => const Text('Admin'),
        ),
      ];

      final controller = NavigatorController(
        navigatorId: 'guarded_nav',
        routeRegistry: routes,
      );

      await controller.push('/');

      // Access denied
      final result1 = await controller.push('/admin');
      expect(result1, isNull);
      expect(controller.currentEntry?.state.location, equals('/'));

      // Access granted
      allowAccess = true;
      await controller.push('/admin');
      expect(controller.currentEntry?.state.location, equals('/admin'));
    });

    test('canActivate redirects to fallback route', () async {
      final routes = [
        NeonRoute(
          path: '/',
          builder: (ctx, state) => const Text('Home'),
        ),
        NeonRoute(
          path: '/login',
          builder: (ctx, state) => const Text('Login'),
        ),
        NeonRoute(
          path: '/account',
          guards: [
            _TestGuard(canActivateCallback: (ctx) {
              return const NeonGuardResult.redirect('/login');
            }),
          ],
          builder: (ctx, state) => const Text('Account'),
        ),
      ];

      final controller = NavigatorController(
        navigatorId: 'nav',
        routeRegistry: routes,
      );

      await controller.push('/');
      await controller.push('/account');

      expect(controller.currentEntry?.state.location, equals('/login'));
    });

    test('canDeactivate blocks popping when unsaved changes exist', () async {
      bool hasUnsavedChanges = true;

      final routes = [
        NeonRoute(
          path: '/',
          builder: (ctx, state) => const Text('Home'),
        ),
        NeonRoute(
          path: '/editor',
          guards: [
            _TestGuard(canDeactivateCallback: (ctx) {
              return hasUnsavedChanges
                  ? const NeonGuardResult.abort('Unsaved changes')
                  : const NeonGuardResult.allow();
            }),
          ],
          builder: (ctx, state) => const Text('Editor'),
        ),
      ];

      final controller = NavigatorController(
        navigatorId: 'nav',
        routeRegistry: routes,
      );

      await controller.push('/');
      await controller.push('/editor');

      // Attempt to pop while changes unsaved
      final popBlocked = await controller.pop();
      expect(popBlocked, isFalse);
      expect(controller.currentEntry?.state.location, equals('/editor'));

      // Save changes and pop succeeds
      hasUnsavedChanges = false;
      final popSucceeded = await controller.pop();
      expect(popSucceeded, isTrue);
      expect(controller.currentEntry?.state.location, equals('/'));
    });

    test('detects infinite redirect loops and throws NavigationRedirectLoopException', () async {
      final routes = [
        NeonRoute(
          path: '/loopA',
          guards: [
            _TestGuard(canActivateCallback: (ctx) => const NeonGuardResult.redirect('/loopB')),
          ],
          builder: (ctx, state) => const Text('A'),
        ),
        NeonRoute(
          path: '/loopB',
          guards: [
            _TestGuard(canActivateCallback: (ctx) => const NeonGuardResult.redirect('/loopA')),
          ],
          builder: (ctx, state) => const Text('B'),
        ),
      ];

      final controller = NavigatorController(
        navigatorId: 'nav',
        routeRegistry: routes,
      );

      expect(
        () async => await controller.push('/loopA'),
        throwsA(isA<NavigationRedirectLoopException>()),
      );
    });
  });

  group('Nested Navigator & Back Button Arbitration', () {
    test('back button bubbles from child navigator to parent', () async {
      final rootRoutes = [
        NeonRoute(
          path: '/',
          builder: (ctx, state) => const Text('RootHome'),
        ),
        NeonRoute(
          path: '/tabs',
          builder: (ctx, state) => const Text('TabsShell'),
        ),
      ];

      final tabRoutes = [
        NeonRoute(
          path: '/tab/feed',
          builder: (ctx, state) => const Text('Feed'),
        ),
        NeonRoute(
          path: '/tab/detail',
          builder: (ctx, state) => const Text('FeedDetail'),
        ),
      ];

      final rootNav = NavigatorController(
        navigatorId: 'root',
        routeRegistry: rootRoutes,
      );

      final childNav = NavigatorController(
        navigatorId: 'tab_child',
        routeRegistry: tabRoutes,
        parent: rootNav,
      );

      await rootNav.push('/');
      await rootNav.push('/tabs');

      await childNav.push('/tab/feed');
      await childNav.push('/tab/detail');

      expect(childNav.canPop, isTrue);
      expect(rootNav.canPop, isTrue);

      // 1. Back button pops child first
      final handled1 = await rootNav.handleBack();
      expect(handled1, isTrue);
      expect(childNav.currentEntry?.state.location, equals('/tab/feed'));
      expect(childNav.canPop, isFalse);

      // 2. Child cannot pop anymore, back button pops root
      final handled2 = await rootNav.handleBack();
      expect(handled2, isTrue);
      expect(rootNav.currentEntry?.state.location, equals('/'));
      expect(rootNav.canPop, isFalse);

      // 3. Root cannot pop anymore, returns false (delegates to OS)
      final handled3 = await rootNav.handleBack();
      expect(handled3, isFalse);
    });
  });

  group('NeonRouter Ingress, Signals, and State Restoration', () {
    late NeonRouter router;

    setUp(() {
      router = NeonRouter(
        routes: [
          NeonRoute(
            path: '/',
            builder: (ctx, state) => const Text('Home'),
          ),
          NeonRoute(
            path: '/login',
            builder: (ctx, state) => const Text('Login'),
          ),
          NeonRoute(
            path: '/dashboard',
            builder: (ctx, state) => const Text('Dashboard'),
          ),
          NeonRoute(
            path: '/dashboard/orders/:orderId',
            builder: (ctx, state) => Text('Order ${state.param("orderId")}'),
          ),
        ],
        initialLocation: '/',
      );
    });

    tearDown(() {
      router.dispose();
    });

    test('initializes with initialLocation', () async {
      await router.initialize();
      expect(router.rootNavigator.currentEntry?.state.location, equals('/'));
      expect(router.telemetryBreadcrumbs.isNotEmpty, isTrue);
    });

    test('deep link reconstructs synthetic backstack', () async {
      await router.initialize();
      await router.handleDeepLink('/dashboard/orders/ord_555', synthesizeBackstack: true);

      expect(router.rootNavigator.currentEntry?.state.location, equals('/dashboard/orders/ord_555'));
      expect(router.rootNavigator.history.length, greaterThan(1));

      // Popping should take us to /dashboard
      final popped = await router.pop();
      expect(popped, isTrue);
      expect(router.rootNavigator.currentEntry?.state.location, equals('/dashboard'));
    });

    test('signal-driven routing redirects automatically on signal change', () async {
      await router.initialize();

      final authSignal = NeonSignal<bool>(true);
      router.bindSignal(authSignal, redirectRule: () {
        return authSignal.value ? null : '/login';
      });

      await router.push('/dashboard');
      expect(router.rootNavigator.currentEntry?.state.location, equals('/dashboard'));

      // Trigger unauthenticated state
      authSignal.value = false;
      await Future.delayed(Duration.zero);

      expect(router.rootNavigator.currentEntry?.state.location, equals('/login'));
    });

    test('exports snapshot and restores navigation history', () async {
      await router.initialize();
      await router.push('/dashboard');
      await router.push('/dashboard/orders/ord_123', arguments: {'tracking': 'TRK_99'});

      final snapshot = router.exportSnapshot();
      expect(snapshot['restorationVersion'], equals(1));
      expect(snapshot['rootNavigator'], isNotNull);

      // Create new router and restore snapshot
      final newRouter = NeonRouter(
        routes: router.routes,
        initialLocation: '/',
      );
      await newRouter.initialize();
      await newRouter.restoreFromSnapshot(snapshot);

      expect(newRouter.rootNavigator.currentEntry?.state.location, equals('/dashboard/orders/ord_123'));
      expect(newRouter.rootNavigator.canPop, isTrue);

      await newRouter.pop();
      expect(newRouter.rootNavigator.currentEntry?.state.location, equals('/dashboard'));
      newRouter.dispose();
    });

    test('handles native bridge action events', () async {
      await router.initialize();

      // Native push action
      final pushed = await router.handleBridgeAction({
        'action': 'nav_push',
        'path': '/dashboard',
      });
      expect(pushed, isTrue);
      expect(router.rootNavigator.currentEntry?.state.location, equals('/dashboard'));

      // Native back button action
      final popped = await router.handleBridgeAction({
        'action': 'nav_pop',
      });
      expect(popped, isTrue);
      expect(router.rootNavigator.currentEntry?.state.location, equals('/'));
    });
  });
}

class _TestGuard extends NeonRouteGuard {
  final NeonGuardResult Function(NeonRouteContext context)? canActivateCallback;
  final NeonGuardResult Function(NeonRouteContext context)? canDeactivateCallback;

  const _TestGuard({
    this.canActivateCallback,
    this.canDeactivateCallback,
  });

  @override
  NeonGuardResult canActivate(NeonRouteContext context) {
    if (canActivateCallback != null) {
      return canActivateCallback!(context);
    }
    return const NeonGuardResult.allow();
  }

  @override
  NeonGuardResult canDeactivate(NeonRouteContext context) {
    if (canDeactivateCallback != null) {
      return canDeactivateCallback!(context);
    }
    return const NeonGuardResult.allow();
  }
}

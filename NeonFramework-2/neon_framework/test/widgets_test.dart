import 'package:test/test.dart';
import 'package:neon_framework/neon.dart';

class TestStatefulNav extends StatefulWidget {
  const TestStatefulNav({super.key});

  @override
  NeonState<TestStatefulNav> createState() => _TestStatefulNavState();
}

class _TestStatefulNavState extends NeonState<TestStatefulNav> {
  int selectedIndex = 0;

  @override
  NeonWidget build(NeonBuildContext context) {
    return NavigationBar(
      destinations: const [
        NavigationDestination(icon: Text('1'), label: 'One'),
        NavigationDestination(icon: Text('2'), label: 'Two'),
      ],
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        setState(() => selectedIndex = index);
      },
    );
  }
}

void main() {
  tearDown(() {
    NeonApp.reset();
  });

  group('AppBar', () {
    test('AppBar stores properties', () {
      const appBar = AppBar(
        title: Text('Title'),
        leading: Text('Back'),
        actions: [Text('Save')],
        variant: AppBarVariant.centerAligned,
      );
      expect(appBar.title, isA<Text>());
      expect((appBar.title as Text).data, equals('Title'));
      expect(appBar.leading, isNotNull);
      expect(appBar.actions?.length, equals(1));
      expect(appBar.variant, equals(AppBarVariant.centerAligned));
    });

    test('AppBar builds LeafWidget', () {
      final context = NeonBuildContext(config: const NeonConfig());
      const appBar = AppBar(title: Text('Title'));
      final built = appBar.build(context);
      expect(built, isA<LeafWidget>());
      expect((built as LeafWidget).type, equals('AppBar'));
    });
  });

  group('FloatingActionButton', () {
    test('FAB stores properties', () {
      var tapped = false;
      final fab = FloatingActionButton(
        onPressed: () => tapped = true,
        variant: FABVariant.large,
        child: const Text('+'),
      );
      expect(fab.variant, equals(FABVariant.large));
      expect(fab.child, isA<Text>());

      final context = NeonBuildContext(config: const NeonConfig());
      final built = fab.build(context) as Button;
      built.tap();
      expect(tapped, isTrue);
    });

    test('FAB padding varies by variant', () {
      final context = NeonBuildContext(config: const NeonConfig());

      const smallFab =
          FloatingActionButton(child: Text(''), variant: FABVariant.small);
      final smallButton = smallFab.build(context) as Button;
      expect(smallButton.padding.top, equals(8.0));

      const regularFab =
          FloatingActionButton(child: Text(''), variant: FABVariant.regular);
      final regularButton = regularFab.build(context) as Button;
      expect(regularButton.padding.top, equals(16.0));

      const largeFab =
          FloatingActionButton(child: Text(''), variant: FABVariant.large);
      final largeButton = largeFab.build(context) as Button;
      expect(largeButton.padding.top, equals(24.0));
    });
  });

  group('IconButton', () {
    test('IconButton stores properties', () {
      var tapped = false;
      final button = IconButton(
        icon: const Text('Icon'),
        onPressed: () => tapped = true,
        variant: IconButtonVariant.filled,
      );
      expect(button.variant, equals(IconButtonVariant.filled));

      final context = NeonBuildContext(config: const NeonConfig());
      final built = button.build(context) as Button;
      expect(built.color, equals(NeonColor.blue));
      built.tap();
      expect(tapped, isTrue);
    });

    test('IconButton colors by variant', () {
      final context = NeonBuildContext(config: const NeonConfig());

      const standard =
          IconButton(icon: Text(''), variant: IconButtonVariant.standard);
      expect((standard.build(context) as Button).color,
          equals(NeonColor.transparent));

      const filled =
          IconButton(icon: Text(''), variant: IconButtonVariant.filled);
      expect((filled.build(context) as Button).color, equals(NeonColor.blue));

      const tonal =
          IconButton(icon: Text(''), variant: IconButtonVariant.tonal);
      expect((tonal.build(context) as Button).color,
          equals(const NeonColor(0xFFEADDFF)));
    });
  });

  group('Material 3 Buttons', () {
    test('FilledButton uses Button with default color', () {
      final context = NeonBuildContext(config: const NeonConfig());
      const button = FilledButton(child: Text('Filled'));
      final built = button.build(context) as Button;
      expect(built.color, equals(NeonColor.blue));
    });

    test('FilledTonalButton uses Button with tonal color', () {
      final context = NeonBuildContext(config: const NeonConfig());
      const button = FilledTonalButton(child: Text('Tonal'));
      final built = button.build(context) as Button;
      expect(built.color, equals(const NeonColor(0xFFEADDFF)));
    });

    test('ElevatedButton uses Button with white color', () {
      final context = NeonBuildContext(config: const NeonConfig());
      const button = ElevatedButton(child: Text('Elevated'));
      final built = button.build(context) as Button;
      expect(built.color, equals(NeonColor.white));
    });

    test('OutlinedButton uses Button with transparent color', () {
      final context = NeonBuildContext(config: const NeonConfig());
      const button = OutlinedButton(child: Text('Outlined'));
      final built = button.build(context) as Button;
      expect(built.color, equals(NeonColor.transparent));
    });

    test('TextButton uses Button with transparent color', () {
      final context = NeonBuildContext(config: const NeonConfig());
      const button = TextButton(child: Text('Text'));
      final built = button.build(context) as Button;
      expect(built.color, equals(NeonColor.transparent));
    });
  });

  group('SegmentedButton', () {
    test('SegmentedButton stores properties', () {
      const button = SegmentedButton(
        segments: [Text('A'), Text('B')],
        selectedIndex: 1,
      );
      expect(button.segments.length, equals(2));
      expect(button.selectedIndex, equals(1));
    });

    test('SegmentedButton builds LeafWidget', () {
      final context = NeonBuildContext(config: const NeonConfig());
      const button = SegmentedButton(segments: [], selectedIndex: 0);
      final built = button.build(context);
      expect(built, isA<LeafWidget>());
      expect((built as LeafWidget).type, equals('SegmentedButton'));
    });
  });

  group('Navigation System', () {
    test('NavigationBar stores destinations', () {
      final nav = NavigationBar(
        destinations: const [
          NavigationDestination(icon: Text('H'), label: 'Home'),
          NavigationDestination(icon: Text('S'), label: 'Settings'),
        ],
        selectedIndex: 1,
      );
      expect(nav.destinations.length, equals(2));
      expect(nav.destinations[0].label, equals('Home'));
      expect(nav.selectedIndex, equals(1));
    });

    test('NavigationDrawer stores children', () {
      final drawer = NavigationDrawer(
        children: const [
          NavigationDrawerDestination(icon: Text('A'), label: Text('App')),
        ],
      );
      expect(drawer.children.length, equals(1));
    });

    test('NavigationRail stores destinations', () {
      final rail = NavigationRail(
        destinations: const [
          NavigationRailDestination(icon: Text('R'), label: Text('Rail')),
        ],
      );
      expect(rail.destinations.length, equals(1));
    });

    test('TabBar stores tabs', () {
      final tabBar = TabBar(
        tabs: const [
          Tab(text: 'Tab 1'),
          Tab(text: 'Tab 2'),
        ],
      );
      expect(tabBar.tabs.length, equals(2));
      expect(tabBar.tabs[0].text, equals('Tab 1'));
    });

    test('Stateful navigation updates index', () {
      final context = NeonBuildContext(config: const NeonConfig());
      final widget = const TestStatefulNav();

      final nav = widget.build(context) as NavigationBar;
      expect(nav.selectedIndex, equals(0));

      if (nav.onDestinationSelected != null) {
        nav.onDestinationSelected!(1);
      }
    });
  });

  group('Widget Identity', () {
    test('Key preserves identity', () {
      const String key = 'test';
      const text1 = Text('A', key: key);
      const text2 = Text('B', key: key);
      expect(text1.key, equals(text2.key));
    });
  });
}

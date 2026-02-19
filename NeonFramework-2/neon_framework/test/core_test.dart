import 'package:test/test.dart';
import 'package:neon_framework/neon.dart';

// Tooling imports for testing
import '../tool/tooling/hot_reload.dart';
import '../tool/tooling/neon_project.dart';
import '../tool/tooling/project_template.dart';
import '../tool/tooling/cli.dart';

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  NeonWidget build(NeonBuildContext context) {
    return const Text('Hello');
  }
}

class TestStatefulWidget extends StatefulWidget {
  const TestStatefulWidget({super.key});

  @override
  NeonState<TestStatefulWidget> createState() => _TestState();
}

class _TestState extends NeonState<TestStatefulWidget> {
  int counter = 0;
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    initialized = true;
  }

  @override
  NeonWidget build(NeonBuildContext context) {
    return Text('Counter: $counter');
  }
}

class TestLifecycleObserver extends NeonLifecycleObserver {
  final List<String> events = [];

  @override
  void onInit() => events.add('init');
  @override
  void onPause() => events.add('pause');
  @override
  void onResume() => events.add('resume');
  @override
  void onDispose() => events.add('dispose');
  @override
  void onHotReload() => events.add('hotReload');
}

void main() {
  tearDown(() {
    NeonApp.reset();
  });

  group('NeonApp', () {
    test('run initializes app and sets instance', () {
      NeonApp.run(const TestApp());
      expect(NeonApp.instance.isRunning, isTrue);
    });

    test('run with custom config', () {
      final config = NeonConfig(
        environment: NeonEnvironment.production,
        buildFlavor: const NeonBuildFlavor(name: 'premium'),
        featureFlags: const NeonFeatureFlags({'dark_mode': true}),
      );
      NeonApp.run(const TestApp(), config: config);
      expect(NeonApp.instance.config.isProd, isTrue);
      expect(NeonApp.instance.config.buildFlavor?.name, equals('premium'));
      expect(
          NeonApp.instance.config.featureFlags.isEnabled('dark_mode'), isTrue);
    });

    test('throws if run called twice', () {
      NeonApp.run(const TestApp());
      expect(() => NeonApp.run(const TestApp()), throwsStateError);
    });

    test('throws if instance accessed before run', () {
      expect(() => NeonApp.instance, throwsStateError);
    });

    test('dispose cleans up', () {
      NeonApp.run(const TestApp());
      NeonApp.instance.dispose();
      expect(() => NeonApp.instance, throwsStateError);
    });

    test('builds widget tree on run', () {
      NeonApp.run(const TestApp());
      expect(NeonApp.instance.widgetTree.root, isNotNull);
      expect(NeonApp.instance.widgetTree.nodeCount, greaterThan(0));
    });
  });

  group('NeonLifecycleManager', () {
    test('full lifecycle flow', () {
      final manager = NeonLifecycleManager();
      final observer = TestLifecycleObserver();
      manager.addObserver(observer);
      manager.init();
      manager.markRunning();
      manager.pause();
      manager.resume();
      manager.hotReload();
      manager.dispose();
      expect(observer.events,
          equals(['init', 'pause', 'resume', 'hotReload', 'dispose']));
    });

    test('pause only works from running or resumed state', () {
      final manager = NeonLifecycleManager();
      final observer = TestLifecycleObserver();
      manager.addObserver(observer);
      manager.pause();
      expect(observer.events, isEmpty);
      manager.init();
      manager.markRunning();
      manager.pause();
      expect(observer.events, contains('pause'));
    });

    test('resume only works from paused state', () {
      final manager = NeonLifecycleManager();
      final observer = TestLifecycleObserver();
      manager.addObserver(observer);
      manager.resume();
      expect(observer.events, isEmpty);
      manager.init();
      manager.markRunning();
      manager.pause();
      manager.resume();
      expect(observer.events, contains('resume'));
    });

    test('remove observer stops notifications', () {
      final manager = NeonLifecycleManager();
      final observer = TestLifecycleObserver();
      manager.addObserver(observer);
      manager.removeObserver(observer);
      manager.init();
      expect(observer.events, isEmpty);
    });
  });

  group('NeonErrorHandler', () {
    test('dev mode throws errors', () {
      final handler =
          NeonErrorHandler(environment: NeonEnvironment.development);
      expect(
        () => handler.handleError(Exception('test'), StackTrace.current),
        throwsA(isA<Exception>()),
      );
      expect(handler.errorLog.length, equals(1));
    });

    test('prod mode logs but does not throw', () {
      final handler = NeonErrorHandler(environment: NeonEnvironment.production);
      handler.handleError(Exception('test'), StackTrace.current);
      expect(handler.errorLog.length, equals(1));
    });

    test('staging mode logs but does not throw', () {
      final handler = NeonErrorHandler(environment: NeonEnvironment.staging);
      handler.handleError(Exception('test'), StackTrace.current);
      expect(handler.errorLog.length, equals(1));
    });

    test('custom handler overrides default behavior', () {
      final handler =
          NeonErrorHandler(environment: NeonEnvironment.development);
      final captured = <Object>[];
      handler.setCustomHandler((error, st) => captured.add(error));
      handler.handleError(Exception('custom'), StackTrace.current);
      expect(captured.length, equals(1));
      expect(handler.errorLog.length, equals(1));
    });

    test('clearLog removes all records', () {
      final handler = NeonErrorHandler(environment: NeonEnvironment.production);
      handler.handleError(Exception('a'), StackTrace.current);
      handler.handleError(Exception('b'), StackTrace.current);
      expect(handler.errorLog.length, equals(2));
      handler.clearLog();
      expect(handler.errorLog.length, equals(0));
    });
  });

  group('NeonConfig', () {
    test('default config is development', () {
      const config = NeonConfig();
      expect(config.isDev, isTrue);
      expect(config.isProd, isFalse);
    });

    test('copyWith creates modified copy', () {
      const config = NeonConfig();
      final updated = config.copyWith(
        environment: NeonEnvironment.production,
        buildFlavor: const NeonBuildFlavor(name: 'paid'),
      );
      expect(updated.isProd, isTrue);
      expect(updated.buildFlavor?.name, equals('paid'));
    });
  });

  group('NeonFeatureFlags', () {
    test('isEnabled returns false for missing flags', () {
      const flags = NeonFeatureFlags();
      expect(flags.isEnabled('nonexistent'), isFalse);
    });

    test('copyWith merges flags', () {
      const flags = NeonFeatureFlags({'a': true, 'b': false});
      final updated = flags.copyWith({'b': true, 'c': true});
      expect(updated.isEnabled('a'), isTrue);
      expect(updated.isEnabled('b'), isTrue);
      expect(updated.isEnabled('c'), isTrue);
    });
  });

  group('NeonBuildFlavor', () {
    test('config access via bracket operator', () {
      const flavor = NeonBuildFlavor(
          name: 'free', config: {'ads': true, 'premium': false});
      expect(flavor['ads'], isTrue);
      expect(flavor['premium'], isFalse);
      expect(flavor['missing'], isNull);
    });
  });

  group('Widget System', () {
    test('Text widget stores data and style', () {
      const text = Text('Hello',
          style: NeonTextStyle(fontSize: 20.0, color: NeonColor.red));
      expect(text.data, equals('Hello'));
      expect(text.style.fontSize, equals(20.0));
      expect(text.style.color, equals(NeonColor.red));
    });

    test('Button tap calls onPressed when enabled', () {
      var tapped = false;
      final button =
          Button(onPressed: () => tapped = true, child: const Text('Tap'));
      button.tap();
      expect(tapped, isTrue);
    });

    test('Button tap does nothing when disabled', () {
      var tapped = false;
      final button = Button(
          onPressed: () => tapped = true,
          enabled: false,
          child: const Text('Tap'));
      button.tap();
      expect(tapped, isFalse);
    });

    test('Container stores properties', () {
      const container =
          Container(width: 100, height: 50, color: NeonColor.blue);
      expect(container.width, equals(100));
      expect(container.height, equals(50));
      expect(container.color, equals(NeonColor.blue));
    });

    test('Column holds children', () {
      const col = Column(children: [Text('A'), Text('B'), Text('C')]);
      expect(col.children.length, equals(3));
    });

    test('Row holds children', () {
      const row = Row(children: [Text('A'), Text('B')]);
      expect(row.children.length, equals(2));
    });

    test('Stack holds children', () {
      const stack = Stack(children: [Text('Layer 1'), Text('Layer 2')]);
      expect(stack.children.length, equals(2));
      expect(stack.fit, equals(StackFit.loose));
    });

    test('StatelessWidget builds correctly', () {
      final context = NeonBuildContext(config: const NeonConfig());
      const app = TestApp();
      final built = app.build(context);
      expect(built, isA<Text>());
    });

    test('StatefulWidget creates state and initializes', () {
      final context = NeonBuildContext(config: const NeonConfig());
      const widget = TestStatefulWidget();
      final built = widget.build(context);
      expect(built, isA<Text>());
    });

    test('NeonState setState throws when disposed', () {
      final state = _TestState();
      state.dispose();
      expect(() => state.setState(() {}), throwsStateError);
    });
  });

  group('NeonBuildContext', () {
    test('provide and find ancestor', () {
      final context = NeonBuildContext(config: const NeonConfig());
      context.provide<String>('theme-dark');
      expect(context.findAncestor<String>(), equals('theme-dark'));
    });

    test('child inherits from parent', () {
      final parent = NeonBuildContext(config: const NeonConfig());
      parent.provide<String>('inherited-value');
      final child = parent.createChild();
      expect(child.findAncestor<String>(), equals('inherited-value'));
    });

    test('child can override parent values', () {
      final parent = NeonBuildContext(config: const NeonConfig());
      parent.provide<String>('parent-value');
      final child = parent.createChild();
      child.provide<String>('child-value');
      expect(child.findAncestor<String>(), equals('child-value'));
    });
  });

  group('NeonWidgetTree', () {
    test('builds tree from root widget', () {
      final tree = NeonWidgetTree();
      final context = NeonBuildContext(config: const NeonConfig());
      tree.buildTree(const TestApp(), context);
      expect(tree.root, isNotNull);
      expect(tree.nodeCount, greaterThan(0));
    });

    test('builds tree with nested widgets', () {
      final tree = NeonWidgetTree();
      final context = NeonBuildContext(config: const NeonConfig());
      const widget = Column(children: [
        Text('A'),
        Text('B'),
        Row(children: [Text('C'), Text('D')])
      ]);
      tree.buildTree(widget, context);
      expect(tree.nodeCount, greaterThanOrEqualTo(5));
    });

    test('element tree reflects built widgets correctly', () {
      final tree = NeonWidgetTree();
      final context = NeonBuildContext(config: const NeonConfig());
      final button = Button(onPressed: () {}, child: const Text('Tap'));
      tree.buildTree(button, context);
      final root = tree.root!;
      expect(root.sourceWidget, isA<Button>());
      expect(root.widget, isA<Container>());
      expect(root.children.length, equals(1));
    });

    test('parent references are correct', () {
      final tree = NeonWidgetTree();
      final context = NeonBuildContext(config: const NeonConfig());
      const widget = Column(children: [Text('A'), Text('B')]);
      tree.buildTree(widget, context);
      final root = tree.root!;
      expect(root.parent, isNull);
      for (final child in root.children) {
        expect(child.parent, equals(root));
      }
    });

    test('depth is calculated correctly', () {
      final tree = NeonWidgetTree();
      final context = NeonBuildContext(config: const NeonConfig());
      const widget = Column(children: [Container(child: Text('Deep'))]);
      tree.buildTree(widget, context);
      final root = tree.root!;
      expect(root.depth, equals(0));
      expect(root.children.first.depth, equals(1));
      expect(root.children.first.children.first.depth, equals(2));
    });

    test('stateful widget state persists across rebuilds', () {
      final tree = NeonWidgetTree();
      final context = NeonBuildContext(config: const NeonConfig());
      const widget = TestStatefulWidget(key: 'counter');
      tree.buildTree(widget, context);
      final stateBeforeRebuild = tree.stateRegistry['counter'];
      expect(stateBeforeRebuild, isNotNull);
      tree.buildTree(widget, context);
      final stateAfterRebuild = tree.stateRegistry['counter'];
      expect(identical(stateBeforeRebuild, stateAfterRebuild), isTrue);
    });

    test('disposeStates clears all state', () {
      final tree = NeonWidgetTree();
      final context = NeonBuildContext(config: const NeonConfig());
      const widget = TestStatefulWidget(key: 'counter');
      tree.buildTree(widget, context);
      expect(tree.stateRegistry.isNotEmpty, isTrue);
      tree.disposeStates();
      expect(tree.stateRegistry.isEmpty, isTrue);
    });
  });

  group('NeonEdgeInsets', () {
    test('all constructor', () {
      const insets = NeonEdgeInsets.all(10);
      expect(insets.top, equals(10));
      expect(insets.right, equals(10));
      expect(insets.bottom, equals(10));
      expect(insets.left, equals(10));
    });

    test('symmetric constructor', () {
      const insets = NeonEdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0);
      expect(insets.top, equals(8.0));
      expect(insets.bottom, equals(8.0));
      expect(insets.left, equals(16.0));
      expect(insets.right, equals(16.0));
    });

    test('only constructor', () {
      const insets = NeonEdgeInsets.only(top: 5, left: 10);
      expect(insets.top, equals(5));
      expect(insets.left, equals(10));
      expect(insets.right, equals(0));
      expect(insets.bottom, equals(0));
    });
  });

  group('NeonColor', () {
    test('equality', () {
      expect(NeonColor.blue, equals(const NeonColor(0xFF0000FF)));
      expect(NeonColor.red, isNot(equals(NeonColor.blue)));
    });

    test('predefined colors', () {
      expect(NeonColor.black.value, equals(0xFF000000));
      expect(NeonColor.white.value, equals(0xFFFFFFFF));
      expect(NeonColor.transparent.value, equals(0x00000000));
    });
  });

  group('Constraints', () {
    test('NeonSize constrain', () {
      const size = NeonSize(500, 300);
      final constrained =
          size.constrain(const NeonConstraints(maxWidth: 200, maxHeight: 100));
      expect(constrained.width, equals(200));
      expect(constrained.height, equals(100));
    });

    test('NeonConstraints tight', () {
      final tight = NeonConstraints.tight(const NeonSize(100, 50));
      expect(tight.isTight, isTrue);
      expect(tight.minWidth, equals(100));
      expect(tight.maxWidth, equals(100));
    });

    test('NeonConstraints loose', () {
      final loose = NeonConstraints.loose(const NeonSize(100, 50));
      expect(loose.minWidth, equals(0));
      expect(loose.maxWidth, equals(100));
    });

    test('NeonConstraints loosen', () {
      final c = NeonConstraints.tight(const NeonSize(100, 50));
      final loosened = c.loosen();
      expect(loosened.minWidth, equals(0));
      expect(loosened.maxWidth, equals(100));
    });

    test('NeonOffset arithmetic', () {
      const a = NeonOffset(10, 20);
      const b = NeonOffset(5, 10);
      expect(a + b, equals(const NeonOffset(15, 30)));
      expect(a - b, equals(const NeonOffset(5, 10)));
    });

    test('NeonRect contains', () {
      const rect = NeonRect(10, 10, 100, 50);
      expect(rect.contains(const NeonOffset(50, 30)), isTrue);
      expect(rect.contains(const NeonOffset(0, 0)), isFalse);
    });

    test('NeonRect from offset', () {
      final rect = NeonRect.fromOffset(
          const NeonOffset(10, 20), const NeonSize(100, 50));
      expect(rect.left, equals(10));
      expect(rect.top, equals(20));
      expect(rect.width, equals(100));
      expect(rect.right, equals(110));
    });
  });

  group('Render Pipeline', () {
    test('RenderText layout and paint', () {
      final render =
          RenderText(text: 'Hello', style: const NeonTextStyle(fontSize: 16.0));
      render.layout(const NeonConstraints(maxWidth: 200, maxHeight: 100));
      expect(render.size.width, greaterThan(0));
      expect(render.size.height, greaterThan(0));

      final canvas = NeonCanvas();
      render.paint(canvas);
      expect(canvas.commandCount, equals(4));
      final drawTextCmds = canvas.commands
          .where((c) => c.type == NeonPaintCommandType.drawText)
          .toList();
      expect(drawTextCmds.length, equals(1));
    });

    test('RenderContainer layout with child', () {
      final container = RenderContainer(
        fixedWidth: 200,
        fixedHeight: 100,
        color: NeonColor.blue,
        padding: const NeonEdgeInsets.all(10),
      );
      final child = RenderText(text: 'Child');
      container.addChild(child);
      container.layout(const NeonConstraints(maxWidth: 300, maxHeight: 300));
      expect(container.size, equals(const NeonSize(200, 100)));

      final canvas = NeonCanvas();
      container.paint(canvas);
      expect(canvas.commandCount, greaterThan(0));
    });

    test('RenderColumn layout positions children vertically', () {
      final column = RenderColumn();
      column.addChild(
          RenderText(text: 'A', style: const NeonTextStyle(fontSize: 16)));
      column.addChild(
          RenderText(text: 'B', style: const NeonTextStyle(fontSize: 16)));
      column.layout(const NeonConstraints(maxWidth: 200, maxHeight: 400));

      expect(column.children.length, equals(2));
      expect(column.children[1].relativeOffset.dy,
          greaterThan(column.children[0].relativeOffset.dy));
    });

    test('RenderRow layout positions children horizontally', () {
      final row = RenderRow();
      row.addChild(
          RenderText(text: 'A', style: const NeonTextStyle(fontSize: 16)));
      row.addChild(
          RenderText(text: 'B', style: const NeonTextStyle(fontSize: 16)));
      row.layout(const NeonConstraints(maxWidth: 400, maxHeight: 200));

      expect(row.children.length, equals(2));
      expect(row.children[1].relativeOffset.dx,
          greaterThan(row.children[0].relativeOffset.dx));
    });

    test('RenderStack layout overlaps children', () {
      final stack = RenderStack();
      stack.addChild(RenderText(text: 'Layer 1'));
      stack.addChild(RenderText(text: 'Layer 2'));
      stack.layout(const NeonConstraints(maxWidth: 200, maxHeight: 200));

      expect(stack.children[0].relativeOffset,
          equals(stack.children[1].relativeOffset));
    });

    test('nested absolute offsets are computed correctly', () {
      final column = RenderColumn();
      column.relativeOffset = const NeonOffset(10, 20);

      final container = RenderContainer(
          fixedWidth: 100, fixedHeight: 50, color: NeonColor.blue);
      final text = RenderText(text: 'Hi');
      container.addChild(text);
      column.addChild(container);

      column.layout(const NeonConstraints(maxWidth: 200, maxHeight: 400));

      expect(container.absoluteOffset.dx, greaterThanOrEqualTo(10));
      expect(container.absoluteOffset.dy, greaterThanOrEqualTo(20));
      expect(text.absoluteOffset.dx,
          greaterThanOrEqualTo(container.absoluteOffset.dx));
    });

    test('full pipeline from widget tree to paint commands', () {
      final tree = NeonWidgetTree();
      final context = NeonBuildContext(config: const NeonConfig());
      const widget = Column(children: [
        Text('Hello', style: NeonTextStyle(fontSize: 20)),
        Container(width: 100, height: 50, color: NeonColor.red),
      ]);
      tree.buildTree(widget, context);

      final pipeline = NeonRenderPipeline();
      pipeline.buildRenderTree(tree.root!);
      final canvas = pipeline.runPipeline(
        NeonConstraints.tight(const NeonSize(360, 800)),
      );

      expect(canvas.commandCount, greaterThan(0));
      expect(pipeline.rootRenderObject, isNotNull);
    });

    test('hit testing finds correct target', () {
      final container = RenderContainer(
          fixedWidth: 100, fixedHeight: 100, color: NeonColor.blue);
      container.layout(const NeonConstraints(maxWidth: 200, maxHeight: 200));
      expect(container.hitTest(const NeonOffset(50, 50)), isTrue);
      expect(container.hitTest(const NeonOffset(150, 150)), isFalse);
    });
  });

  group('NeonCanvas', () {
    test('drawRect creates command', () {
      final canvas = NeonCanvas();
      canvas.drawRect(const NeonRect(0, 0, 100, 50), color: NeonColor.red);
      expect(canvas.commandCount, equals(1));
      expect(canvas.commands.first.type, equals(NeonPaintCommandType.drawRect));
    });

    test('drawText creates command', () {
      final canvas = NeonCanvas();
      canvas.drawText('Hello', const NeonOffset(10, 20));
      expect(canvas.commandCount, equals(1));
      expect(canvas.commands.first.type, equals(NeonPaintCommandType.drawText));
    });

    test('drawCircle creates command', () {
      final canvas = NeonCanvas();
      canvas.drawCircle(const NeonOffset(50, 50), 25);
      expect(canvas.commandCount, equals(1));
      expect(
          canvas.commands.first.type, equals(NeonPaintCommandType.drawCircle));
    });

    test('device pixel ratio scales physical coordinates', () {
      final canvas = NeonCanvas(
        deviceInfo: const NeonDeviceInfo(devicePixelRatio: 3.0),
      );
      canvas.drawRect(const NeonRect(10, 10, 100, 50));
      final physRect = canvas.commands.first.params['physicalRect'] as NeonRect;
      expect(physRect.left, equals(30));
      expect(physRect.width, equals(300));
    });

    test('save and restore commands', () {
      final canvas = NeonCanvas();
      canvas.save();
      canvas.drawRect(const NeonRect(0, 0, 50, 50));
      canvas.restore();
      expect(canvas.commandCount, equals(3));
    });

    test('clear removes all commands', () {
      final canvas = NeonCanvas();
      canvas.drawRect(const NeonRect(0, 0, 50, 50));
      canvas.drawText('test', NeonOffset.zero);
      expect(canvas.commandCount, equals(2));
      canvas.clear();
      expect(canvas.commandCount, equals(0));
    });
  });

  group('Animation Foundation', () {
    test('NeonAnimationValue tracks progress', () {
      const anim = NeonAnimationValue<double>(begin: 0, end: 100);
      expect(anim.isAtStart, isTrue);
      expect(anim.isComplete, isFalse);

      final mid = anim.withProgress(0.5);
      expect(mid.progress, equals(0.5));

      final done = anim.withProgress(1.0);
      expect(done.isComplete, isTrue);
    });

    test('NeonAnimationValue clamps progress', () {
      const anim = NeonAnimationValue<double>(begin: 0, end: 100);
      final clamped = anim.withProgress(1.5);
      expect(clamped.progress, equals(1.0));

      final clampedLow = anim.withProgress(-0.5);
      expect(clampedLow.progress, equals(0.0));
    });

    test('NeonCurves produce correct values', () {
      expect(NeonCurves.linear.transform(0.5), equals(0.5));
      expect(NeonCurves.easeIn.transform(0.0), equals(0.0));
      expect(NeonCurves.easeIn.transform(1.0), equals(1.0));
      expect(NeonCurves.easeOut.transform(0.0), equals(0.0));
      expect(NeonCurves.easeOut.transform(1.0), equals(1.0));
      expect(NeonCurves.easeInOut.transform(0.0), equals(0.0));
      expect(NeonCurves.easeInOut.transform(1.0), equals(1.0));
    });

    test('NeonDuration constants', () {
      expect(NeonDuration.fast.milliseconds, equals(150));
      expect(NeonDuration.normal.milliseconds, equals(300));
      expect(NeonDuration.slow.milliseconds, equals(500));
    });
  });

  group('NeonDeviceInfo', () {
    test('default values', () {
      const info = NeonDeviceInfo();
      expect(info.devicePixelRatio, equals(1.0));
      expect(info.screenSize, equals(const NeonSize(360, 800)));
    });

    test('logical size matches screen size', () {
      const info = NeonDeviceInfo(screenSize: NeonSize(414, 896));
      expect(info.logicalSize, equals(const NeonSize(414, 896)));
    });
  });

  group('NeonSignal', () {
    test('holds initial value', () {
      final signal = NeonSignal<int>(42);
      expect(signal.value, equals(42));
      expect(signal.peek(), equals(42));
    });

    test('updates value and notifies listeners', () {
      final signal = NeonSignal<int>(0);
      final log = <int>[];
      signal.listen(() => log.add(signal.peek()));

      signal.value = 1;
      signal.value = 2;
      signal.value = 3;

      expect(log, equals([1, 2, 3]));
    });

    test('does not notify when value is identical', () {
      final signal = NeonSignal<int>(5);
      var callCount = 0;
      signal.listen(() => callCount++);

      signal.value = 5;
      expect(callCount, equals(0));
    });

    test('update with function', () {
      final signal = NeonSignal<int>(10);
      signal.update((v) => v + 5);
      expect(signal.value, equals(15));
    });

    test('removeListener stops notifications', () {
      final signal = NeonSignal<int>(0);
      var called = false;
      void listener() => called = true;

      signal.listen(listener);
      signal.removeListener(listener);
      signal.value = 1;

      expect(called, isFalse);
    });

    test('dispose prevents further updates', () {
      final signal = NeonSignal<int>(0);
      signal.dispose();
      expect(signal.isDisposed, isTrue);
      expect(() => signal.value = 1, throwsStateError);
    });

    test('listenerCount tracks listeners', () {
      final signal = NeonSignal<int>(0);
      expect(signal.listenerCount, equals(0));
      void l1() {}
      void l2() {}
      signal.listen(l1);
      signal.listen(l2);
      expect(signal.listenerCount, equals(2));
      signal.removeListener(l1);
      expect(signal.listenerCount, equals(1));
    });

    test('toString shows type and value', () {
      final signal = NeonSignal<String>('hello');
      expect(signal.toString(), equals('NeonSignal<String>(hello)'));
    });
  });

  group('NeonComputed', () {
    test('computes initial value', () {
      final a = NeonSignal<int>(2);
      final b = NeonSignal<int>(3);
      final sum = NeonComputed<int>(() => a.value + b.value);

      expect(sum.value, equals(5));
    });

    test('recomputes when dependency changes', () {
      final count = NeonSignal<int>(1);
      final doubled = NeonComputed<int>(() => count.value * 2);

      expect(doubled.value, equals(2));
      count.value = 5;
      expect(doubled.value, equals(10));
    });

    test('notifies listeners on change', () {
      final signal = NeonSignal<int>(0);
      final computed = NeonComputed<int>(() => signal.value * 10);
      final log = <int>[];
      computed.listen(() => log.add(computed.peek()));

      signal.value = 1;
      signal.value = 2;

      expect(log, equals([10, 20]));
    });

    test('peek returns cached value without tracking', () {
      final signal = NeonSignal<int>(7);
      final computed = NeonComputed<int>(() => signal.value + 1);
      expect(computed.peek(), equals(8));
    });

    test('chained computeds work', () {
      final base = NeonSignal<int>(1);
      final doubled = NeonComputed<int>(() => base.value * 2);
      final quadrupled = NeonComputed<int>(() => doubled.value * 2);

      expect(quadrupled.value, equals(4));
      base.value = 3;
      expect(quadrupled.value, equals(12));
    });

    test('nested computed with dynamic dependencies updates correctly', () {
      final toggle = NeonSignal<bool>(true);
      final a = NeonSignal<int>(1);
      final b = NeonSignal<int>(2);
      final inner = NeonComputed<int>(() => toggle.value ? a.value : b.value);
      final outer = NeonComputed<int>(() => inner.value * 10);

      expect(outer.value, equals(10));

      toggle.value = false;
      expect(outer.value, equals(20));

      b.value = 5;
      expect(outer.value, equals(50));

      a.value = 99;
      expect(outer.value, equals(50));
    });

    test('effect tracking nested computed updates', () {
      final base = NeonSignal<int>(1);
      final computed = NeonComputed<int>(() => base.value + 10);
      final log = <int>[];

      final effect = NeonEffect(() {
        log.add(computed.value);
      });

      expect(log, equals([11]));

      base.value = 5;
      expect(log, equals([11, 15]));

      effect.dispose();
    });

    test('dispose cleans up dependencies', () {
      final signal = NeonSignal<int>(0);
      final computed = NeonComputed<int>(() => signal.value + 1);
      computed.dispose();
      expect(computed.isDisposed, isTrue);
    });
  });

  group('NeonEffect', () {
    test('runs immediately on creation', () {
      final signal = NeonSignal<int>(5);
      final log = <int>[];
      NeonEffect(() => log.add(signal.value));
      expect(log, equals([5]));
    });

    test('re-runs when dependencies change', () {
      final signal = NeonSignal<String>('a');
      final log = <String>[];
      NeonEffect(() => log.add(signal.value));

      signal.value = 'b';
      signal.value = 'c';

      expect(log, equals(['a', 'b', 'c']));
    });

    test('tracks dynamic dependencies', () {
      final toggle = NeonSignal<bool>(true);
      final a = NeonSignal<int>(1);
      final b = NeonSignal<int>(2);
      final log = <int>[];

      NeonEffect(() {
        if (toggle.value) {
          log.add(a.value);
        } else {
          log.add(b.value);
        }
      });

      expect(log, equals([1]));

      toggle.value = false;
      expect(log, equals([1, 2]));

      a.value = 99;
      expect(log.length, equals(2));

      b.value = 50;
      expect(log, equals([1, 2, 50]));
    });

    test('dispose stops effect', () {
      final signal = NeonSignal<int>(0);
      final log = <int>[];
      final effect = NeonEffect(() => log.add(signal.value));

      signal.value = 1;
      effect.dispose();
      signal.value = 2;

      expect(log, equals([0, 1]));
      expect(effect.isDisposed, isTrue);
    });
  });

  group('NeonAsyncValue', () {
    test('loading state', () {
      const v = NeonAsyncValue<int>.loading();
      expect(v.isLoading, isTrue);
      expect(v.hasData, isFalse);
      expect(() => v.data, throwsStateError);
    });

    test('success state', () {
      const v = NeonAsyncValue<String>.success('hello');
      expect(v.isSuccess, isTrue);
      expect(v.data, equals('hello'));
      expect(v.hasData, isTrue);
    });

    test('error state', () {
      final v = NeonAsyncValue<int>.error('oops');
      expect(v.isError, isTrue);
      expect(v.error, equals('oops'));
      expect(v.hasError, isTrue);
    });

    test('cached state', () {
      const v = NeonAsyncValue<int>.cached(42, isRefreshing: true);
      expect(v.isCached, isTrue);
      expect(v.data, equals(42));
      expect(v.isRefreshing, isTrue);
    });

    test('when pattern matching', () {
      const loading = NeonAsyncValue<int>.loading();
      const success = NeonAsyncValue<int>.success(10);
      final error = NeonAsyncValue<int>.error('fail');

      expect(
        loading.when(
          loading: () => 'loading',
          success: (d) => 'success',
          error: (e, st) => 'error',
        ),
        equals('loading'),
      );

      expect(
        success.when(
          loading: () => 'loading',
          success: (d) => 'got $d',
          error: (e, st) => 'error',
        ),
        equals('got 10'),
      );

      expect(
        error.when(
          loading: () => 'loading',
          success: (d) => 'success',
          error: (e, st) => 'err: $e',
        ),
        equals('err: fail'),
      );
    });

    test('maybeWhen with orElse', () {
      const v = NeonAsyncValue<int>.success(5);
      final result = v.maybeWhen(
        success: (d) => 'got $d',
        orElse: () => 'other',
      );
      expect(result, equals('got 5'));

      const loading = NeonAsyncValue<int>.loading();
      final result2 = loading.maybeWhen(
        success: (d) => 'got $d',
        orElse: () => 'other',
      );
      expect(result2, equals('other'));
    });

    test('copyWith preserves fields', () {
      const v = NeonAsyncValue<int>.success(10);
      final updated =
          v.copyWith(status: NeonAsyncStatus.cached, isRefreshing: true);
      expect(updated.isCached, isTrue);
      expect(updated.data, equals(10));
      expect(updated.isRefreshing, isTrue);
    });

    test('toString formats correctly', () {
      const v = NeonAsyncValue<int>.success(42);
      expect(v.toString(), contains('success'));
      expect(v.toString(), contains('42'));
    });
  });

  group('SignalMixin', () {
    test('provides signal through context', () {
      final signal = NeonSignal<int>(10);
      final context = NeonBuildContext(config: const NeonConfig());
      final provider = NeonSignalProvider(signal: signal);
      provider.provideToContext(context);

      final found = NeonSignalProvider.of<int>(context);
      expect(found, isNotNull);
      expect(found!.value, equals(10));
    });

    test('child context inherits signal', () {
      final signal = NeonSignal<String>('theme');
      final parent = NeonBuildContext(config: const NeonConfig());
      NeonSignalProvider(signal: signal).provideToContext(parent);

      final child = parent.createChild();
      final found = NeonSignalProvider.of<String>(child);
      expect(found, isNotNull);
      expect(found!.value, equals('theme'));
    });
  });

  group('NeonPlatformChannel', () {
    test('creates channel with name and codec', () {
      final channel = NeonPlatformChannel(name: 'test/channel');
      expect(channel.name, equals('test/channel'));
      expect(channel.codec, equals(NeonChannelCodec.standard));
      expect(channel.isOpen, isTrue);
    });

    test('invokeMethod logs message', () async {
      final channel = NeonPlatformChannel(name: 'test/channel');
      NeonPlatformDispatcher.instance.registerChannel(channel);

      await channel.invokeMethod('doSomething', {'key': 'value'});

      expect(channel.messageLog.length, equals(1));
      expect(channel.messageLog.first.method, equals('doSomething'));
      expect(channel.messageLog.first.direction,
          equals(NeonMessageDirection.dartToNative));

      NeonPlatformDispatcher.reset();
    });

    test('handlePlatformMessage triggers handler', () async {
      final channel = NeonPlatformChannel(name: 'test/channel');
      String? receivedMethod;
      channel.setMessageHandler((method, args) async {
        receivedMethod = method;
        return 'handled';
      });

      final result = await channel.handlePlatformMessage('nativeCall', null);

      expect(receivedMethod, equals('nativeCall'));
      expect(result, equals('handled'));
      expect(channel.messageLog.length, equals(1));
      expect(channel.messageLog.first.direction,
          equals(NeonMessageDirection.nativeToDart));
    });

    test('incoming stream emits messages', () async {
      final channel = NeonPlatformChannel(name: 'test/channel');
      final messages = <NeonChannelMessage>[];
      channel.incoming.listen(messages.add);

      await channel.handlePlatformMessage('event1', null);
      await channel.handlePlatformMessage('event2', null);

      await Future<void>.delayed(Duration.zero);

      expect(messages.length, equals(2));
      expect(messages[0].method, equals('event1'));
      expect(messages[1].method, equals('event2'));

      channel.close();
    });

    test('close prevents further invocations', () {
      final channel = NeonPlatformChannel(name: 'test/channel');
      channel.close();
      expect(channel.isOpen, isFalse);
      expect(() => channel.invokeMethod('test'), throwsStateError);
    });

    test('mock dispatcher intercepts messages', () async {
      final channel = NeonPlatformChannel(name: 'test/mock');
      final dispatcher = NeonPlatformDispatcher.instance;
      dispatcher.registerChannel(channel);

      dispatcher.setMockDispatcher((message) async {
        if (message.method == 'getVersion') return '1.0.0';
        return null;
      });

      final result = await channel.invokeMethod<String>('getVersion');
      expect(result, equals('1.0.0'));

      NeonPlatformDispatcher.reset();
    });
  });

  group('NeonPlatformDispatcher', () {
    test('register and retrieve channel', () {
      final dispatcher = NeonPlatformDispatcher.instance;
      final channel = NeonPlatformChannel(name: 'test/reg');
      dispatcher.registerChannel(channel);

      expect(dispatcher.getChannel('test/reg'), equals(channel));

      dispatcher.unregisterChannel('test/reg');
      expect(dispatcher.getChannel('test/reg'), isNull);

      NeonPlatformDispatcher.reset();
    });

    test('receivePlatformMessage dispatches to channel', () async {
      final dispatcher = NeonPlatformDispatcher.instance;
      final channel = NeonPlatformChannel(name: 'test/dispatch');
      String? handledMethod;
      channel.setMessageHandler((method, args) async {
        handledMethod = method;
        return null;
      });
      dispatcher.registerChannel(channel);

      await dispatcher.receivePlatformMessage('test/dispatch', 'hello', null);
      expect(handledMethod, equals('hello'));

      NeonPlatformDispatcher.reset();
    });
  });

  group('NeonPlatformBridge', () {
    tearDown(() => NeonPlatformBridge.reset());

    test('initializes with platform target', () {
      final bridge = NeonPlatformBridge.instance;
      bridge.initialize(platform: NeonTargetPlatform.android);

      expect(bridge.isInitialized, isTrue);
      expect(bridge.platform, equals(NeonTargetPlatform.android));
    });

    test('throws if accessed before init', () {
      final bridge = NeonPlatformBridge.instance;
      expect(() => bridge.platformInfo, throwsStateError);
      expect(() => bridge.nativeRenderer, throwsStateError);
      expect(() => bridge.fileSystem, throwsStateError);
    });

    test('provides all subsystems after init', () {
      final bridge = NeonPlatformBridge.instance;
      bridge.initialize(platform: NeonTargetPlatform.ios);

      expect(bridge.platformInfo, isNotNull);
      expect(bridge.nativeRenderer, isNotNull);
      expect(bridge.fileSystem, isNotNull);
      expect(bridge.platformLifecycle, isNotNull);
      expect(bridge.systemChannel, isNotNull);
      expect(bridge.renderChannel, isNotNull);
    });

    test('double init is safe', () {
      final bridge = NeonPlatformBridge.instance;
      bridge.initialize(platform: NeonTargetPlatform.android);
      bridge.initialize(platform: NeonTargetPlatform.ios);
      expect(bridge.platform, equals(NeonTargetPlatform.android));
    });
  });

  group('NeonPlatformInfo', () {
    test('mock values work', () {
      final channel = NeonPlatformChannel(name: 'test/sys');
      final info = NeonPlatformInfo(
          channel: channel, platform: NeonTargetPlatform.android);

      info.setMockValues(
        osVersion: 'Android 14',
        deviceModel: 'Pixel 8',
        devicePixelRatio: 2.75,
        screenSize: const NeonSize(412, 892),
        safeArea: const NeonEdgeInsetsData(top: 48, bottom: 24),
        locale: 'en_US',
        isDarkMode: true,
      );

      expect(info.isLoaded, isTrue);
      expect(info.osVersion, equals('Android 14'));
      expect(info.deviceModel, equals('Pixel 8'));
      expect(info.devicePixelRatio, equals(2.75));
      expect(info.screenSize, equals(const NeonSize(412, 892)));
      expect(info.safeArea.top, equals(48));
      expect(info.safeArea.bottom, equals(24));
      expect(info.isDarkMode, isTrue);
      expect(info.isAndroid, isTrue);
      expect(info.isIOS, isFalse);
      expect(info.platformName, equals('Android'));
    });

    test('iOS platform detected', () {
      final channel = NeonPlatformChannel(name: 'test/sys');
      final info =
          NeonPlatformInfo(channel: channel, platform: NeonTargetPlatform.ios);
      expect(info.isIOS, isTrue);
      expect(info.platformName, equals('iOS'));
    });
  });

  group('NeonEdgeInsetsData', () {
    test('horizontal and vertical totals', () {
      const insets =
          NeonEdgeInsetsData(top: 10, right: 20, bottom: 30, left: 40);
      expect(insets.horizontal, equals(60));
      expect(insets.vertical, equals(40));
    });

    test('equality', () {
      const a = NeonEdgeInsetsData(top: 10, bottom: 10);
      const b = NeonEdgeInsetsData(top: 10, bottom: 10);
      expect(a, equals(b));
    });
  });

  group('NeonNativeRenderer', () {
    test('initialize sets ready state', () async {
      final channel = NeonPlatformChannel(name: 'test/render');
      NeonPlatformDispatcher.instance.registerChannel(channel);
      final renderer = NeonNativeRenderer(channel: channel);

      await renderer.initialize(const NeonSize(360, 800), 3.0);
      expect(renderer.isReady, isTrue);

      renderer.dispose();
      NeonPlatformDispatcher.reset();
    });

    test('submitFrame tracks frame history', () async {
      final channel = NeonPlatformChannel(name: 'test/render');
      NeonPlatformDispatcher.instance.registerChannel(channel);
      final renderer = NeonNativeRenderer(channel: channel);

      await renderer.initialize(const NeonSize(360, 800), 3.0);

      final canvas = NeonCanvas();
      canvas.drawRect(const NeonRect(0, 0, 100, 50), color: NeonColor.red);
      canvas.drawText('Hello', const NeonOffset(10, 10));

      await renderer.submitFrame(canvas);

      expect(renderer.frameCount, equals(1));
      expect(renderer.frameHistory.length, equals(1));
      expect(renderer.frameHistory.first.commandCount, equals(2));

      renderer.dispose();
      NeonPlatformDispatcher.reset();
    });

    test('submitFrame throws when not initialized', () {
      final channel = NeonPlatformChannel(name: 'test/render');
      final renderer = NeonNativeRenderer(channel: channel);
      final canvas = NeonCanvas();

      expect(() => renderer.submitFrame(canvas), throwsStateError);
    });

    test('dispose clears state', () async {
      final channel = NeonPlatformChannel(name: 'test/render');
      NeonPlatformDispatcher.instance.registerChannel(channel);
      final renderer = NeonNativeRenderer(channel: channel);

      await renderer.initialize(const NeonSize(360, 800), 1.0);
      renderer.dispose();

      expect(renderer.isReady, isFalse);
      expect(renderer.frameHistory, isEmpty);

      NeonPlatformDispatcher.reset();
    });
  });

  group('NeonFileSystem', () {
    test('mock file operations', () async {
      final channel = NeonPlatformChannel(name: 'test/file');
      final fs = NeonFileSystem(channel: channel);
      fs.enableMock();

      expect(await fs.fileExists('test.txt'), isFalse);

      await fs.writeFile('test.txt', 'Hello World');
      expect(await fs.fileExists('test.txt'), isTrue);

      final content = await fs.readFile('test.txt');
      expect(content, equals('Hello World'));

      final deleted = await fs.deleteFile('test.txt');
      expect(deleted, isTrue);
      expect(await fs.fileExists('test.txt'), isFalse);
    });

    test('mock list files', () async {
      final channel = NeonPlatformChannel(name: 'test/file');
      final fs = NeonFileSystem(channel: channel);
      fs.enableMock();

      await fs.writeFile('docs/a.txt', 'A');
      await fs.writeFile('docs/b.txt', 'B');
      await fs.writeFile('other/c.txt', 'C');

      final files = await fs.listFiles('docs/');
      expect(files.length, equals(2));
      expect(files.every((f) => f.startsWith('docs/')), isTrue);
    });

    test('mock storage path', () async {
      final channel = NeonPlatformChannel(name: 'test/file');
      final fs = NeonFileSystem(channel: channel);
      fs.enableMock();

      final path = await fs.getStoragePath(NeonStorageLocation.appDocuments);
      expect(path, equals('/mock/appDocuments'));
    });

    test('different storage locations are isolated', () async {
      final channel = NeonPlatformChannel(name: 'test/file');
      final fs = NeonFileSystem(channel: channel);
      fs.enableMock();

      await fs.writeFile('data.json', '{"a":1}',
          location: NeonStorageLocation.appDocuments);
      await fs.writeFile('data.json', '{"b":2}',
          location: NeonStorageLocation.appCache);

      final doc = await fs.readFile('data.json',
          location: NeonStorageLocation.appDocuments);
      final cache = await fs.readFile('data.json',
          location: NeonStorageLocation.appCache);

      expect(doc, equals('{"a":1}'));
      expect(cache, equals('{"b":2}'));
    });
  });

  group('NeonPlatformLifecycle', () {
    test('simulated native events are logged', () {
      final channel = NeonPlatformChannel(name: 'test/lifecycle');
      final lifecycle = NeonPlatformLifecycle(channel: channel);

      lifecycle.simulateNativeEvent(NeonNativeLifecycleEvent.onCreate);
      lifecycle.simulateNativeEvent(NeonNativeLifecycleEvent.onResume);

      expect(lifecycle.eventLog.length, equals(2));
      expect(lifecycle.eventLog[0], equals(NeonNativeLifecycleEvent.onCreate));
      expect(lifecycle.eventLog[1], equals(NeonNativeLifecycleEvent.onResume));

      lifecycle.dispose();
    });

    test('events stream emits', () async {
      final channel = NeonPlatformChannel(name: 'test/lifecycle');
      final lifecycle = NeonPlatformLifecycle(channel: channel);
      final events = <NeonNativeLifecycleEvent>[];
      lifecycle.events.listen(events.add);

      lifecycle.simulateNativeEvent(NeonNativeLifecycleEvent.onPause);
      await Future<void>.delayed(Duration.zero);

      expect(events, equals([NeonNativeLifecycleEvent.onPause]));

      lifecycle.dispose();
    });

    test('bridges native events to NeonLifecycleManager', () {
      final channel = NeonPlatformChannel(name: 'test/lifecycle');
      final lifecycle = NeonPlatformLifecycle(channel: channel);
      final manager = NeonLifecycleManager();
      final observer = TestLifecycleObserver();
      manager.addObserver(observer);
      manager.init();
      manager.markRunning();

      lifecycle.bindLifecycleManager(manager);

      lifecycle.simulateNativeEvent(NeonNativeLifecycleEvent.onPause);
      expect(observer.events, contains('pause'));

      lifecycle.simulateNativeEvent(NeonNativeLifecycleEvent.onResume);
      expect(observer.events, contains('resume'));

      lifecycle.dispose();
    });

    test('iOS lifecycle events bridge correctly', () {
      final channel = NeonPlatformChannel(name: 'test/lifecycle');
      final lifecycle = NeonPlatformLifecycle(channel: channel);
      final manager = NeonLifecycleManager();
      final observer = TestLifecycleObserver();
      manager.addObserver(observer);
      manager.init();
      manager.markRunning();

      lifecycle.bindLifecycleManager(manager);

      lifecycle.simulateNativeEvent(NeonNativeLifecycleEvent.willResignActive);
      expect(observer.events, contains('pause'));

      lifecycle.simulateNativeEvent(NeonNativeLifecycleEvent.didBecomeActive);
      expect(observer.events, contains('resume'));

      lifecycle.dispose();
    });

    test('handles lifecycle message from channel', () async {
      final channel = NeonPlatformChannel(name: 'test/lifecycle');
      final lifecycle = NeonPlatformLifecycle(channel: channel);

      await channel.handlePlatformMessage('lifecycle.event', 'onResume');

      expect(lifecycle.eventLog.length, equals(1));
      expect(
          lifecycle.eventLog.first, equals(NeonNativeLifecycleEvent.onResume));

      lifecycle.dispose();
    });
  });

  // ─── Phase 6: Tooling Tests ───

  group('NeonCli', () {
    test('version is set', () {
      expect(NeonCli.version, equals('0.1.0'));
    });

    test('can be instantiated', () {
      final cli = NeonCli();
      expect(cli, isNotNull);
    });

    test('--version flag returns 0', () async {
      final cli = NeonCli();
      final result = await cli.run(['--version']);
      expect(result, equals(0));
    });

    test('unknown command returns error', () async {
      final cli = NeonCli();
      final result = await cli.run(['nonexistent']);
      expect(result, equals(1));
    });
  });

  group('NeonLogger', () {
    test('info prints message', () {
      expect(() => NeonLogger.info('test'), returnsNormally);
    });

    test('success prints message', () {
      expect(() => NeonLogger.success('ok'), returnsNormally);
    });

    test('warning prints message', () {
      expect(() => NeonLogger.warning('warn'), returnsNormally);
    });

    test('error prints message', () {
      expect(() => NeonLogger.error('err'), returnsNormally);
    });

    test('step prints message', () {
      expect(() => NeonLogger.step('step'), returnsNormally);
    });

    test('header prints message', () {
      expect(() => NeonLogger.header('Header'), returnsNormally);
    });
  });

  group('NeonProjectTemplate', () {
    test('generates app template files', () {
      final template = NeonProjectTemplate(
        projectName: 'test_app',
        template: 'app',
      );
      final files = template.generate();

      expect(files.containsKey('pubspec.yaml'), isTrue);
      expect(files.containsKey('analysis_options.yaml'), isTrue);
      expect(files.containsKey('lib/main.dart'), isTrue);
      expect(files.containsKey('lib/app.dart'), isTrue);
      expect(files.containsKey('lib/screens/home_screen.dart'), isTrue);
      expect(files.containsKey('neon.yaml'), isTrue);
      expect(files.containsKey('.gitignore'), isTrue);
      expect(files.length, equals(7));
    });

    test('generates minimal template files', () {
      final template = NeonProjectTemplate(
        projectName: 'mini_app',
        template: 'minimal',
      );
      final files = template.generate();

      expect(files.containsKey('pubspec.yaml'), isTrue);
      expect(files.containsKey('analysis_options.yaml'), isTrue);
      expect(files.containsKey('lib/main.dart'), isTrue);
      expect(files.containsKey('neon.yaml'), isTrue);
      expect(files.containsKey('.gitignore'), isTrue);
      expect(files.length, equals(5));
    });

    test('pubspec contains project name', () {
      final template = NeonProjectTemplate(
        projectName: 'my_cool_app',
        template: 'app',
      );
      final files = template.generate();
      expect(files['pubspec.yaml']!, contains('name: my_cool_app'));
    });

    test('pubspec contains neon_framework dependency', () {
      final template = NeonProjectTemplate(
        projectName: 'my_app',
        template: 'app',
      );
      final files = template.generate();
      expect(files['pubspec.yaml']!, contains('neon_framework'));
    });

    test('neon.yaml contains project name', () {
      final template = NeonProjectTemplate(
        projectName: 'my_app',
        template: 'app',
      );
      final files = template.generate();
      expect(files['neon.yaml']!, contains('name: my_app'));
    });

    test('neon.yaml contains android and ios config', () {
      final template = NeonProjectTemplate(
        projectName: 'my_app',
        template: 'app',
      );
      final files = template.generate();
      final config = files['neon.yaml']!;
      expect(config, contains('android:'));
      expect(config, contains('ios:'));
    });

    test('neon.yaml contains hot_reload config', () {
      final template = NeonProjectTemplate(
        projectName: 'my_app',
        template: 'app',
      );
      final files = template.generate();
      expect(files['neon.yaml']!, contains('hot_reload:'));
      expect(files['neon.yaml']!, contains('mode: state_preserving'));
    });

    test('main.dart imports neon_framework', () {
      final template = NeonProjectTemplate(
        projectName: 'my_app',
        template: 'app',
      );
      final files = template.generate();
      expect(files['lib/main.dart']!,
          contains("import 'package:neon_framework/neon.dart'"));
    });

    test('minimal main.dart has inline widget', () {
      final template = NeonProjectTemplate(
        projectName: 'my_app',
        template: 'minimal',
      );
      final files = template.generate();
      expect(files['lib/main.dart']!,
          contains('class MyApp extends StatelessWidget'));
      expect(files['lib/main.dart']!, contains("Text('Hello, Neon!')"));
    });

    test('app template has StatefulWidget example', () {
      final template = NeonProjectTemplate(
        projectName: 'my_app',
        template: 'app',
      );
      final files = template.generate();
      expect(
          files['lib/screens/home_screen.dart']!, contains('StatefulWidget'));
      expect(files['lib/screens/home_screen.dart']!, contains('_counter'));
    });

    test('writeFiles rejects existing directory', () {
      final template = NeonProjectTemplate(
        projectName: '.',
        template: 'app',
      );
      final files = template.generate();
      final result = template.writeFiles(files);
      expect(result.success, isFalse);
      expect(result.message, contains('already exists'));
    });
  });

  group('HotReloadMode', () {
    test('fromString parses ui', () {
      expect(HotReloadMode.fromString('ui'), equals(HotReloadMode.ui));
    });

    test('fromString parses state-preserving', () {
      expect(HotReloadMode.fromString('state-preserving'),
          equals(HotReloadMode.statePreserving));
    });

    test('fromString parses full', () {
      expect(HotReloadMode.fromString('full'), equals(HotReloadMode.full));
    });

    test('fromString defaults to statePreserving', () {
      expect(HotReloadMode.fromString('unknown'),
          equals(HotReloadMode.statePreserving));
    });
  });

  group('HotReloadEvent', () {
    test('creates with required fields', () {
      final event = HotReloadEvent(
        type: HotReloadEventType.uiReload,
        description: 'test reload',
      );

      expect(event.type, equals(HotReloadEventType.uiReload));
      expect(event.description, equals('test reload'));
      expect(event.changedFiles, isEmpty);
      expect(event.timestamp, isNotNull);
    });

    test('tracks changed files', () {
      final event = HotReloadEvent(
        type: HotReloadEventType.statePreservingReload,
        description: 'reload',
        changedFiles: ['lib/main.dart', 'lib/app.dart'],
      );

      expect(event.changedFiles.length, equals(2));
    });

    test('toString includes type and description', () {
      final event = HotReloadEvent(
        type: HotReloadEventType.fullReload,
        description: 'full reload triggered',
      );

      expect(event.toString(), contains('fullReload'));
      expect(event.toString(), contains('full reload triggered'));
    });
  });

  group('HotReloadEngine', () {
    test('initializes with correct defaults', () {
      final engine = HotReloadEngine(
        projectPath: '.',
        watchPaths: ['lib/'],
      );

      expect(engine.mode, equals(HotReloadMode.statePreserving));
      expect(engine.isRunning, isFalse);
      expect(engine.history, isEmpty);
    });

    test('starts and stops', () {
      final engine = HotReloadEngine(
        projectPath: '.',
        watchPaths: ['lib/'],
      );

      engine.start();
      expect(engine.isRunning, isTrue);

      engine.stop();
      expect(engine.isRunning, isFalse);
    });

    test('double start is safe', () {
      final engine = HotReloadEngine(
        projectPath: '.',
        watchPaths: ['lib/'],
      );

      engine.start();
      engine.start();
      expect(engine.isRunning, isTrue);

      engine.stop();
    });

    test('accepts custom mode', () {
      final engine = HotReloadEngine(
        projectPath: '.',
        watchPaths: ['lib/'],
        mode: HotReloadMode.ui,
      );

      expect(engine.mode, equals(HotReloadMode.ui));
    });

    test('accepts onReload callback', () {
      HotReloadEvent? captured;
      final engine = HotReloadEngine(
        projectPath: '.',
        watchPaths: ['lib/'],
        onReload: (event) {
          captured = event;
        },
      );

      expect(engine.onReload, isNotNull);
    });
  });

  group('HotReloadSession', () {
    test('tracks reload count', () {
      final engine = HotReloadEngine(
        projectPath: '.',
        watchPaths: ['lib/'],
      );
      final session = HotReloadSession(engine: engine);

      expect(session.reloadCount, equals(0));

      session.recordReload();
      session.recordReload();
      session.recordReload();

      expect(session.reloadCount, equals(3));
    });

    test('reports uptime', () {
      final engine = HotReloadEngine(
        projectPath: '.',
        watchPaths: ['lib/'],
      );
      final session = HotReloadSession(engine: engine);

      expect(session.uptime.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('provides stats map', () {
      final engine = HotReloadEngine(
        projectPath: '.',
        watchPaths: ['lib/'],
        mode: HotReloadMode.ui,
      );
      final session = HotReloadSession(engine: engine);

      final stats = session.stats;
      expect(stats['reload_count'], equals(0));
      expect(stats['mode'], equals('ui'));
      expect(stats['is_running'], isFalse);
      expect(stats.containsKey('uptime_seconds'), isTrue);
    });
  });

  group('NeonProject', () {
    test('load from current directory', () {
      final project = NeonProject.load();
      expect(project.isValid, isTrue);
      expect(project.name, isNotEmpty);
    });

    test('load from invalid directory fails gracefully', () {
      final project = NeonProject.load('/tmp/nonexistent_project_xyz');
      expect(project.isValid, isFalse);
      expect(project.error, contains('No pubspec.yaml'));
    });
  });

  // ─── Phase 7: Storage & Networking Tests ───

  group('NeonKeyValueStore', () {
    test('stores and retrieves string', () async {
      final kv = NeonKeyValueStore();
      await kv.setString('name', 'Neon');
      expect(await kv.getString('name'), equals('Neon'));
    });

    test('stores and retrieves int', () async {
      final kv = NeonKeyValueStore();
      await kv.setInt('count', 42);
      expect(await kv.getInt('count'), equals(42));
    });

    test('stores and retrieves double', () async {
      final kv = NeonKeyValueStore();
      await kv.setDouble('pi', 3.14);
      expect(await kv.getDouble('pi'), equals(3.14));
    });

    test('stores and retrieves bool', () async {
      final kv = NeonKeyValueStore();
      await kv.setBool('dark', true);
      expect(await kv.getBool('dark'), isTrue);
    });

    test('stores and retrieves string list', () async {
      final kv = NeonKeyValueStore();
      await kv.setStringList('tags', ['a', 'b', 'c']);
      expect(await kv.getStringList('tags'), equals(['a', 'b', 'c']));
    });

    test('stores and retrieves json', () async {
      final kv = NeonKeyValueStore();
      await kv.setJson('user', {'name': 'Alice', 'age': 30});
      final json = await kv.getJson('user');
      expect(json!['name'], equals('Alice'));
      expect(json['age'], equals(30));
    });

    test('returns null for missing keys', () async {
      final kv = NeonKeyValueStore();
      expect(await kv.getString('missing'), isNull);
      expect(await kv.getInt('missing'), isNull);
      expect(await kv.getDouble('missing'), isNull);
      expect(await kv.getBool('missing'), isNull);
    });

    test('removes key', () async {
      final kv = NeonKeyValueStore();
      await kv.setString('key', 'value');
      await kv.remove('key');
      expect(await kv.getString('key'), isNull);
    });

    test('clears all keys', () async {
      final kv = NeonKeyValueStore();
      await kv.setString('a', '1');
      await kv.setString('b', '2');
      await kv.clear();
      expect(await kv.getString('a'), isNull);
      expect(await kv.getString('b'), isNull);
    });

    test('lists keys', () async {
      final kv = NeonKeyValueStore();
      await kv.setString('x', '1');
      await kv.setString('y', '2');
      final keys = await kv.keys();
      expect(keys, containsAll(['x', 'y']));
    });

    test('containsKey works', () async {
      final kv = NeonKeyValueStore();
      await kv.setString('present', 'yes');
      expect(await kv.containsKey('present'), isTrue);
      expect(await kv.containsKey('absent'), isFalse);
    });

    test('prefix isolates keys', () async {
      final kv1 = NeonKeyValueStore(prefix: 'app');
      final kv2 = NeonKeyValueStore(prefix: 'cache');
      final backend = NeonMemoryKVBackend();
      final kvA = NeonKeyValueStore(backend: backend, prefix: 'a');
      final kvB = NeonKeyValueStore(backend: backend, prefix: 'b');

      await kvA.setString('key', 'from_a');
      await kvB.setString('key', 'from_b');

      expect(await kvA.getString('key'), equals('from_a'));
      expect(await kvB.getString('key'), equals('from_b'));
    });
  });

  group('NeonColumn', () {
    test('generates basic column SQL', () {
      final col = NeonColumn(name: 'name', type: NeonColumnType.text);
      expect(col.toSql(), equals('name TEXT'));
    });

    test('generates primary key SQL', () {
      final col = NeonColumn(
        name: 'id',
        type: NeonColumnType.integer,
        primaryKey: true,
        autoIncrement: true,
      );
      expect(col.toSql(), contains('PRIMARY KEY'));
      expect(col.toSql(), contains('AUTOINCREMENT'));
    });

    test('generates NOT NULL constraint', () {
      final col = NeonColumn(
        name: 'email',
        type: NeonColumnType.text,
        nullable: false,
      );
      expect(col.toSql(), contains('NOT NULL'));
    });

    test('generates UNIQUE constraint', () {
      final col = NeonColumn(
        name: 'code',
        type: NeonColumnType.text,
        unique: true,
      );
      expect(col.toSql(), contains('UNIQUE'));
    });

    test('generates default value', () {
      final col = NeonColumn(
        name: 'status',
        type: NeonColumnType.integer,
        defaultValue: 0,
      );
      expect(col.toSql(), contains('DEFAULT 0'));
    });
  });

  group('NeonTableSchema', () {
    test('generates CREATE TABLE SQL', () {
      final schema = NeonTableSchema(
        name: 'users',
        columns: [
          NeonColumn(
              name: 'id', type: NeonColumnType.integer, primaryKey: true),
          NeonColumn(name: 'name', type: NeonColumnType.text),
        ],
      );
      final sql = schema.toCreateSql();
      expect(sql, contains('CREATE TABLE IF NOT EXISTS users'));
      expect(sql, contains('id INTEGER PRIMARY KEY'));
      expect(sql, contains('name TEXT'));
    });

    test('generates DROP TABLE SQL', () {
      final schema = NeonTableSchema(name: 'users', columns: []);
      expect(schema.toDropSql(), equals('DROP TABLE IF EXISTS users'));
    });
  });

  group('NeonDatabase', () {
    test('opens and closes', () async {
      final db = NeonDatabase(path: ':memory:');
      await db.open();
      expect(db.isOpen, isTrue);
      await db.close();
      expect(db.isOpen, isFalse);
    });

    test('creates tables on open', () async {
      final backend = NeonMemoryDatabaseBackend();
      final db = NeonDatabase(path: ':memory:', backend: backend);

      db.defineTable(NeonTableSchema(
        name: 'users',
        columns: [
          NeonColumn(
              name: 'id', type: NeonColumnType.integer, primaryKey: true),
          NeonColumn(name: 'name', type: NeonColumnType.text),
        ],
      ));

      await db.open();
      expect(
          backend.executedSql.any((s) => s.contains('CREATE TABLE')), isTrue);
    });

    test('insert and query', () async {
      final db = NeonDatabase(path: ':memory:');
      db.defineTable(NeonTableSchema(
        name: 'items',
        columns: [
          NeonColumn(
              name: 'id', type: NeonColumnType.integer, primaryKey: true),
          NeonColumn(name: 'title', type: NeonColumnType.text),
        ],
      ));
      await db.open();

      await db.insert('items', {'id': 1, 'title': 'Test Item'});
      final result = await db.queryTable('items');
      expect(result.isNotEmpty, isTrue);
      expect(result.first!['title'], equals('Test Item'));
    });

    test('runs migrations in order', () async {
      final backend = NeonMemoryDatabaseBackend();
      final db = NeonDatabase(path: ':memory:', backend: backend);

      db.addMigration(NeonMigration(
        version: 2,
        description: 'Add email column',
        upStatements: ['ALTER TABLE users ADD COLUMN email TEXT'],
      ));
      db.addMigration(NeonMigration(
        version: 1,
        description: 'Create users table',
        upStatements: ['CREATE TABLE users (id INTEGER PRIMARY KEY)'],
      ));

      await db.open();
      expect(db.version, equals(2));
      expect(backend.executedSql,
          contains('CREATE TABLE users (id INTEGER PRIMARY KEY)'));
    });

    test('delete from table', () async {
      final db = NeonDatabase(path: ':memory:');
      db.defineTable(NeonTableSchema(
        name: 'items',
        columns: [
          NeonColumn(
              name: 'id', type: NeonColumnType.integer, primaryKey: true),
        ],
      ));
      await db.open();

      await db.insert('items', {'id': 1});
      await db.insert('items', {'id': 2});
      final deleteResult = await db.delete('items');
      expect(deleteResult.rowsAffected, equals(2));
    });

    test('raw query and execute', () async {
      final backend = NeonMemoryDatabaseBackend();
      final db = NeonDatabase(path: ':memory:', backend: backend);
      await db.open();

      await db.rawExecute('CREATE TABLE test (id INTEGER)');
      expect(
          backend.executedSql.last, equals('CREATE TABLE test (id INTEGER)'));
    });
  });

  group('NeonQueryResult', () {
    test('isEmpty and isNotEmpty', () {
      const empty = NeonQueryResult();
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);

      final withData = NeonQueryResult(rows: [
        {'id': 1}
      ]);
      expect(withData.isEmpty, isFalse);
      expect(withData.isNotEmpty, isTrue);
    });

    test('first returns first row', () {
      final result = NeonQueryResult(rows: [
        {'id': 1},
        {'id': 2}
      ]);
      expect(result.first!['id'], equals(1));
    });

    test('first returns null when empty', () {
      const result = NeonQueryResult();
      expect(result.first, isNull);
    });
  });

  group('NeonHttpHeaders', () {
    test('case-insensitive get/set', () {
      final headers = NeonHttpHeaders();
      headers['Content-Type'] = 'application/json';
      expect(headers['content-type'], equals('application/json'));
    });

    test('merge combines headers', () {
      final a = NeonHttpHeaders({'accept': 'json'});
      final b = NeonHttpHeaders({'authorization': 'Bearer token'});
      final merged = a.merge(b);
      expect(merged['accept'], equals('json'));
      expect(merged['authorization'], equals('Bearer token'));
    });

    test('toMap returns immutable copy', () {
      final headers = NeonHttpHeaders({'key': 'value'});
      final map = headers.toMap();
      expect(map['key'], equals('value'));
    });
  });

  group('NeonHttpRequest', () {
    test('GET factory', () {
      final req = NeonHttpRequest.get('https://api.example.com/users');
      expect(req.method, equals(NeonHttpMethod.get));
      expect(req.url.toString(), equals('https://api.example.com/users'));
    });

    test('POST factory', () {
      final req = NeonHttpRequest.post(
        'https://api.example.com/users',
        body: {'name': 'Alice'},
      );
      expect(req.method, equals(NeonHttpMethod.post));
      expect(req.body, isNotNull);
    });

    test('DELETE factory', () {
      final req = NeonHttpRequest.delete('https://api.example.com/users/1');
      expect(req.method, equals(NeonHttpMethod.delete));
    });
  });

  group('NeonHttpResponse', () {
    test('status code checks', () {
      NeonHttpResponse makeResponse(int code) => NeonHttpResponse(
            statusCode: code,
            headers: NeonHttpHeaders(),
            body: '',
            duration: Duration.zero,
            request: NeonHttpRequest.get('https://test.com'),
          );

      expect(makeResponse(200).isSuccess, isTrue);
      expect(makeResponse(301).isRedirect, isTrue);
      expect(makeResponse(404).isClientError, isTrue);
      expect(makeResponse(500).isServerError, isTrue);
    });

    test('json parsing', () {
      final response = NeonHttpResponse(
        statusCode: 200,
        headers: NeonHttpHeaders(),
        body: '{"name": "Alice"}',
        duration: Duration.zero,
        request: NeonHttpRequest.get('https://test.com'),
      );
      expect(response.json['name'], equals('Alice'));
    });

    test('json list parsing', () {
      final response = NeonHttpResponse(
        statusCode: 200,
        headers: NeonHttpHeaders(),
        body: '[1, 2, 3]',
        duration: Duration.zero,
        request: NeonHttpRequest.get('https://test.com'),
      );
      expect(response.jsonList, equals([1, 2, 3]));
    });

    test('toString includes info', () {
      final response = NeonHttpResponse(
        statusCode: 200,
        headers: NeonHttpHeaders(),
        body: 'hello',
        duration: const Duration(milliseconds: 50),
        request: NeonHttpRequest.get('https://test.com'),
      );
      expect(response.toString(), contains('200'));
    });
  });

  group('NeonMockHttpBackend', () {
    test('returns default mock response', () async {
      final mock = NeonMockHttpBackend();
      final response = await mock.send(
        NeonHttpRequest.get('https://api.example.com/test'),
      );
      expect(response.statusCode, equals(200));
      expect(response.body, contains('mock'));
    });

    test('handles URL pattern matching', () async {
      final mock = NeonMockHttpBackend();
      mock.onRequest(
          '/users',
          (req) => mock.mockResponse(
                statusCode: 200,
                body: '{"users": []}',
                request: req,
              ));

      final response = await mock.send(
        NeonHttpRequest.get('https://api.example.com/users'),
      );
      expect(response.body, contains('users'));
    });

    test('tracks sent requests', () async {
      final mock = NeonMockHttpBackend();
      await mock.send(NeonHttpRequest.get('https://test.com/a'));
      await mock.send(NeonHttpRequest.post('https://test.com/b'));
      expect(mock.sentRequests.length, equals(2));
    });

    test('default handler catches all', () async {
      final mock = NeonMockHttpBackend();
      mock.onAnyRequest((req) => mock.mockResponse(
            statusCode: 418,
            body: 'teapot',
            request: req,
          ));

      final response = await mock.send(NeonHttpRequest.get('https://any.com'));
      expect(response.statusCode, equals(418));
    });
  });

  group('NeonHttpClient', () {
    test('uses mock backend', () async {
      final mock = NeonMockHttpBackend();
      final client = NeonHttpClient(backend: mock);

      final response = await client.get('https://api.test.com/data');
      expect(response.isSuccess, isTrue);
      expect(mock.sentRequests.length, equals(1));
    });

    test('base URL resolution', () async {
      final mock = NeonMockHttpBackend();
      final client = NeonHttpClient(
        backend: mock,
        baseUrl: 'https://api.test.com',
      );

      await client.get('/users');
      expect(mock.sentRequests.first.url.toString(),
          equals('https://api.test.com/users'));
    });

    test('POST with body', () async {
      final mock = NeonMockHttpBackend();
      final client = NeonHttpClient(backend: mock);

      await client.post('https://test.com/items', body: {'name': 'Item'});
      expect(mock.sentRequests.first.method, equals(NeonHttpMethod.post));
      expect(mock.sentRequests.first.body, isNotNull);
    });

    test('request interceptors', () async {
      final mock = NeonMockHttpBackend();
      final client = NeonHttpClient(backend: mock);

      client.addRequestInterceptor((req) async {
        req.headers['authorization'] = 'Bearer test-token';
        return req;
      });

      await client.get('https://test.com/protected');
      expect(
        mock.sentRequests.first.headers['authorization'],
        equals('Bearer test-token'),
      );
    });

    test('response interceptors', () async {
      final mock = NeonMockHttpBackend();
      final client = NeonHttpClient(backend: mock);

      int interceptedStatus = 0;
      client.addResponseInterceptor((response) async {
        interceptedStatus = response.statusCode;
        return response;
      });

      await client.get('https://test.com/data');
      expect(interceptedStatus, equals(200));
    });

    test('default headers applied', () async {
      final mock = NeonMockHttpBackend();
      final client = NeonHttpClient(
        backend: mock,
        defaultHeaders: NeonHttpHeaders({'x-api-key': 'my-key'}),
      );

      await client.get('https://test.com');
      expect(mock.sentRequests.first.headers['x-api-key'], equals('my-key'));
    });

    test('all HTTP methods', () async {
      final mock = NeonMockHttpBackend();
      final client = NeonHttpClient(backend: mock);

      await client.get('https://test.com');
      await client.post('https://test.com');
      await client.put('https://test.com');
      await client.patch('https://test.com');
      await client.delete('https://test.com');

      expect(mock.sentRequests.length, equals(5));
      expect(mock.sentRequests[0].method, equals(NeonHttpMethod.get));
      expect(mock.sentRequests[1].method, equals(NeonHttpMethod.post));
      expect(mock.sentRequests[2].method, equals(NeonHttpMethod.put));
      expect(mock.sentRequests[3].method, equals(NeonHttpMethod.patch));
      expect(mock.sentRequests[4].method, equals(NeonHttpMethod.delete));
    });
  });

  group('NeonWebSocket', () {
    test('connects and reports state', () async {
      final ws = NeonWebSocket();
      await ws.connect('ws://test.com');
      expect(ws.isConnected, isTrue);
      expect(ws.state, equals(NeonWebSocketState.connected));
    });

    test('sends messages', () async {
      final mock = NeonMockWebSocketBackend();
      final ws = NeonWebSocket(backend: mock);
      await ws.connect('ws://test.com');

      ws.send('hello');
      expect(mock.sentMessages, contains('hello'));
    });

    test('sends JSON messages', () async {
      final mock = NeonMockWebSocketBackend();
      final ws = NeonWebSocket(backend: mock);
      await ws.connect('ws://test.com');

      ws.sendJson({'type': 'greeting', 'data': 'hello'});
      expect(mock.sentMessages.first, contains('greeting'));
    });

    test('receives messages via listener', () async {
      final mock = NeonMockWebSocketBackend();
      final ws = NeonWebSocket(backend: mock);
      await ws.connect('ws://test.com');

      final received = <String>[];
      ws.onMessage((msg) => received.add(msg.data));

      mock.simulateMessage('hello');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(received, contains('hello'));
    });

    test('closes connection', () async {
      final ws = NeonWebSocket();
      await ws.connect('ws://test.com');
      await ws.close();
      expect(ws.isConnected, isFalse);
      expect(ws.autoReconnect, isFalse);
    });

    test('connect/disconnect listeners', () async {
      final ws = NeonWebSocket();
      bool connected = false;
      ws.onConnect(() => connected = true);
      await ws.connect('ws://test.com');
      expect(connected, isTrue);
    });

    test('reconnect increments attempts', () async {
      final mock = NeonMockWebSocketBackend();
      final ws = NeonWebSocket(
        backend: mock,
        reconnectDelay: const Duration(milliseconds: 1),
        maxReconnectAttempts: 3,
      );
      await ws.connect('ws://test.com');
      await ws.reconnect();
      await ws.reconnect();
    });

    test('reconnect without prior connection throws', () async {
      final ws = NeonWebSocket();
      expect(() => ws.reconnect(), throwsStateError);
    });

    test('message json parsing', () {
      final msg = NeonWebSocketMessage('{"key": "value"}');
      expect(msg.json, isNotNull);
      expect(msg.json!['key'], equals('value'));
    });

    test('message invalid json returns null', () {
      final msg = NeonWebSocketMessage('not json');
      expect(msg.json, isNull);
    });

    test('dispose cleans up', () {
      final ws = NeonWebSocket();
      expect(() => ws.dispose(), returnsNormally);
    });
  });

  group('NeonCacheEntry', () {
    test('fresh entry is not expired', () {
      final entry = NeonCacheEntry(
        key: 'test',
        data: 'value',
        maxAge: const Duration(hours: 1),
      );
      expect(entry.isFresh, isTrue);
      expect(entry.isExpired, isFalse);
    });

    test('entry without maxAge never expires', () {
      final entry = NeonCacheEntry(key: 'test', data: 'value');
      expect(entry.isExpired, isFalse);
    });

    test('age returns duration since creation', () {
      final entry = NeonCacheEntry(key: 'test', data: 'value');
      expect(entry.age.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('toString includes key and expiry info', () {
      final entry = NeonCacheEntry(
        key: 'my_key',
        data: 'value',
        maxAge: const Duration(minutes: 5),
      );
      expect(entry.toString(), contains('my_key'));
    });
  });

  group('NeonCacheStore', () {
    test('put and get', () {
      final store = NeonCacheStore();
      store.put('key', 'value');
      final entry = store.get<String>('key');
      expect(entry, isNotNull);
      expect(entry!.data, equals('value'));
    });

    test('has and hasFresh', () {
      final store = NeonCacheStore(defaultMaxAge: const Duration(hours: 1));
      store.put('key', 'value');
      expect(store.has('key'), isTrue);
      expect(store.hasFresh('key'), isTrue);
      expect(store.has('missing'), isFalse);
    });

    test('remove entry', () {
      final store = NeonCacheStore();
      store.put('key', 'value');
      store.remove('key');
      expect(store.has('key'), isFalse);
    });

    test('clear all entries', () {
      final store = NeonCacheStore();
      store.put('a', 1);
      store.put('b', 2);
      store.clear();
      expect(store.size, equals(0));
    });

    test('evictExpired removes only expired', () {
      final store = NeonCacheStore();
      store.put('fresh', 'value', maxAge: const Duration(hours: 1));
      store.put('expired', 'value', maxAge: const Duration(milliseconds: 0));
      store.evictExpired();
      expect(store.has('fresh'), isTrue);
    });

    test('stats reports counts', () {
      final store = NeonCacheStore(defaultMaxAge: const Duration(hours: 1));
      store.put('a', 1);
      store.put('b', 2);
      final stats = store.stats;
      expect(stats['size'], equals(2));
    });

    test('keys returns all keys', () {
      final store = NeonCacheStore();
      store.put('x', 1);
      store.put('y', 2);
      expect(store.keys, containsAll(['x', 'y']));
    });
  });

  group('NeonCachePolicy', () {
    test('cacheFirst returns cached data', () async {
      final store = NeonCacheStore();
      store.put<String>('key', 'cached_value',
          maxAge: const Duration(hours: 1));

      int fetchCount = 0;
      final policy = NeonCachePolicy<String>.cacheFirst(
        store: store,
        fetcher: (key) async {
          fetchCount++;
          return 'network_value';
        },
      );

      final result = await policy.execute('key');
      expect(result, equals('cached_value'));
      expect(fetchCount, equals(0));
    });

    test('cacheFirst fetches when no cache', () async {
      final store = NeonCacheStore();

      final policy = NeonCachePolicy<String>.cacheFirst(
        store: store,
        fetcher: (key) async => 'network_value',
      );

      final result = await policy.execute('key');
      expect(result, equals('network_value'));
      expect(store.has('key'), isTrue);
    });

    test('networkFirst returns network data', () async {
      final store = NeonCacheStore();

      final policy = NeonCachePolicy<String>.networkFirst(
        store: store,
        fetcher: (key) async => 'fresh_data',
      );

      final result = await policy.execute('key');
      expect(result, equals('fresh_data'));
    });

    test('networkFirst falls back to cache on error', () async {
      final store = NeonCacheStore();
      store.put<String>('key', 'stale_data');

      final policy = NeonCachePolicy<String>.networkFirst(
        store: store,
        fetcher: (key) async => throw Exception('network error'),
      );

      final result = await policy.execute('key');
      expect(result, equals('stale_data'));
    });

    test('networkFirst throws when no cache and network fails', () async {
      final store = NeonCacheStore();

      final policy = NeonCachePolicy<String>.networkFirst(
        store: store,
        fetcher: (key) async => throw Exception('network error'),
      );

      expect(() => policy.execute('key'), throwsException);
    });

    test('cacheOnly returns cached data', () async {
      final store = NeonCacheStore();
      store.put<String>('key', 'cached');

      final policy = NeonCachePolicy<String>.cacheOnly(
        store: store,
        fetcher: (key) async => 'should_not_fetch',
      );

      final result = await policy.execute('key');
      expect(result, equals('cached'));
    });

    test('cacheOnly throws when no cache', () async {
      final store = NeonCacheStore();

      final policy = NeonCachePolicy<String>.cacheOnly(
        store: store,
        fetcher: (key) async => 'value',
      );

      expect(() => policy.execute('key'), throwsStateError);
    });

    test('networkOnly always fetches', () async {
      final store = NeonCacheStore();
      store.put<String>('key', 'old_cached');

      int fetchCount = 0;
      final policy = NeonCachePolicy<String>.networkOnly(
        store: store,
        fetcher: (key) async {
          fetchCount++;
          return 'fresh';
        },
      );

      final result = await policy.execute('key');
      expect(result, equals('fresh'));
      expect(fetchCount, equals(1));
    });

    test('staleWhileRevalidate returns stale and refreshes', () async {
      final store = NeonCacheStore();
      store.put<String>('key', 'stale',
          maxAge: const Duration(milliseconds: 0));

      String? refreshedValue;
      final policy = NeonCachePolicy<String>.staleWhileRevalidate(
        store: store,
        fetcher: (key) async => 'refreshed',
        onBackgroundRefresh: (data) => refreshedValue = data,
      );

      final result = await policy.execute('key');
      expect(result, equals('stale'));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(refreshedValue, equals('refreshed'));
    });

    test('staleWhileRevalidate fetches when no cache', () async {
      final store = NeonCacheStore();

      final policy = NeonCachePolicy<String>.staleWhileRevalidate(
        store: store,
        fetcher: (key) async => 'first_fetch',
      );

      final result = await policy.execute('key');
      expect(result, equals('first_fetch'));
    });
  });

  // ─── Phase 8: Plugins & Extensibility Tests ───

  group('NeonSemanticVersion', () {
    test('parses standard version', () {
      final v = NeonSemanticVersion.parse('1.2.3');
      expect(v.major, equals(1));
      expect(v.minor, equals(2));
      expect(v.patch, equals(3));
      expect(v.preRelease, isNull);
    });

    test('parses version with v prefix', () {
      final v = NeonSemanticVersion.parse('v2.0.0');
      expect(v.major, equals(2));
    });

    test('parses pre-release version', () {
      final v = NeonSemanticVersion.parse('1.0.0-beta.1');
      expect(v.major, equals(1));
      expect(v.preRelease, equals('beta.1'));
    });

    test('comparison works correctly', () {
      final v1 = NeonSemanticVersion.parse('1.0.0');
      final v2 = NeonSemanticVersion.parse('2.0.0');
      final v3 = NeonSemanticVersion.parse('1.1.0');
      final v4 = NeonSemanticVersion.parse('1.0.1');

      expect(v1 < v2, isTrue);
      expect(v2 > v1, isTrue);
      expect(v1 < v3, isTrue);
      expect(v1 < v4, isTrue);
      expect(v1 == NeonSemanticVersion.parse('1.0.0'), isTrue);
    });

    test('pre-release is lower than release', () {
      final pre = NeonSemanticVersion.parse('1.0.0-alpha');
      final release = NeonSemanticVersion.parse('1.0.0');
      expect(pre < release, isTrue);
    });

    test('toString formats correctly', () {
      expect(NeonSemanticVersion.parse('1.2.3').toString(), equals('1.2.3'));
      expect(NeonSemanticVersion.parse('1.0.0-rc1').toString(),
          equals('1.0.0-rc1'));
    });
  });

  group('NeonSdkConstraint', () {
    test('any accepts all versions', () {
      const constraint = NeonSdkConstraint.any();
      expect(constraint.isSatisfiedBy('0.1.0'), isTrue);
      expect(constraint.isSatisfiedBy('99.0.0'), isTrue);
    });

    test('exact matches only specific version', () {
      const constraint = NeonSdkConstraint.exact('1.0.0');
      expect(constraint.isSatisfiedBy('1.0.0'), isTrue);
      expect(constraint.isSatisfiedBy('1.0.1'), isFalse);
      expect(constraint.isSatisfiedBy('0.9.0'), isFalse);
    });

    test('range constraint works', () {
      const constraint = NeonSdkConstraint(
        minVersion: '0.5.0',
        maxVersion: '2.0.0',
      );
      expect(constraint.isSatisfiedBy('0.5.0'), isTrue);
      expect(constraint.isSatisfiedBy('1.0.0'), isTrue);
      expect(constraint.isSatisfiedBy('0.4.0'), isFalse);
      expect(constraint.isSatisfiedBy('2.0.0'), isFalse);
    });

    test('toString formats correctly', () {
      expect(const NeonSdkConstraint.any().toString(), equals('any'));
      expect(
          const NeonSdkConstraint.exact('1.0.0').toString(), equals('=1.0.0'));
      expect(
        const NeonSdkConstraint(minVersion: '1.0.0').toString(),
        equals('>=1.0.0'),
      );
    });
  });

  group('NeonPluginManifest', () {
    test('creates with required fields', () {
      const manifest = NeonPluginManifest(
        id: 'test_plugin',
        name: 'Test Plugin',
        version: '1.0.0',
      );
      expect(manifest.id, equals('test_plugin'));
      expect(manifest.isDartOnlyPlugin, isTrue);
      expect(manifest.isNativePlugin, isFalse);
    });

    test('native type is detected', () {
      const manifest = NeonPluginManifest(
        id: 'native_plugin',
        name: 'Native Plugin',
        version: '1.0.0',
        type: NeonPluginType.native,
      );
      expect(manifest.isNativePlugin, isTrue);
    });

    test('toJson includes all fields', () {
      const manifest = NeonPluginManifest(
        id: 'test',
        name: 'Test',
        version: '1.0.0',
        description: 'A test plugin',
        author: 'Tester',
        capabilities: {'logging'},
        dependencies: ['dep_a'],
      );
      final json = manifest.toJson();
      expect(json['id'], equals('test'));
      expect(json['description'], equals('A test plugin'));
      expect(json['capabilities'], contains('logging'));
      expect(json['dependencies'], contains('dep_a'));
    });

    test('parsedVersion returns semantic version', () {
      const manifest = NeonPluginManifest(
        id: 'test',
        name: 'Test',
        version: '2.1.3',
      );
      final v = manifest.parsedVersion;
      expect(v.major, equals(2));
      expect(v.minor, equals(1));
      expect(v.patch, equals(3));
    });
  });

  group('NeonPluginContext', () {
    test('stores and retrieves data', () {
      final ctx = NeonPluginContext(sdkVersion: '0.8.0');
      ctx.set<String>('key', 'value');
      expect(ctx.get<String>('key'), equals('value'));
      expect(ctx.has('key'), isTrue);
    });

    test('returns null for missing key', () {
      final ctx = NeonPluginContext(sdkVersion: '0.8.0');
      expect(ctx.get<String>('missing'), isNull);
      expect(ctx.has('missing'), isFalse);
    });

    test('removes data', () {
      final ctx = NeonPluginContext(sdkVersion: '0.8.0');
      ctx.set('key', 'value');
      ctx.remove('key');
      expect(ctx.has('key'), isFalse);
    });

    test('tracks registered plugins', () {
      final ctx = NeonPluginContext(sdkVersion: '0.8.0');
      ctx.trackRegistration('plugin_a');
      ctx.trackRegistration('plugin_b');
      expect(ctx.registeredPluginIds, containsAll(['plugin_a', 'plugin_b']));
      expect(ctx.isPluginRegistered('plugin_a'), isTrue);
      expect(ctx.isPluginRegistered('plugin_c'), isFalse);
    });
  });

  group('NeonPluginRegistry', () {
    late NeonPluginRegistry registry;

    setUp(() {
      NeonPluginRegistry.reset();
      registry = NeonPluginRegistry.instance;
      registry.initialize(sdkVersion: '0.8.0');
    });

    tearDown(() {
      NeonPluginRegistry.reset();
    });

    test('initializes correctly', () {
      expect(registry.isInitialized, isTrue);
      expect(registry.sdkVersion, equals('0.8.0'));
      expect(registry.pluginCount, equals(0));
    });

    test('registers Dart-only plugin', () {
      final plugin = _TestDartPlugin();
      registry.register(plugin);

      expect(registry.pluginCount, equals(1));
      expect(registry.hasPlugin('test_dart'), isTrue);
      expect(plugin.isRegistered, isTrue);
      expect(plugin.registerCalled, isTrue);
    });

    test('retrieves plugin by id', () {
      final plugin = _TestDartPlugin();
      registry.register(plugin);

      final retrieved = registry.getPlugin<_TestDartPlugin>('test_dart');
      expect(retrieved, same(plugin));
    });

    test('operator[] works', () {
      final plugin = _TestDartPlugin();
      registry.register(plugin);
      expect(registry['test_dart'], same(plugin));
      expect(registry['nonexistent'], isNull);
    });

    test('rejects duplicate registration', () {
      registry.register(_TestDartPlugin());

      expect(
        () => registry.register(_TestDartPlugin()),
        throwsA(isA<NeonPluginException>()),
      );
    });

    test('rejects incompatible SDK version', () {
      final plugin = _SdkConstrainedPlugin();

      expect(
        () => registry.register(plugin),
        throwsA(isA<NeonPluginException>()),
      );
    });

    test('accepts compatible SDK version', () {
      NeonPluginRegistry.reset();
      registry = NeonPluginRegistry.instance;
      registry.initialize(sdkVersion: '1.5.0');

      final plugin = _SdkConstrainedPlugin();
      registry.register(plugin);
      expect(plugin.isRegistered, isTrue);
    });

    test('rejects missing dependency', () {
      final plugin = _DependentPlugin();

      expect(
        () => registry.register(plugin),
        throwsA(isA<NeonPluginException>()),
      );
    });

    test('accepts when dependency is registered', () {
      registry.register(_TestDartPlugin());

      final plugin = _DependentPlugin();
      registry.register(plugin);
      expect(plugin.isRegistered, isTrue);
    });

    test('detects capability conflict', () {
      registry.register(_CapabilityPluginA());

      expect(
        () => registry.register(_CapabilityPluginB()),
        throwsA(isA<NeonPluginException>()),
      );
    });

    test('unregisters plugin', () {
      final plugin = _TestDartPlugin();
      registry.register(plugin);
      registry.unregister('test_dart');

      expect(registry.hasPlugin('test_dart'), isFalse);
      expect(plugin.isRegistered, isFalse);
      expect(plugin.disposeCalled, isTrue);
    });

    test('rejects unregister of non-existent plugin', () {
      expect(
        () => registry.unregister('nonexistent'),
        throwsA(isA<NeonPluginException>()),
      );
    });

    test('prevents unregister when other plugins depend on it', () {
      registry.register(_TestDartPlugin());
      registry.register(_DependentPlugin());

      expect(
        () => registry.unregister('test_dart'),
        throwsA(isA<NeonPluginException>()),
      );
    });

    test('finds plugins by capability', () {
      registry.register(_CapabilityPluginA());
      registry.register(_TestDartPlugin());

      final loggers = registry.getPluginsWithCapability('logging');
      expect(loggers.length, equals(1));
      expect(loggers.first.manifest.id, equals('cap_a'));
    });

    test('registers and executes hooks', () async {
      registry.register(_TestDartPlugin());

      registry.registerHook('test_dart', 'onSave', (arg) async {
        return 'saved: $arg';
      });

      final results = await registry.executeHook('onSave', 'data');
      expect(results.first, equals('saved: data'));
    });

    test('hook on unregistered plugin throws', () {
      expect(
        () => registry.registerHook('nonexistent', 'hook', (arg) async => null),
        throwsA(isA<NeonPluginException>()),
      );
    });

    test('getHooks returns hooks for name', () {
      registry.register(_TestDartPlugin());
      registry.registerHook('test_dart', 'onBuild', (arg) async => null);

      final hooks = registry.getHooks('onBuild');
      expect(hooks.length, equals(1));
      expect(hooks.first.pluginId, equals('test_dart'));
    });

    test('executeHook with no hooks returns empty', () async {
      final results = await registry.executeHook('nonexistent_hook');
      expect(results, isEmpty);
    });

    test('pluginIds returns registration order', () {
      registry.register(_TestDartPlugin());
      registry.register(_CapabilityPluginA());

      expect(registry.pluginIds, equals(['test_dart', 'cap_a']));
    });

    test('getRegistryStats returns correct stats', () {
      registry.register(_TestDartPlugin());

      final stats = registry.getRegistryStats();
      expect(stats['total_plugins'], equals(1));
      expect(stats['dart_only'], equals(1));
      expect(stats['native'], equals(0));
      expect(stats['sdk_version'], equals('0.8.0'));
    });

    test('context tracks registrations', () {
      registry.register(_TestDartPlugin());
      expect(registry.context.isPluginRegistered('test_dart'), isTrue);

      registry.unregister('test_dart');
      expect(registry.context.isPluginRegistered('test_dart'), isFalse);
    });

    test('dispose cleans up all plugins in reverse order', () {
      final a = _TestDartPlugin();
      final b = _CapabilityPluginA();
      registry.register(a);
      registry.register(b);

      registry.dispose();
      expect(a.disposeCalled, isTrue);
      expect(b.disposeCalled, isTrue);
      expect(registry.isInitialized, isFalse);
    });

    test('throws when not initialized', () {
      NeonPluginRegistry.reset();
      final fresh = NeonPluginRegistry.instance;
      expect(() => fresh.register(_TestDartPlugin()), throwsStateError);
    });
  });

  group('NeonLoggerPlugin', () {
    late NeonPluginRegistry registry;

    setUp(() {
      NeonPluginRegistry.reset();
      registry = NeonPluginRegistry.instance;
      registry.initialize();
    });

    tearDown(() {
      NeonPluginRegistry.reset();
    });

    test('registers and logs messages', () {
      final logger = NeonLoggerPlugin();
      registry.register(logger);

      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');
      logger.error('Error message');

      expect(logger.entries.length, greaterThanOrEqualTo(4));
    });

    test('respects minimum log level', () {
      final logger = NeonLoggerPlugin(minLevel: NeonLogLevel.warning);
      registry.register(logger);

      logger.debug('Should skip');
      logger.info('Should skip');
      logger.warning('Should appear');
      logger.error('Should appear');

      final nonRegistration = logger.entries
          .where((e) => e.message != 'NeonLoggerPlugin registered')
          .toList();
      expect(nonRegistration.length, equals(2));
    });

    test('callback receives entries', () {
      final captured = <NeonLogEntry>[];
      final logger = NeonLoggerPlugin(onLog: captured.add);
      registry.register(logger);

      logger.info('Test callback');
      expect(captured.any((e) => e.message == 'Test callback'), isTrue);
    });

    test('filters by level and tag', () {
      final logger = NeonLoggerPlugin();
      registry.register(logger);

      logger.info('HTTP request', tag: 'http');
      logger.error('DB error', tag: 'db');
      logger.info('HTTP response', tag: 'http');

      expect(logger.getByTag('http').length, equals(2));
      expect(logger.getByLevel(NeonLogLevel.error).length, equals(1));
    });

    test('stats returns counts', () {
      final logger = NeonLoggerPlugin();
      registry.register(logger);

      logger.debug('d');
      logger.info('i');
      logger.error('e');

      final stats = logger.stats;
      expect(stats['total'], greaterThanOrEqualTo(3));
    });

    test('clear removes entries', () {
      final logger = NeonLoggerPlugin();
      registry.register(logger);

      logger.info('one');
      logger.info('two');
      logger.clear();
      expect(logger.entries, isEmpty);
    });

    test('manifest is correct', () {
      final logger = NeonLoggerPlugin();
      expect(logger.manifest.id, equals('neon_logger'));
      expect(logger.manifest.isDartOnlyPlugin, isTrue);
      expect(logger.manifest.capabilities, contains('logging'));
    });

    test('is accessible from context after registration', () {
      final logger = NeonLoggerPlugin();
      registry.register(logger);

      final fromContext = registry.context.get<NeonLoggerPlugin>('logger');
      expect(fromContext, same(logger));
    });
  });

  group('NeonDeviceInfoPlugin', () {
    late NeonPluginRegistry registry;

    setUp(() {
      NeonPluginRegistry.reset();
      NeonPlatformDispatcher.reset();
      registry = NeonPluginRegistry.instance;
      registry.initialize();
    });

    tearDown(() {
      NeonPluginRegistry.reset();
      NeonPlatformDispatcher.reset();
    });

    test('registers as native plugin with channel', () {
      final deviceInfo = NeonDeviceInfoPlugin();
      registry.register(deviceInfo);

      expect(deviceInfo.isRegistered, isTrue);
      expect(deviceInfo.nativeChannel, isNotNull);
      expect(deviceInfo.nativeChannel!.name,
          equals('neon/plugin/neon_device_info'));
    });

    test('handles updateDeviceInfo message', () async {
      final deviceInfo = NeonDeviceInfoPlugin();
      registry.register(deviceInfo);

      await deviceInfo.nativeChannel!.handlePlatformMessage(
        'updateDeviceInfo',
        {
          'model': 'Pixel 8',
          'os_version': 'Android 15',
          'app_version': '1.2.0'
        },
      );

      expect(deviceInfo.deviceModel, equals('Pixel 8'));
      expect(deviceInfo.osVersion, equals('Android 15'));
      expect(deviceInfo.appVersion, equals('1.2.0'));
    });

    test('handles updateBattery message', () async {
      final deviceInfo = NeonDeviceInfoPlugin();
      registry.register(deviceInfo);

      await deviceInfo.nativeChannel!.handlePlatformMessage(
        'updateBattery',
        {'level': 0.85, 'charging': true},
      );

      expect(deviceInfo.batteryLevel, equals(0.85));
      expect(deviceInfo.isCharging, isTrue);
    });

    test('toJson returns all info', () {
      final deviceInfo = NeonDeviceInfoPlugin();
      registry.register(deviceInfo);

      final json = deviceInfo.toJson();
      expect(json.containsKey('device_model'), isTrue);
      expect(json.containsKey('os_version'), isTrue);
      expect(json.containsKey('battery_level'), isTrue);
    });

    test('manifest is correct', () {
      final deviceInfo = NeonDeviceInfoPlugin();
      expect(deviceInfo.manifest.id, equals('neon_device_info'));
      expect(deviceInfo.manifest.isNativePlugin, isTrue);
      expect(deviceInfo.manifest.capabilities, contains('device_info'));
    });

    test('unregistering closes native channel', () {
      final deviceInfo = NeonDeviceInfoPlugin();
      registry.register(deviceInfo);

      final channel = deviceInfo.nativeChannel!;
      registry.unregister('neon_device_info');

      expect(channel.isOpen, isFalse);
      expect(deviceInfo.isRegistered, isFalse);
    });

    test('is accessible from context after registration', () {
      final deviceInfo = NeonDeviceInfoPlugin();
      registry.register(deviceInfo);

      final fromContext =
          registry.context.get<NeonDeviceInfoPlugin>('device_info');
      expect(fromContext, same(deviceInfo));
    });
  });

  group('NeonPluginException', () {
    test('toString includes code and message', () {
      const e = NeonPluginException(
        'Something went wrong',
        pluginId: 'test',
        code: NeonPluginErrorCode.alreadyRegistered,
      );
      expect(e.toString(), contains('alreadyRegistered'));
      expect(e.toString(), contains('Something went wrong'));
    });
  });

  // ─── Phase 9: Performance Benchmarks & Integration Tests ───

  group('Render Pipeline Benchmarks', () {
    test('full pipeline completes under 16ms for typical widget tree', () {
      NeonApp.reset();
      NeonApp.run(const _BenchmarkApp());

      final tree = NeonApp.instance.widgetTree;
      final pipeline = NeonRenderPipeline();
      final rootElement = tree.root!;

      final stopwatch = Stopwatch()..start();

      pipeline.buildRenderTree(rootElement);
      pipeline.runPipeline(const NeonConstraints(
        minWidth: 0,
        maxWidth: 360,
        minHeight: 0,
        maxHeight: 800,
      ));

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(16),
          reason: 'Pipeline should complete within one 60fps frame budget');

      NeonApp.reset();
    });

    test('1000 sequential layouts complete efficiently', () {
      NeonApp.reset();
      NeonApp.run(const _BenchmarkApp());

      final tree = NeonApp.instance.widgetTree;
      final pipeline = NeonRenderPipeline();
      pipeline.buildRenderTree(tree.root!);

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        pipeline.rootRenderObject!.markNeedsLayout();
        pipeline.runPipeline(const NeonConstraints(
          minWidth: 0,
          maxWidth: 360,
          minHeight: 0,
          maxHeight: 800,
        ));
      }
      stopwatch.stop();

      final avgMs = stopwatch.elapsedMicroseconds / 1000 / 1000;
      expect(avgMs, lessThan(1.0),
          reason: 'Average layout+paint should be well under 1ms');

      NeonApp.reset();
    });

    test('paint produces deterministic output', () {
      NeonApp.reset();
      NeonApp.run(const _BenchmarkApp());

      final tree = NeonApp.instance.widgetTree;
      final pipeline = NeonRenderPipeline();
      pipeline.buildRenderTree(tree.root!);
      final canvas1 = pipeline.runPipeline(const NeonConstraints(
        minWidth: 0,
        maxWidth: 360,
        minHeight: 0,
        maxHeight: 800,
      ));
      final commands1 = canvas1.commands.length;

      pipeline.rootRenderObject!.markNeedsLayout();
      final canvas2 = pipeline.runPipeline(const NeonConstraints(
        minWidth: 0,
        maxWidth: 360,
        minHeight: 0,
        maxHeight: 800,
      ));
      final commands2 = canvas2.commands.length;

      expect(commands1, equals(commands2),
          reason: 'Same tree should produce same number of paint commands');

      NeonApp.reset();
    });

    test('render tree node count matches widget tree', () {
      NeonApp.reset();
      NeonApp.run(const _BenchmarkApp());

      final tree = NeonApp.instance.widgetTree;
      final pipeline = NeonRenderPipeline();
      final renderRoot = pipeline.buildRenderTree(tree.root!);

      int countRenderNodes(NeonRenderObject obj) {
        var count = 1;
        for (final child in obj.children) {
          count += countRenderNodes(child);
        }
        return count;
      }

      expect(countRenderNodes(renderRoot), equals(tree.nodeCount),
          reason:
              'Every widget element should have a corresponding render object');

      NeonApp.reset();
    });
  });

  group('Signal Performance', () {
    test('1000 signal updates complete efficiently', () {
      final signal = NeonSignal<int>(0);
      final computed = NeonComputed<int>(() => signal.value * 2);

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        signal.value = i;
        computed.value;
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: '1000 signal updates should complete quickly');
    });

    test('computed with long dependency chain', () {
      final base = NeonSignal<int>(1);
      final c1 = NeonComputed<int>(() => base.value + 1);
      final c2 = NeonComputed<int>(() => c1.value * 2);
      final c3 = NeonComputed<int>(() => c2.value + c1.value);
      final c4 = NeonComputed<int>(() => c3.value * c2.value);

      base.value = 5;
      expect(c1.value, equals(6));
      expect(c2.value, equals(12));
      expect(c3.value, equals(18));
      expect(c4.value, equals(216));
    });

    test('effect disposes cleanly without leaks', () {
      final signal = NeonSignal<int>(0);
      final log = <int>[];

      final effect = NeonEffect(() {
        log.add(signal.value);
      });

      signal.value = 1;
      signal.value = 2;
      effect.dispose();
      signal.value = 3;

      expect(log, contains(2));
      expect(log, isNot(contains(3)), reason: 'Disposed effect should not run');
    });
  });

  group('End-to-End Integration', () {
    test(
        'full app lifecycle: build -> render -> paint -> signal update -> rebuild',
        () {
      NeonApp.reset();
      NeonApp.run(const TestApp());

      expect(NeonApp.instance.isRunning, isTrue);
      expect(NeonApp.instance.widgetTree.root, isNotNull);

      final tree = NeonApp.instance.widgetTree;
      final pipeline = NeonRenderPipeline();
      pipeline.buildRenderTree(tree.root!);
      final canvas = pipeline.runPipeline(const NeonConstraints(
        minWidth: 0,
        maxWidth: 360,
        minHeight: 0,
        maxHeight: 800,
      ));

      expect(canvas.commands, isNotEmpty);
      expect(pipeline.rootRenderObject, isNotNull);
      expect(pipeline.rootRenderObject!.size.width, greaterThan(0));

      NeonApp.instance.pause();
      NeonApp.instance.resume();
      NeonApp.instance.dispose();
    });

    test('stateful widget with signals triggers rebuild tracking', () {
      final counter = NeonSignal<int>(0);
      final doubled = NeonComputed<int>(() => counter.value * 2);
      final history = <int>[];

      NeonEffect(() {
        history.add(doubled.value);
      });

      counter.value = 5;
      counter.value = 10;

      expect(history, contains(0));
      expect(history, contains(10));
      expect(history, contains(20));
    });

    test('async value lifecycle: loading -> success -> cached', () {
      var state = NeonAsyncValue<String>.loading();
      expect(state.isLoading, isTrue);

      state = NeonAsyncValue.success('Data loaded');
      expect(state.isSuccess, isTrue);
      expect(state.data, equals('Data loaded'));

      state = NeonAsyncValue.cached('Data loaded');
      expect(state.isCached, isTrue);
    });

    test('platform channel round-trip', () async {
      NeonPlatformDispatcher.reset();
      final dispatcher = NeonPlatformDispatcher.instance;

      dispatcher.setMockDispatcher((message) async {
        if (message.method == 'getInfo') {
          return {'platform': 'test', 'version': '1.0'};
        }
        return null;
      });

      final channel = NeonPlatformChannel(name: 'test/integration');
      dispatcher.registerChannel(channel);

      final result =
          await channel.invokeMethod<Map<String, dynamic>>('getInfo');
      expect(result, isNotNull);
      expect(result!['platform'], equals('test'));

      channel.close();
      NeonPlatformDispatcher.reset();
    });

    test('HTTP client with cache policy integration', () async {
      final mock = NeonMockHttpBackend();
      mock.onRequest(
          '/data',
          (req) => mock.mockResponse(
                statusCode: 200,
                body: '{"value": 42}',
                request: req,
              ));
      final client = NeonHttpClient(
        backend: mock,
        baseUrl: 'https://api.test.com',
      );

      final cacheStore =
          NeonCacheStore(defaultMaxAge: const Duration(hours: 1));
      final policy = NeonCachePolicy<String>.cacheFirst(
        store: cacheStore,
        fetcher: (key) async {
          final response = await client.get('/data');
          return response.body;
        },
      );

      final result1 = await policy.execute('api_data');
      expect(result1, contains('42'));
      expect(mock.sentRequests.length, equals(1));

      final result2 = await policy.execute('api_data');
      expect(result2, equals(result1));
      expect(mock.sentRequests.length, equals(1),
          reason: 'Second call should use cache, not network');
    });

    test('plugin registry with logger and hook and signal integration',
        () async {
      NeonPluginRegistry.reset();
      final registry = NeonPluginRegistry.instance;
      registry.initialize(sdkVersion: '0.8.0');

      final logger = NeonLoggerPlugin();
      registry.register(logger);

      final counter = NeonSignal<int>(0);
      registry.registerHook('neon_logger', 'onCounterChange', (arg) async {
        logger.info('Counter changed to $arg', tag: 'counter');
        return arg;
      });

      counter.value = 5;
      await registry.executeHook('onCounterChange', counter.value);

      expect(logger.getByTag('counter').length, equals(1));
      expect(logger.getByTag('counter').first.message, contains('5'));

      NeonPluginRegistry.reset();
    });

    test('KV store and database and HTTP client data flow', () async {
      final kv = NeonKeyValueStore();
      await kv.setString('api_base', 'https://api.example.com');

      final db = NeonDatabase(path: ':memory:');
      db.defineTable(NeonTableSchema(
        name: 'cache_entries',
        columns: [
          NeonColumn(name: 'key', type: NeonColumnType.text, primaryKey: true),
          NeonColumn(name: 'value', type: NeonColumnType.text),
          NeonColumn(name: 'timestamp', type: NeonColumnType.integer),
        ],
      ));
      await db.open();

      final mock = NeonMockHttpBackend();
      mock.onAnyRequest((req) => mock.mockResponse(
            statusCode: 200,
            body: '{"result": "ok"}',
            request: req,
          ));

      final baseUrl = await kv.getString('api_base');
      final client = NeonHttpClient(backend: mock, baseUrl: baseUrl!);
      final response = await client.get('/sync');

      await db.insert('cache_entries', {
        'key': '/sync',
        'value': response.body,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final cached = await db
          .queryTable('cache_entries', where: 'key = ?', whereArgs: ['/sync']);
      expect(cached.first!['value'], contains('ok'));

      await db.close();
    });

    test('widget tree to render pipeline to canvas verification', () {
      NeonApp.reset();

      final app = Column(children: [
        const Text('Title',
            style: NeonTextStyle(fontSize: 20, color: NeonColor(0xFF000000))),
        Container(
          width: 200,
          height: 50,
          color: const NeonColor(0xFFFF0000),
          child: const Text('Inside'),
        ),
      ]);

      final tree = NeonWidgetTree();
      final ctx = NeonBuildContext(config: const NeonConfig());
      tree.buildTree(app, ctx);

      final pipeline = NeonRenderPipeline();
      pipeline.buildRenderTree(tree.root!);
      final canvas = pipeline.runPipeline(const NeonConstraints(
        minWidth: 0,
        maxWidth: 400,
        minHeight: 0,
        maxHeight: 600,
      ));

      final drawTextCmds = canvas.commands
          .where((c) => c.type == NeonPaintCommandType.drawText)
          .toList();
      final drawRectCmds = canvas.commands
          .where((c) => c.type == NeonPaintCommandType.drawRect)
          .toList();

      expect(drawTextCmds.length, equals(2),
          reason: 'Should paint Title and Inside');
      expect(drawRectCmds.length, equals(1),
          reason: 'Should paint the Container background');

      expect(drawTextCmds[0].params['text'], equals('Title'));
      expect(drawTextCmds[1].params['text'], equals('Inside'));
    });

    test('WebSocket with signal reactive update', () async {
      final mock = NeonMockWebSocketBackend();
      final ws = NeonWebSocket(backend: mock);
      await ws.connect('ws://test.com');

      final messages = NeonSignal<List<String>>([]);

      ws.onMessage((msg) {
        messages.value = [...messages.value, msg.data];
      });

      mock.simulateMessage('hello');
      mock.simulateMessage('world');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(messages.value, containsAll(['hello', 'world']));

      await ws.close();
    });

    test('animation value interpolation accuracy', () {
      final anim = NeonAnimationValue(begin: 0.0, end: 100.0);

      expect(anim.isAtStart, isTrue);
      expect(anim.isComplete, isFalse);

      final mid = anim.withProgress(0.5);
      expect(mid.progress, equals(0.5));
      expect(mid.isComplete, isFalse);

      final done = anim.withProgress(1.0);
      expect(done.isComplete, isTrue);

      final curvedValue = NeonCurves.easeIn.transform(0.5);
      expect(curvedValue, greaterThan(0));
      expect(curvedValue, lessThan(1));
    });

    test('render pipeline handles empty widget', () {
      final tree = NeonWidgetTree();
      final ctx = NeonBuildContext(config: const NeonConfig());
      tree.buildTree(const Text(''), ctx);

      final pipeline = NeonRenderPipeline();
      pipeline.buildRenderTree(tree.root!);
      final canvas = pipeline.runPipeline(const NeonConstraints(
        minWidth: 0,
        maxWidth: 360,
        minHeight: 0,
        maxHeight: 800,
      ));

      expect(canvas.commands, isNotEmpty);
    });

    test('file system path sandboxing', () async {
      final fs = NeonFileSystem(
        channel: NeonPlatformChannel(name: 'test/fs'),
      );

      expect(NeonStorageLocation.appDocuments, isNotNull);
      expect(NeonStorageLocation.appCache, isNotNull);
      expect(NeonStorageLocation.appSupport, isNotNull);
      expect(NeonStorageLocation.temp, isNotNull);
      expect(NeonStorageLocation.values.length, equals(4));
    });

    group('Extended Widget System', () {
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

      test('FloatingActionButton builds correctly', () {
        var tapped = false;
        final fab = FloatingActionButton(
          onPressed: () => tapped = true,
          variant: FABVariant.large,
          child: const Text('+'),
        );
        final context = NeonBuildContext(config: const NeonConfig());
        final built = fab.build(context) as Button;
        built.tap();
        expect(tapped, isTrue);
      });

      test('IconButton variants', () {
        final context = NeonBuildContext(config: const NeonConfig());
        const filled =
            IconButton(icon: Text(''), variant: IconButtonVariant.filled);
        expect((filled.build(context) as Button).color, equals(NeonColor.blue));
      });

      test('Material 3 Buttons build into Button', () {
        final context = NeonBuildContext(config: const NeonConfig());
        const button = FilledTonalButton(child: Text('Tonal'));
        final built = button.build(context) as Button;
        expect(built.color, equals(const NeonColor(0xFFEADDFF)));
      });

      test('NavigationBar destinations', () {
        final nav = NavigationBar(
          destinations: const [
            NavigationDestination(icon: Text('H'), label: 'Home'),
          ],
          selectedIndex: 0,
        );
        expect(nav.destinations.length, equals(1));
        expect(nav.destinations[0].label, equals('Home'));
      });

      test('SegmentedButton builds LeafWidget', () {
        final context = NeonBuildContext(config: const NeonConfig());
        const button = SegmentedButton(segments: [], selectedIndex: 0);
        final built = button.build(context);
        expect(built, isA<LeafWidget>());
        expect((built as LeafWidget).type, equals('SegmentedButton'));
      });
    });
  });
}

class _TestDartPlugin extends NeonDartPlugin {
  bool registerCalled = false;
  bool disposeCalled = false;

  @override
  NeonPluginManifest get manifest => const NeonPluginManifest(
        id: 'test_dart',
        name: 'Test Dart Plugin',
        version: '1.0.0',
      );

  @override
  void onRegister(NeonPluginContext context) {
    registerCalled = true;
  }

  @override
  void onDispose() {
    disposeCalled = true;
  }
}

class _SdkConstrainedPlugin extends NeonDartPlugin {
  @override
  NeonPluginManifest get manifest => const NeonPluginManifest(
        id: 'sdk_constrained',
        name: 'SDK Constrained',
        version: '1.0.0',
        sdkConstraint:
            NeonSdkConstraint(minVersion: '1.0.0', maxVersion: '2.0.0'),
      );

  @override
  void onRegister(NeonPluginContext context) {}

  @override
  void onDispose() {}
}

class _DependentPlugin extends NeonDartPlugin {
  @override
  NeonPluginManifest get manifest => const NeonPluginManifest(
        id: 'dependent',
        name: 'Dependent Plugin',
        version: '1.0.0',
        dependencies: ['test_dart'],
      );

  @override
  void onRegister(NeonPluginContext context) {}

  @override
  void onDispose() {}
}

class _CapabilityPluginA extends NeonDartPlugin {
  bool disposeCalled = false;

  @override
  NeonPluginManifest get manifest => const NeonPluginManifest(
        id: 'cap_a',
        name: 'Capability A',
        version: '1.0.0',
        capabilities: {'logging'},
      );

  @override
  void onRegister(NeonPluginContext context) {}

  @override
  void onDispose() {
    disposeCalled = true;
  }
}

class _CapabilityPluginB extends NeonDartPlugin {
  @override
  NeonPluginManifest get manifest => const NeonPluginManifest(
        id: 'cap_b',
        name: 'Capability B',
        version: '1.0.0',
        capabilities: {'logging'},
      );

  @override
  void onRegister(NeonPluginContext context) {}

  @override
  void onDispose() {}
}

class _BenchmarkApp extends StatelessWidget {
  const _BenchmarkApp({super.key});

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(children: [
      const Text('Header',
          style: NeonTextStyle(fontSize: 24, fontWeight: NeonFontWeight.bold)),
      Row(children: [
        Button(
          child: const Text('Action A'),
          onPressed: () {},
          color: const NeonColor(0xFF0000FF),
        ),
        Button(
          child: const Text('Action B'),
          onPressed: () {},
          color: const NeonColor(0xFF00FF00),
        ),
      ]),
      Container(
        width: 300,
        height: 200,
        color: const NeonColor(0xFFEEEEEE),
        padding: const NeonEdgeInsets.all(16),
        child: Column(children: [
          const Text('Item 1'),
          const Text('Item 2'),
          const Text('Item 3'),
          Row(children: [
            const Text('Nested A'),
            const Text('Nested B'),
          ]),
        ]),
      ),
    ]);
  }
}

import 'package:neon_framework/neon.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(
      children: [
        const Text(
          'Welcome to Neon!',
          style: NeonTextStyle(
            fontSize: 24.0,
            fontWeight: NeonFontWeight.bold,
            color: NeonColor.blue,
          ),
        ),
        const Text('A Dart-based mobile framework'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Button(
              onPressed: () {},
              color: NeonColor.blue,
              child: const Text(
                'Get Started',
                style: NeonTextStyle(color: NeonColor.white),
              ),
            ),
            Button(
              onPressed: () {},
              color: NeonColor.grey,
              child: const Text(
                'Learn More',
                style: NeonTextStyle(color: NeonColor.white),
              ),
            ),
          ],
        ),
        const Container(
          width: 300,
          height: 100,
          color: NeonColor.white,
          padding: NeonEdgeInsets.all(16.0),
          child: Text('Content area'),
        ),
      ],
    );
  }
}

Future<void> main() async {
  final config = const NeonConfig(
    environment: NeonEnvironment.development,
    buildFlavor: NeonBuildFlavor(name: 'free'),
    featureFlags: NeonFeatureFlags({'dark_mode': true}),
  );

  NeonApp.run(const MyApp(), config: config);

  final app = NeonApp.instance;

  // ignore: avoid_print
  print('--- Widget Tree ---');
  app.widgetTree.printTree();

  // ignore: avoid_print
  print('--- Render Pipeline ---');

  final deviceInfo = const NeonDeviceInfo(
    devicePixelRatio: 3.0,
    screenSize: NeonSize(360, 800),
    physicalSize: NeonSize(1080, 2400),
  );

  final pipeline = NeonRenderPipeline(deviceInfo: deviceInfo);

  final rootElement = app.widgetTree.root!;
  pipeline.buildRenderTree(rootElement);

  final screenConstraints = NeonConstraints.tight(deviceInfo.screenSize);
  final canvas = pipeline.runPipeline(screenConstraints);

  // ignore: avoid_print
  print('Render tree:');
  // ignore: avoid_print
  print(pipeline.debugDump());

  // ignore: avoid_print
  print('Paint commands: ${canvas.commandCount}');
  for (final cmd in canvas.commands) {
    // ignore: avoid_print
    print('  ${cmd.type}: ${cmd.params}');
  }

  // ignore: avoid_print
  print('\n--- Animation Foundation ---');
  const anim = NeonAnimationValue<double>(begin: 0.0, end: 1.0);
  // ignore: avoid_print
  print('Animation: $anim');
  final mid = anim.withProgress(0.5);
  // ignore: avoid_print
  print('At 50%: $mid');

  // ignore: avoid_print
  print('Curves:');
  for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
    // ignore: avoid_print
    print(
        '  t=$t -> easeIn=${NeonCurves.easeIn.transform(t).toStringAsFixed(3)}, easeOut=${NeonCurves.easeOut.transform(t).toStringAsFixed(3)}');
  }

  // ignore: avoid_print
  print('\n--- State Management (Signals) ---');

  final counter = NeonSignal<int>(0);
  // ignore: avoid_print
  print('Counter: ${counter.value}');

  counter.listen(() {
    // ignore: avoid_print
    print('Counter changed to: ${counter.peek()}');
  });

  counter.value = 1;
  counter.value = 2;
  counter.update((c) => c + 1);
  // ignore: avoid_print
  print('Final counter: ${counter.value}');

  final doubled = NeonComputed<int>(() => counter.value * 2);
  // ignore: avoid_print
  print('Doubled: ${doubled.value}');

  counter.value = 10;
  // ignore: avoid_print
  print('Doubled after update: ${doubled.value}');

  final effectLog = <String>[];
  final effect = NeonEffect(() {
    effectLog.add('counter is ${counter.value}');
  });
  counter.value = 42;
  // ignore: avoid_print
  print('Effect log: $effectLog');

  // ignore: avoid_print
  print('\n--- Async Values ---');
  const loading = NeonAsyncValue<String>.loading();
  // ignore: avoid_print
  print(loading);

  const success = NeonAsyncValue<String>.success('Hello');
  // ignore: avoid_print
  print(success);
  // ignore: avoid_print
  print('Data: ${success.data}');

  final errorVal = NeonAsyncValue<String>.error('Network failed');
  // ignore: avoid_print
  print(errorVal);

  final result = success.when(
    loading: () => 'Loading...',
    success: (data) => 'Got: $data',
    error: (e, st) => 'Error: $e',
  );
  // ignore: avoid_print
  print('When result: $result');

  effect.dispose();
  doubled.dispose();
  counter.dispose();

  // ignore: avoid_print
  print('\n--- Platform Integration ---');

  final bridge = NeonPlatformBridge.instance;
  bridge.initialize(platform: NeonTargetPlatform.android);
  // ignore: avoid_print
  print('Platform: ${bridge.platform?.name}');
  // ignore: avoid_print
  print('Initialized: ${bridge.isInitialized}');

  bridge.platformInfo.setMockValues(
    osVersion: 'Android 14',
    deviceModel: 'Pixel 8 Pro',
    devicePixelRatio: 2.75,
    screenSize: const NeonSize(412, 892),
    safeArea: const NeonEdgeInsetsData(top: 48, bottom: 24),
    isDarkMode: true,
  );

  // ignore: avoid_print
  print('Device: ${bridge.platformInfo}');
  // ignore: avoid_print
  print('Safe area: ${bridge.platformInfo.safeArea}');

  final renderer = bridge.nativeRenderer;
  await renderer.initialize(const NeonSize(412, 892), 2.75);
  // ignore: avoid_print
  print('Renderer ready: ${renderer.isReady}');

  final demoCanvas = NeonCanvas();
  demoCanvas.drawRect(const NeonRect(0, 0, 412, 892), color: NeonColor.white);
  demoCanvas.drawText('Hello from Neon!', const NeonOffset(50, 100));
  await renderer.submitFrame(demoCanvas);
  // ignore: avoid_print
  print(
      'Frame submitted: ${renderer.frameCount} frames, avg ${renderer.averageFrameTimeMs.toStringAsFixed(2)}ms');

  final fs = bridge.fileSystem;
  fs.enableMock();
  await fs.writeFile('settings.json', '{"theme": "dark"}');
  final settings = await fs.readFile('settings.json');
  // ignore: avoid_print
  print('File content: $settings');

  final lifecycleBridge = bridge.platformLifecycle;
  lifecycleBridge.simulateNativeEvent(NeonNativeLifecycleEvent.onResume);
  // ignore: avoid_print
  print('Lifecycle events: ${lifecycleBridge.eventLog}');

  NeonPlatformBridge.reset();

  // ignore: avoid_print
  print('\n--- Tooling (CLI & Hot Reload) ---');

  NeonCli();
  // ignore: avoid_print
  print('CLI version: ${NeonCli.version}');

  final template = const NeonProjectTemplate(
    projectName: 'demo_app',
    template: 'app',
  );
  final files = template.generate();
  // ignore: avoid_print
  print('App template files: ${files.keys.toList()}');

  final minimalTemplate = const NeonProjectTemplate(
    projectName: 'mini_app',
    template: 'minimal',
  );
  final minimalFiles = minimalTemplate.generate();
  // ignore: avoid_print
  print('Minimal template files: ${minimalFiles.keys.toList()}');

  final engine = HotReloadEngine(
    projectPath: '.',
    watchPaths: ['lib/'],
    mode: HotReloadMode.statePreserving,
    onReload: (event) {
      // ignore: avoid_print
      print('  Reload: ${event.description}');
    },
  );
  // ignore: avoid_print
  print('Hot reload mode: ${engine.mode.name}');
  // ignore: avoid_print
  print('Hot reload running: ${engine.isRunning}');

  // ignore: avoid_print
  print('\n--- Storage & Networking ---');

  final kv = NeonKeyValueStore();
  await kv.setString('theme', 'dark');
  await kv.setInt('launch_count', 7);
  await kv.setBool('onboarded', true);
  await kv.setJson('user', {'name': 'Alice', 'level': 5});
  // ignore: avoid_print
  print('KV theme: ${await kv.getString("theme")}');
  // ignore: avoid_print
  print('KV launch_count: ${await kv.getInt("launch_count")}');
  // ignore: avoid_print
  print('KV onboarded: ${await kv.getBool("onboarded")}');
  // ignore: avoid_print
  print('KV user: ${await kv.getJson("user")}');

  final db = NeonDatabase(path: 'app.db');
  db.defineTable(const NeonTableSchema(
    name: 'todos',
    columns: [
      NeonColumn(
          name: 'id',
          type: NeonColumnType.integer,
          primaryKey: true,
          autoIncrement: true),
      NeonColumn(name: 'title', type: NeonColumnType.text, nullable: false),
      NeonColumn(name: 'done', type: NeonColumnType.integer, defaultValue: 0),
    ],
  ));
  await db.open();
  await db.insert('todos', {'id': 1, 'title': 'Build Neon app', 'done': 0});
  await db.insert('todos', {'id': 2, 'title': 'Write tests', 'done': 1});
  final todos = await db.queryTable('todos');
  // ignore: avoid_print
  print('Todos: ${todos.all}');
  await db.close();

  final mockHttp = NeonMockHttpBackend();
  mockHttp.onRequest(
      '/users',
      (req) => mockHttp.mockResponse(
            statusCode: 200,
            body: '{"users": [{"name": "Alice"}, {"name": "Bob"}]}',
            request: req,
          ));
  final httpClient = NeonHttpClient(
    backend: mockHttp,
    baseUrl: 'https://api.example.com',
    defaultHeaders: NeonHttpHeaders({'x-api-key': 'neon-secret'}),
  );
  final usersResponse = await httpClient.get('/users');
  // ignore: avoid_print
  print('HTTP GET /users: ${usersResponse.statusCode} — ${usersResponse.body}');

  final mockWs = NeonMockWebSocketBackend();
  final ws = NeonWebSocket(backend: mockWs);
  await ws.connect('ws://chat.example.com');
  ws.onMessage((msg) {
    // ignore: avoid_print
    print('WS received: ${msg.data}');
  });
  ws.sendJson({'type': 'join', 'room': 'neon-dev'});
  mockWs.simulateMessage('{"type": "welcome", "msg": "Hello!"}');
  await Future.delayed(const Duration(milliseconds: 10));
  // ignore: avoid_print
  print('WS sent: ${mockWs.sentMessages}');
  await ws.close();

  final cacheStore = NeonCacheStore(defaultMaxAge: const Duration(minutes: 5));
  final cachePolicy = NeonCachePolicy<String>.cacheFirst(
    store: cacheStore,
    fetcher: (key) async => 'fetched_$key',
  );
  final cached1 = await cachePolicy.execute('greeting');
  // ignore: avoid_print
  print('Cache policy (miss): $cached1');
  final cached2 = await cachePolicy.execute('greeting');
  // ignore: avoid_print
  print('Cache policy (hit): $cached2');
  // ignore: avoid_print
  print('Cache stats: ${cacheStore.stats}');

  // ignore: avoid_print
  print('\n--- Plugins & Extensibility ---');

  NeonPluginRegistry.reset();
  final pluginRegistry = NeonPluginRegistry.instance;
  pluginRegistry.initialize(sdkVersion: '0.8.0');

  final logger = NeonLoggerPlugin();
  pluginRegistry.register(logger);
  // ignore: avoid_print
  print('Logger registered: ${logger.isRegistered}');
  logger.debug('App starting', tag: 'app');
  logger.info('User logged in', tag: 'auth');
  logger.warning('Low memory', tag: 'system');
  logger.error('Failed to fetch', tag: 'http');
  // ignore: avoid_print
  print('Log entries: ${logger.entries.length}');
  // ignore: avoid_print
  print('Log stats: ${logger.stats}');
  // ignore: avoid_print
  print(
      'HTTP logs: ${logger.getByTag("http").map((e) => e.toString()).toList()}');

  NeonPlatformDispatcher.reset();
  final deviceInfoPlugin = NeonDeviceInfoPlugin();
  pluginRegistry.register(deviceInfoPlugin);
  // ignore: avoid_print
  print('DeviceInfo registered: ${deviceInfoPlugin.isRegistered}');
  // ignore: avoid_print
  print('DeviceInfo channel: ${deviceInfoPlugin.nativeChannel.name}');

  await deviceInfoPlugin.nativeChannel.handlePlatformMessage(
    'updateDeviceInfo',
    {
      'model': 'Pixel 8 Pro',
      'os_version': 'Android 15',
      'app_version': '2.0.0'
    },
  );
  await deviceInfoPlugin.nativeChannel.handlePlatformMessage(
    'updateBattery',
    {'level': 0.92, 'charging': false},
  );
  // ignore: avoid_print
  print('Device: ${deviceInfoPlugin.toJson()}');

  pluginRegistry.registerHook('neon_logger', 'onAppPause', (arg) async {
    logger.info('App pausing — flushing logs');
    return logger.entries.length;
  });
  final hookResults = await pluginRegistry.executeHook('onAppPause');
  // ignore: avoid_print
  print('Hook results: $hookResults');

  // ignore: avoid_print
  print('Registry stats: ${pluginRegistry.getRegistryStats()}');
  pluginRegistry.dispose();

  app.dispose();
  // ignore: avoid_print
  print('\n--- Done ---');
}

import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:neon_framework/neon.dart';

void main() {
  group('NeonFeatureOptions Subsystem Defaults & copyWith', () {
    test('DiffingOptions default values & copyWith', () {
      const diffing = DiffingOptions();
      expect(diffing.enabled, isTrue);
      expect(diffing.maxPatchBatchSize, equals(150));
      expect(diffing.enableRecoveryFallback, isTrue);
      expect(diffing.preserveNativeFocus, isTrue);
      expect(diffing.patchVersion, equals(1));

      final customized = diffing.copyWith(
        enabled: false,
        maxPatchBatchSize: 50,
      );
      expect(customized.enabled, isFalse);
      expect(customized.maxPatchBatchSize, equals(50));
      expect(customized.enableRecoveryFallback, isTrue);
    });

    test('NavigationOptions default values & copyWith', () {
      const nav = NavigationOptions();
      expect(nav.enableTelemetry, isTrue);
      expect(nav.enableSyntheticBackstack, isTrue);
      expect(nav.strictPathMatching, isFalse);
      expect(nav.maxRedirectDepth, equals(5));

      final modified = nav.copyWith(strictPathMatching: true);
      expect(modified.strictPathMatching, isTrue);
      expect(modified.enableTelemetry, isTrue);
    });

    test('RenderingOptions default values & copyWith', () {
      const rendering = RenderingOptions();
      expect(rendering.enableSpringAnimations, isTrue);
      expect(rendering.strictConstraintValidation, isTrue);
      expect(rendering.frameRenderLogging, isTrue);

      final modified = rendering.copyWith(frameRenderLogging: false);
      expect(modified.frameRenderLogging, isFalse);
    });

    test('DataOptions default values & copyWith', () {
      const data = DataOptions();
      expect(data.networkTimeoutMs, equals(15000));
      expect(data.webSocketAutoReconnect, isTrue);
      expect(data.maxCacheEntries, equals(200));
      expect(data.defaultCacheTtlSeconds, equals(300));
    });

    test('DiagnosticsOptions default values & copyWith', () {
      const diag = DiagnosticsOptions();
      expect(diag.enableWebInspector, isTrue);
      expect(diag.enableTimeTravelSnapshots, isTrue);
      expect(diag.maxSnapshotHistory, equals(20));
      expect(diag.verboseActionLogging, isTrue);
    });
  });

  group('NeonFeatureOptions Serialization', () {
    test('toJson and fromJson preserves all options', () {
      final original = NeonFeatureOptions(
        diffing: const DiffingOptions(enabled: false, maxPatchBatchSize: 75),
        navigation: const NavigationOptions(strictPathMatching: true),
        rendering: const RenderingOptions(enableSpringAnimations: false),
        data: const DataOptions(networkTimeoutMs: 30000),
        diagnostics: const DiagnosticsOptions(verboseActionLogging: false),
      );

      final json = original.toJson();
      final restored = NeonFeatureOptions.fromJson(json);

      expect(restored.diffing.enabled, isFalse);
      expect(restored.diffing.maxPatchBatchSize, equals(75));
      expect(restored.navigation.strictPathMatching, isTrue);
      expect(restored.rendering.enableSpringAnimations, isFalse);
      expect(restored.data.networkTimeoutMs, equals(30000));
      expect(restored.diagnostics.verboseActionLogging, isFalse);
    });

    test('fromJson handles partial maps gracefully with defaults', () {
      final partial = {
        'diffing': {'enabled': false},
      };

      final restored = NeonFeatureOptions.fromJson(partial);
      expect(restored.diffing.enabled, isFalse);
      expect(restored.diffing.maxPatchBatchSize, equals(150));
      expect(restored.navigation.enableTelemetry, isTrue);
      expect(restored.rendering.enableSpringAnimations, isTrue);
    });
  });

  group('NeonFeatureOptionsManager Reactive State & Listener', () {
    test('manager notifies listeners on update and mutate', () {
      final manager = NeonFeatureOptionsManager();
      expect(manager.current.diffing.enabled, isTrue);

      NeonFeatureOptions? notifiedOptions;
      manager.addListener((opts) {
        notifiedOptions = opts;
      });

      manager.mutate((curr) => curr.copyWith(
            diffing: curr.diffing.copyWith(enabled: false),
          ));

      expect(manager.current.diffing.enabled, isFalse);
      expect(notifiedOptions, isNotNull);
      expect(notifiedOptions!.diffing.enabled, isFalse);
    });

    test('manager updates from JSON cleanly', () {
      final manager = NeonFeatureOptionsManager();
      manager.updateFromJson({
        'data': {'networkTimeoutMs': 8000},
      });

      expect(manager.current.data.networkTimeoutMs, equals(8000));
      expect(manager.current.diffing.enabled, isTrue);
    });
  });

  group('NeonConfig Integration with Feature Options', () {
    test('NeonConfig carries featureOptions by default', () {
      const config = NeonConfig();
      expect(config.featureOptions.diffing.enabled, isTrue);
      expect(config.featureOptions.navigation.enableTelemetry, isTrue);
    });

    test('NeonConfig copyWith preserves featureOptions', () {
      final customOptions = NeonFeatureOptions(
        diffing: const DiffingOptions(enabled: false),
      );
      final config = NeonConfig(featureOptions: customOptions);
      expect(config.featureOptions.diffing.enabled, isFalse);

      final updated = config.copyWith(port: 9090);
      expect(updated.port, equals(9090));
      expect(updated.featureOptions.diffing.enabled, isFalse);
    });
  });

  group('NeonApp Feature Options API Integration', () {
    tearDown(() {
      try {
        NeonApp.instance.dispose();
      } catch (_) {}
    });

    test('NeonApp initializes featureOptionsManager and serves /api/feature-options',
        () async {
      final rootWidget = Container(child: const Text('Options Test'));
      NeonApp.run(
        rootWidget,
        config: const NeonConfig(
          port: 0,
          featureOptions: NeonFeatureOptions(
            diffing: DiffingOptions(enabled: true, maxPatchBatchSize: 99),
          ),
        ),
      );

      // Give the server time to start
      await Future.delayed(const Duration(milliseconds: 500));

      final app = NeonApp.instance;
      expect(app.featureOptionsManager.current.diffing.maxPatchBatchSize, equals(99));

      // Test GET /api/feature-options
      final client = HttpClient();
      final getReq = await client.get('127.0.0.1', app.port, '/api/feature-options');
      final getResp = await getReq.close();
      expect(getResp.statusCode, equals(HttpStatus.ok));

      final getBody = await utf8.decoder.bind(getResp).join();
      final getJson = jsonDecode(getBody) as Map<String, dynamic>;
      expect(getJson['diffing']['maxPatchBatchSize'], equals(99));

      // Test POST /api/feature-options
      final postReq = await client.post('127.0.0.1', app.port, '/api/feature-options');
      postReq.headers.contentType = ContentType.json;
      postReq.write(jsonEncode({
        'diffing': {'enabled': false, 'maxPatchBatchSize': 200},
      }));
      final postResp = await postReq.close();
      expect(postResp.statusCode, equals(HttpStatus.ok));

      final postBody = await utf8.decoder.bind(postResp).join();
      final postJson = jsonDecode(postBody) as Map<String, dynamic>;
      expect(postJson['success'], isTrue);
      expect(app.featureOptionsManager.current.diffing.enabled, isFalse);
      expect(app.featureOptionsManager.current.diffing.maxPatchBatchSize, equals(200));

      client.close();
    });
  });
}

import 'dart:io';
import 'package:neon_framework/neon.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 1: NeonLang (.neon) Compiler & Dart Interop', () {
    const sampleNeonSource = '''
module app.screens

import "package:neon_framework/neon.dart"
import "models/task_model.dart"

@state count: Int = 0
@state tasks: List<String> = ["Design NeonLang", "Build Neon Studio"]

component TaskStudioScreen {
    route: "/tasks"

    view {
        Scaffold(title: "Neon Task Studio") {
            Column(padding: 16.dp, gap: 12.dp) {
                Text("Active Tasks")
                    .font(size: 20, weight: .bold)
                    .color(#4F46E5)

                ForEach(tasks) -> item {
                    Card(elevation: 2) {
                        Row(align: .spaceBetween) {
                            Text(item)
                            Badge("High")
                        }
                    }
                }

                Button("+ Increment") {
                    count += 1
                }
                .padding(8.dp)
            }
        }
    }
}
''';

    test('Lexer tokenizes annotations, hex colors, units, and enum shorthands', () {
      final lexer = NeonLexer(sampleNeonSource);
      final tokens = lexer.tokenize();

      expect(
        tokens.any((t) => t.type == NeonTokenType.annotationState && t.lexeme == '@state'),
        isTrue,
      );
      expect(
        tokens.any(
          (t) => t.type == NeonTokenType.unitLiteral && t.lexeme == '16' && t.unitSuffix == 'dp',
        ),
        isTrue,
      );
      expect(
        tokens.any((t) => t.type == NeonTokenType.hexColorLiteral && t.lexeme == '#4F46E5'),
        isTrue,
      );
      expect(
        tokens.any((t) => t.type == NeonTokenType.enumShorthand && t.lexeme == 'bold'),
        isTrue,
      );
    });

    test('Compiler compiles .neon into valid NeonStatefulWidget Dart code with Dart interop', () {
      const compiler = NeonCompiler();
      final result = compiler.compileSource(sampleNeonSource);

      expect(result.isSuccess, isTrue);
      expect(result.diagnostics, isEmpty);
      expect(result.routes['/tasks'], equals('TaskStudioScreen'));
      expect(result.sourceMap, isNotEmpty);

      // Verify generated Dart code preserves .dart imports & uses Neon Framework widgets
      expect(result.dartCode, contains("import 'models/task_model.dart';"));
      expect(result.dartCode, contains('class TaskStudioScreen extends NeonStatefulWidget'));
      expect(result.dartCode, contains('int count = 0;'));
      expect(result.dartCode, contains('NeonScaffold('));
      expect(result.dartCode, contains('const NeonColor(0xFF4F46E5)'));
      expect(result.dartCode, contains('setState(() { count += 1; })'));
    });

    test('Semantic analyzer catches unknown widgets and invalid route prefixes', () {
      const invalidNeon = '''
component BrokenScreen {
    route: "invalid_route_without_slash"
    view {
        NonExistentMagicWidget()
    }
}
''';
      const compiler = NeonCompiler();
      final result = compiler.compileSource(invalidNeon);

      expect(result.diagnostics.any((d) => d.code == 'NEON202'), isTrue);
      expect(result.diagnostics.any((d) => d.code == 'NEON203'), isTrue);
    });
  });

  group('Phase 2: Universal Cross-OS Mobile Packaging (.apk, .bundle, .app, .ipa)', () {
    late Directory tempOutDir;

    setUp(() {
      tempOutDir = Directory.systemTemp.createTempSync('neon_cross_os_test_');
    });

    tearDown(() {
      if (tempOutDir.existsSync()) {
        tempOutDir.deleteSync(recursive: true);
      }
    });

    for (final host in NeonHostOs.values) {
      test('Builds signed Android .apk and .aab/.bundle on ${host.name.toUpperCase()}', () {
        const builder = NeonCrossOsBuilder();

        final apkResult = builder.build(NeonPackageBuildRequest(
          appName: 'NeonTaskStudio',
          bundleId: 'dev.neonframework.todo',
          version: '1.0.0',
          buildNumber: 10,
          format: NeonPackageFormat.apk,
          hostOs: host,
          outputDirectory: tempOutDir.path,
        ));

        expect(apkResult.success, isTrue);
        expect(apkResult.signed, isTrue);
        expect(apkResult.hostOs, equals(host));
        expect(apkResult.artifactPath, endsWith('.apk'));
        expect(File(apkResult.artifactPath).existsSync(), isTrue);

        final bundleResult = builder.build(NeonPackageBuildRequest(
          appName: 'NeonTaskStudio',
          bundleId: 'dev.neonframework.todo',
          version: '1.0.0',
          buildNumber: 10,
          format: NeonPackageFormat.bundle,
          hostOs: host,
          outputDirectory: tempOutDir.path,
        ));

        expect(bundleResult.success, isTrue);
        expect(bundleResult.artifactPath, endsWith('.aab'));
        expect(File(bundleResult.artifactPath).existsSync(), isTrue);
      });

      test('Builds signed iOS .app and .ipa on ${host.name.toUpperCase()} without Xcode lock-in', () {
        const builder = NeonCrossOsBuilder();

        final appResult = builder.build(NeonPackageBuildRequest(
          appName: 'NeonTaskStudio',
          bundleId: 'dev.neonframework.todo',
          version: '1.0.0',
          buildNumber: 10,
          format: NeonPackageFormat.app,
          hostOs: host,
          outputDirectory: tempOutDir.path,
        ));

        expect(appResult.success, isTrue);
        expect(appResult.hostOs, equals(host));
        expect(appResult.artifactPath, endsWith('NeonTaskStudio.app'));
        expect(File('${appResult.artifactPath}/Info.plist').existsSync(), isTrue);
        expect(
          File('${appResult.artifactPath}/_CodeSignature/CodeResources').existsSync(),
          isTrue,
        );

        final ipaResult = builder.build(NeonPackageBuildRequest(
          appName: 'NeonTaskStudio',
          bundleId: 'dev.neonframework.todo',
          version: '1.0.0',
          buildNumber: 10,
          format: NeonPackageFormat.ipa,
          hostOs: host,
          outputDirectory: tempOutDir.path,
        ));

        expect(ipaResult.success, isTrue);
        expect(ipaResult.signed, isTrue);
        expect(ipaResult.artifactPath, endsWith('.ipa'));
        expect(File(ipaResult.artifactPath).existsSync(), isTrue);
      });
    }
  });

  group('Phase 3 & 4: neon-lsp, neon-mcp-server, and Google Antigravity Agents', () {
    test('NeonLspServer provides completions, hover docs, and diagnostics', () {
      final lsp = NeonLspServer();
      final initResp = lsp.handleRequest(<String, dynamic>{
        'id': 1,
        'method': 'initialize',
      });
      expect((initResp['result'] as Map<String, dynamic>)['serverInfo']['name'], equals('neon-lsp'));

      final modCompletions = lsp.provideCompletions(prefix: '.');
      expect(modCompletions.any((c) => c.label == '.padding'), isTrue);

      final stateCompletions = lsp.provideCompletions(prefix: '@');
      expect(stateCompletions.any((c) => c.label == '@state'), isTrue);

      final hover = lsp.provideHover('Scaffold');
      expect(hover, contains('Scaffold'));
    });

    test('NeonAntigravityAgentHub configures subagents and dispatches MCP tasks', () {
      final hub = NeonAntigravityAgentHub(
        backend: NeonAntigravityModelBackend.liteRtOnDevice,
      );

      expect(hub.subagents.length, equals(4));

      final uiTask = hub.dispatchSubagentTask(
        role: NeonSubagentRole.uiArchitect,
        prompt: 'Compile QuickCard component',
        toolArgs: <String, dynamic>{
          'source': 'component QuickCard { route: "/card" view { Text("Hi") } }',
        },
      );

      expect(uiTask['status'], equals('completed'));
      final toolOut = uiTask['toolOutput'] as Map<String, dynamic>;
      expect(toolOut['isSuccess'], isTrue);
      expect(toolOut['dartCode'], contains('class QuickCard extends NeonStatelessWidget'));

      final pyScript = hub.generateAntigravitySdkPythonConfig();
      expect(pyScript, contains('LiteRTAgentConfig'));
      expect(pyScript, contains('LocalAgentConfig'));
      expect(pyScript, contains('LocalOpenAIAgentConfig'));
      expect(pyScript, contains('neon_release_packager'));
    });
  });

  group('Phase 5: Neon Studio IDE Workbench (Xcode + Android Studio + Neon Features)', () {
    test('Extracts Route Storyboard, 3D Widget Hierarchy, and Time-Travel Scrubber', () {
      final ide = NeonStudioIdeWorkbench();
      ide.openOrUpdateFile(
        'lib/screens/home.neon',
        '''
component HomeScreen {
    route: "/home"
    view {
        Scaffold(title: "Home") {
            Column(padding: 12.dp) {
                Text("Welcome to Neon Studio")
            }
        }
    }
}
''',
      );

      final storyboard = ide.extractStoryboardGraph();
      expect(storyboard.length, equals(1));
      expect(storyboard.first.routePath, equals('/home'));
      expect(storyboard.first.componentName, equals('HomeScreen'));

      final layers3D = ide.inspect3DWidgetHierarchy('lib/screens/home.neon');
      expect(layers3D.first.widgetType, equals('Scaffold'));
      expect(layers3D.first.children.first.widgetType, equals('Column'));
      expect(layers3D.first.children.first.depthZ, equals(12));

      ide.recordStateSnapshot(
        description: 'Initial state',
        statePayload: <String, dynamic>{'count': 0},
      );
      ide.recordStateSnapshot(
        description: 'Incremented',
        statePayload: <String, dynamic>{'count': 1},
      );

      final scrubbed = ide.scrubToFrame(0);
      expect(scrubbed.statePayload['count'], equals(0));
      expect(ide.activeTimeTravelIndex, equals(0));

      const caps = NeonUnifiedCapabilities(camera: true, biometrics: true);
      expect(caps.toAndroidPermissions(), contains('android.permission.CAMERA'));
      expect(caps.toIosInfoPlistKeys().containsKey('NSCameraUsageDescription'), isTrue);
    });
  });
}


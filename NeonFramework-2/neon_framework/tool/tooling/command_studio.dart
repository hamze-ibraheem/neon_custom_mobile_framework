import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:args/command_runner.dart';
import 'package:neon_framework/neon.dart';
import 'cli.dart';

/// CLI command (`neon studio`) to launch the Neon Studio IDE Workbench from any project directory.
class StudioCommand extends Command<int> {
  StudioCommand() {
    argParser.addOption(
      'port',
      abbr: 'p',
      help: 'Port to run the Neon Studio IDE server on.',
      defaultsTo: '9090',
    );
  }

  @override
  final String name = 'studio';

  @override
  final String description =
      'Launch Neon Studio IDE Workbench (Xcode + Android Studio + Antigravity Agents).';

  @override
  Future<int> run() async {
    final portStr = argResults!['port'] as String;
    final port = int.tryParse(portStr) ?? 9090;
    NeonLogger.header('Launching Neon Studio IDE on http://localhost:$port');

    final ide = NeonStudioIdeWorkbench();
    final htmlFile = await _resolveStudioHtmlFile();

    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    stdout.writeln('╔══════════════════════════════════════════════════════════════════╗');
    stdout.writeln('║  ⚡ NEON STUDIO IDE — PRODUCTION & CLOUD WORKBENCH SERVER        ║');
    stdout.writeln('║  Listening on: http://localhost:$port (0.0.0.0:$port)            ║');
    stdout.writeln('║  Workspace: ${Directory.current.path}');
    stdout.writeln('║  Routes: / , /studio , /ide , /api/compile , /api/build          ║');
    stdout.writeln('╚══════════════════════════════════════════════════════════════════╝');

    await for (final HttpRequest request in server) {
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        continue;
      }

      final path = request.uri.path;
      if (request.method == 'GET' &&
          (path == '/' || path == '/studio' || path == '/studio/' || path == '/ide' || path == '/index.html')) {
        if (htmlFile != null && htmlFile.existsSync()) {
          request.response.headers.contentType = ContentType.html;
          request.response.write(htmlFile.readAsStringSync());
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('Neon Studio IDE UI not found.');
        }
        await request.response.close();
        continue;
      }

      if (request.method == 'GET' && path == '/health') {
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(<String, dynamic>{
          'status': 'healthy',
          'service': 'neon-studio-ide',
          'port': port,
          'workspace': Directory.current.path,
        }));
        await request.response.close();
        continue;
      }

      if (request.method == 'POST' && path == '/api/compile') {
        final body = await utf8.decoder.bind(request).join();
        final payload = jsonDecode(body) as Map<String, dynamic>;
        final source = payload['source'] as String? ?? '';
        final fileName = payload['fileName'] as String? ?? 'lib/screens/task_studio.neon';

        ide.openOrUpdateFile(fileName, source);
        final compiled = ide.compiler.compileSource(source);
        final layers = ide.inspect3DWidgetHierarchy(fileName);
        final storyboard = ide.extractStoryboardGraph();

        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(<String, dynamic>{
          'isSuccess': compiled.isSuccess,
          'dartCode': compiled.dartCode,
          'diagnostics': compiled.diagnostics.map((d) => d.toJson()).toList(),
          'sourceMap': compiled.sourceMap.map((s) => s.toJson()).toList(),
          'layers3D': layers.map((l) => l.toJson()).toList(),
          'storyboard': storyboard.map((r) => r.toJson()).toList(),
        }));
        await request.response.close();
        continue;
      }

      if (request.method == 'POST' && path == '/api/build') {
        final body = await utf8.decoder.bind(request).join();
        final payload = jsonDecode(body) as Map<String, dynamic>;
        final formatName = payload['format'] as String? ?? 'apk';
        final hostName = payload['hostOs'] as String? ?? 'macos';

        final format = NeonPackageFormat.values.firstWhere(
          (f) => f.name == formatName,
          orElse: () => NeonPackageFormat.apk,
        );
        final hostOs = NeonHostOs.values.firstWhere(
          (h) => h.name == hostName,
          orElse: NeonHostOs.detect,
        );

        final result = ide.buildMobilePackage(
          appName: payload['appName'] as String? ?? 'NeonTaskStudio',
          bundleId: payload['bundleId'] as String? ?? 'dev.neonframework.taskstudio',
          format: format,
          hostOs: hostOs,
          outputDirectory: 'build/studio_packages',
        );

        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(result.toJson()));
        await request.response.close();
        continue;
      }

      if (request.method == 'POST' && path == '/api/agent') {
        final body = await utf8.decoder.bind(request).join();
        final payload = jsonDecode(body) as Map<String, dynamic>;
        final roleName = payload['role'] as String? ?? 'uiArchitect';
        final prompt = payload['prompt'] as String? ?? '';
        final source = payload['source'] as String? ?? '';

        final role = NeonSubagentRole.values.firstWhere(
          (r) => r.name == roleName,
          orElse: () => NeonSubagentRole.uiArchitect,
        );

        final response = ide.agentHub.dispatchSubagentTask(
          role: role,
          prompt: prompt,
          toolArgs: <String, dynamic>{
            if (source.isNotEmpty) 'source': source,
            if (role == NeonSubagentRole.releasePackager) ...<String, dynamic>{
              'appName': 'NeonTaskStudio',
              'bundleId': 'dev.neonframework.taskstudio',
              'format': 'ipa',
              'outputDirectory': 'build/studio_packages',
            },
          },
        );

        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(response));
        await request.response.close();
        continue;
      }

      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    }
    return 0;
  }

  Future<File?> _resolveStudioHtmlFile() async {
    const candidates = <String>[
      'neon_studio/web/index.html',
      'NeonFramework-2/neon_framework/neon_studio/web/index.html',
      '../neon_studio/web/index.html',
    ];
    for (final path in candidates) {
      final f = File(path);
      if (f.existsSync()) return f;
    }
    try {
      final pkgUri = await Isolate.resolvePackageUri(Uri.parse('package:neon_framework/neon.dart'));
      if (pkgUri != null) {
        final pkgRoot = File.fromUri(pkgUri).parent.parent;
        final pkgHtml = File('${pkgRoot.path}/neon_studio/web/index.html');
        if (pkgHtml.existsSync()) return pkgHtml;
      }
    } catch (_) {}
    return null;
  }
}


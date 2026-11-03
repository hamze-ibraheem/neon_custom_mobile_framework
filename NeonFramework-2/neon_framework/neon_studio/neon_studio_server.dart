/// Live HTTP Backend Server for **Neon Studio IDE** (`http://localhost:9090`).
///
/// Serves the interactive Neon Studio IDE Workbench UI and exposes live API endpoints
/// for `.neon` compilation, 3D widget layer inspection, Route Storyboard extraction,
/// Cross-OS `.apk`/`.bundle`/`.app`/`.ipa` building, and Google Antigravity Agents.
library neon_studio_server;

import 'dart:convert';
import 'dart:io';
import 'package:neon_framework/neon.dart';

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? (int.tryParse(args.first) ?? 9090) : 9090;
  final ide = NeonStudioIdeWorkbench();

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('╔══════════════════════════════════════════════════════════════════╗');
  stdout.writeln('║  ⚡ NEON STUDIO IDE — LIVE WORKBENCH SERVER                      ║');
  stdout.writeln('║  URL: http://localhost:$port                                      ║');
  stdout.writeln('║  Features: NeonLang (.neon) + Dart (.dart) | Cross-OS Builder    ║');
  stdout.writeln('║            Xcode Live Canvas + Android 3D Inspector + Antigravity║');
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
    if (request.method == 'GET' && (path == '/' || path == '/index.html')) {
      final htmlFile = File('neon_studio/web/index.html');
      if (htmlFile.existsSync()) {
        request.response.headers.contentType = ContentType.html;
        request.response.write(htmlFile.readAsStringSync());
      } else {
        request.response.write('Neon Studio IDE UI not found at neon_studio/web/index.html');
      }
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
}

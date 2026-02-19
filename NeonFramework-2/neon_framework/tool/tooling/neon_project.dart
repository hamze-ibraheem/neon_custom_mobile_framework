import 'dart:io';
import 'package:path/path.dart' as p;

class NeonProject {
  final String name;
  final String rootPath;
  final String? error;
  final Map<String, dynamic> config;

  NeonProject._({
    required this.name,
    required this.rootPath,
    this.error,
    this.config = const {},
  });

  bool get isValid => error == null;

  String? get entryPoint {
    final mainFile = File(p.join(rootPath, 'lib', 'main.dart'));
    if (mainFile.existsSync()) return 'lib/main.dart';
    return null;
  }

  static NeonProject load([String? path]) {
    final rootPath = path ?? Directory.current.path;

    final pubspecFile = File(p.join(rootPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      return NeonProject._(
        name: '',
        rootPath: rootPath,
        error: 'No pubspec.yaml found. Are you in a Neon project directory?',
      );
    }

    final pubspecContent = pubspecFile.readAsStringSync();
    final nameMatch = RegExp(r'^name:\s*(\S+)', multiLine: true)
        .firstMatch(pubspecContent);
    final projectName = nameMatch?.group(1) ?? 'unknown';

    final neonYaml = File(p.join(rootPath, 'neon.yaml'));
    Map<String, dynamic> config = {};
    if (neonYaml.existsSync()) {
      config = _parseSimpleYaml(neonYaml.readAsStringSync());
    }

    return NeonProject._(
      name: projectName,
      rootPath: rootPath,
      config: config,
    );
  }

  static Map<String, dynamic> _parseSimpleYaml(String content) {
    final map = <String, dynamic>{};
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final colonIndex = trimmed.indexOf(':');
      if (colonIndex > 0) {
        final key = trimmed.substring(0, colonIndex).trim();
        final value = trimmed.substring(colonIndex + 1).trim();
        if (value.isNotEmpty) {
          map[key] = value;
        }
      }
    }
    return map;
  }
}

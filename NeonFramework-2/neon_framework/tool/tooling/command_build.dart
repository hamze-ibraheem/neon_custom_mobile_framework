import 'dart:io';
import 'package:args/command_runner.dart';
import 'cli.dart';
import 'neon_project.dart';

class BuildCommand extends Command<int> {
  @override
  final String name = 'build';

  @override
  final String description = 'Build the Neon app for release.';

  BuildCommand() {
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'Target platform.',
      allowed: ['android', 'ios'],
      defaultsTo: 'android',
    );
    argParser.addOption(
      'flavor',
      abbr: 'f',
      help: 'Build flavor (e.g., dev, staging, prod).',
    );
    argParser.addFlag(
      'obfuscate',
      help: 'Enable Dart code obfuscation.',
      negatable: false,
    );
    argParser.addFlag(
      'release',
      help: 'Build in release mode.',
      defaultsTo: true,
      negatable: true,
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output directory for build artifacts.',
      defaultsTo: 'build/',
    );
  }

  @override
  Future<int> run() async {
    final args = argResults!;
    var target = args['target'] as String;
    if (args.rest.contains('apk') || args.rest.contains('android')) {
      target = 'android';
    } else if (args.rest.contains('ios') || args.rest.contains('ipa')) {
      target = 'ios';
    }
    final flavor = args['flavor'] as String?;
    final obfuscate = args['obfuscate'] as bool;
    final output = args['output'] as String;

    final project = NeonProject.load();
    if (!project.isValid) {
      NeonLogger.error(project.error!);
      return 1;
    }

    NeonLogger.header('Neon Build');
    NeonLogger.info('Project: ${project.name}');
    NeonLogger.info('Target: $target');
    if (flavor != null) NeonLogger.info('Flavor: $flavor');
    NeonLogger.info('Obfuscate: $obfuscate');
    NeonLogger.info('Output: $output');

    NeonLogger.step('Resolving dependencies...');
    final pubResult = Process.runSync(
      'dart',
      ['pub', 'get'],
      workingDirectory: project.rootPath,
    );
    if (pubResult.exitCode != 0) {
      NeonLogger.error('Failed to resolve dependencies.');
      return 1;
    }

    NeonLogger.step('Analyzing sources...');
    final entryPoint = project.entryPoint;
    if (entryPoint == null) {
      NeonLogger.error('No entry point found (lib/main.dart).');
      return 1;
    }

    final analyzeResult = Process.runSync(
      'dart',
      ['analyze', entryPoint],
      workingDirectory: project.rootPath,
    );
    if (analyzeResult.exitCode != 0) {
      NeonLogger.error('Analysis failed. Fix errors before building.');
      NeonLogger.info(analyzeResult.stderr.toString());
      return 1;
    }

    NeonLogger.step('Compiling for $target...');
    final buildResult = _buildForTarget(project, target, output, obfuscate);
    if (!buildResult.success) {
      NeonLogger.error('Build failed: ${buildResult.message}');
      return 1;
    }

    NeonLogger.success('Build complete!');
    NeonLogger.info('Artifacts: ${buildResult.outputPath}');
    return 0;
  }

  BuildResult _buildForTarget(
    NeonProject project,
    String target,
    String output,
    bool obfuscate,
  ) {
    final outputDir = Directory('${project.rootPath}/$output$target');
    outputDir.createSync(recursive: true);

    switch (target) {
      case 'android':
        return _buildAndroid(project, outputDir, obfuscate);
      case 'ios':
        return _buildIos(project, outputDir, obfuscate);
      default:
        return BuildResult(
          success: false,
          message: 'Unsupported target: $target',
        );
    }
  }

  BuildResult _buildAndroid(
    NeonProject project,
    Directory outputDir,
    bool obfuscate,
  ) {
    try {
      final compileResult = Process.runSync(
        'dart',
        [
          'compile',
          'aot-snapshot',
          project.entryPoint!,
          '-o',
          '${outputDir.path}/app.aot',
          if (obfuscate) '--enable-asserts',
        ],
        workingDirectory: project.rootPath,
      );

      if (compileResult.exitCode != 0) {
        return BuildResult(
          success: false,
          message: compileResult.stderr.toString(),
        );
      }

      return BuildResult(
        success: true,
        message: 'Android build complete.',
        outputPath: outputDir.path,
      );
    } catch (e) {
      return BuildResult(success: false, message: '$e');
    }
  }

  BuildResult _buildIos(
    NeonProject project,
    Directory outputDir,
    bool obfuscate,
  ) {
    try {
      final compileResult = Process.runSync(
        'dart',
        [
          'compile',
          'aot-snapshot',
          project.entryPoint!,
          '-o',
          '${outputDir.path}/app.aot',
        ],
        workingDirectory: project.rootPath,
      );

      if (compileResult.exitCode != 0) {
        return BuildResult(
          success: false,
          message: compileResult.stderr.toString(),
        );
      }

      return BuildResult(
        success: true,
        message: 'iOS build complete.',
        outputPath: outputDir.path,
      );
    } catch (e) {
      return BuildResult(success: false, message: '$e');
    }
  }
}

class BuildResult {
  final bool success;
  final String message;
  final String? outputPath;

  const BuildResult({
    required this.success,
    required this.message,
    this.outputPath,
  });
}

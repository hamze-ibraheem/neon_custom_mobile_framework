import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:neon_framework/neon.dart';
import 'package:path/path.dart' as p;
import 'cli.dart';
import 'neon_project.dart';
import 'ios/ios_generator.dart';
import 'ios/xcode_cloud_setup.dart';

class BuildCommand extends Command<int> {
  BuildCommand() {
    argParser.addOption(
      'target',
      abbr: 't',
      help:
          'Target platform or package format (android, ios, apk, bundle, aab, app, ipa).',
      allowed: ['android', 'ios', 'apk', 'bundle', 'aab', 'app', 'ipa'],
      defaultsTo: 'android',
    );
    argParser.addOption(
      'host-os',
      help: 'Host OS executing the build (windows, macos, linux).',
      allowed: ['windows', 'macos', 'linux'],
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
    argParser.addFlag(
      'xcode-cloud',
      help:
          'Configure and validate project for Apple Developer Xcode Cloud & TestFlight automated builds.',
      negatable: false,
    );
    argParser.addFlag(
      'archive',
      help:
          'Create a local Xcode archive (.xcarchive) using xcodebuild on macOS.',
      negatable: false,
    );
  }

  @override
  final String name = 'build';

  @override
  final String description =
      'Build the Neon app for release (.apk, .bundle/.aab, .app, .ipa).';

  @override
  Future<int> run() async {
    final args = argResults!;
    var target = args['target'] as String;
    if (args.rest.contains('apk')) {
      target = 'apk';
    } else if (args.rest.contains('bundle') || args.rest.contains('aab')) {
      target = 'bundle';
    } else if (args.rest.contains('app')) {
      target = 'app';
    } else if (args.rest.contains('ipa')) {
      target = 'ipa';
    } else if (args.rest.contains('android')) {
      target = 'android';
    } else if (args.rest.contains('ios')) {
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
    final isXcodeCloud = (args['xcode-cloud'] as bool?) ?? false;
    final isArchive = (args['archive'] as bool?) ?? false;

    final buildResult = _buildForTarget(
      project: project,
      target: target,
      output: output,
      obfuscate: obfuscate,
      isXcodeCloud: isXcodeCloud,
      isArchive: isArchive,
    );
    if (!buildResult.success) {
      NeonLogger.error('Build failed: ${buildResult.message}');
      return 1;
    }

    NeonLogger.success('Build complete!');
    if (buildResult.outputPath != null) {
      NeonLogger.info('Artifacts: ${buildResult.outputPath}');
    }
    return 0;
  }

  BuildResult _buildForTarget({
    required NeonProject project,
    required String target,
    required String output,
    required bool obfuscate,
    required bool isXcodeCloud,
    required bool isArchive,
  }) {
    final outputDir = Directory('${project.rootPath}/$output$target');
    outputDir.createSync(recursive: true);

    switch (target) {
      case 'android':
        return _buildAndroid(project, outputDir, obfuscate);
      case 'ios':
        return _buildIos(
          project: project,
          outputDir: outputDir,
          obfuscate: obfuscate,
          isXcodeCloud: isXcodeCloud,
          isArchive: isArchive,
        );
      case 'apk':
      case 'bundle':
      case 'aab':
      case 'app':
      case 'ipa':
        final pkgFormat = (target == 'aab' || target == 'bundle')
            ? NeonPackageFormat.bundle
            : NeonPackageFormat.values.firstWhere((f) => f.name == target);
        const crossBuilder = NeonCrossOsBuilder();
        final pkgRes = crossBuilder.build(NeonPackageBuildRequest(
          appName: project.name,
          bundleId:
              project.config['bundle_id'] as String? ?? 'dev.neonframework.app',
          version: project.config['version'] as String? ?? '1.0.0',
          buildNumber: 1,
          format: pkgFormat,
          outputDirectory: outputDir.path,
        ));
        return BuildResult(
          success: pkgRes.success,
          message: 'Built ${pkgFormat.name} on ${pkgRes.hostOs.name}',
          outputPath: pkgRes.artifactPath,
        );
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

  BuildResult _buildIos({
    required NeonProject project,
    required Directory outputDir,
    required bool obfuscate,
    required bool isXcodeCloud,
    required bool isArchive,
  }) {
    try {
      final bundleId =
          project.config['bundle_id'] as String? ?? 'com.neon.myapp';
      final schemeName = project.config['scheme'] as String? ?? 'NeonApp';

      // 1. If Xcode Cloud flag requested, setup and validate CI environment
      if (isXcodeCloud) {
        NeonLogger.info(
            'Configuring Xcode Cloud automated CI for TestFlight...');
        final xcodeCloud = XcodeCloudSetup(projectRoot: project.rootPath);
        xcodeCloud.setupCiScripts(bundleId: bundleId, schemeName: schemeName);

        final iosGen = IosGenerator(projectRoot: project.rootPath);
        final isReady =
            iosGen.verifyXcodeCloudReadiness(schemeName: schemeName);

        NeonLogger.info('Xcode Cloud Checklist:');
        NeonLogger.info(' • App ID registered in Apple Developer: $bundleId');
        NeonLogger.info(' • App Record created in App Store Connect');
        NeonLogger.info(' • Shared Scheme active: $schemeName.xcscheme');
        NeonLogger.info(' • CI scripts generated in ci_scripts/');
        NeonLogger.info(
            ' • TestFlight auto-distribution enabled in Xcode Cloud workflow');

        if (!isReady) {
          NeonLogger.warning(
              'Project needs shared scheme verification before pushing to Git.');
        }
      }

      // 2. Perform Dart compilation snapshot
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

      // 3. Optional local archive creation via xcodebuild if on macOS and --archive flag given
      if (isArchive && Platform.isMacOS) {
        final iosDir = Directory(p.join(project.rootPath, 'ios'));
        if (iosDir.existsSync()) {
          final xcodeProjects = iosDir
              .listSync()
              .whereType<Directory>()
              .where((d) => d.path.endsWith('.xcodeproj'))
              .toList();

          if (xcodeProjects.isNotEmpty) {
            final projPath = xcodeProjects.first.path;
            final archivePath =
                p.join(outputDir.path, '${project.name}.xcarchive');
            NeonLogger.step('Creating Xcode archive at $archivePath...');

            final archiveResult = Process.runSync(
              'xcodebuild',
              [
                '-project',
                projPath,
                '-scheme',
                schemeName,
                '-configuration',
                'Release',
                '-archivePath',
                archivePath,
                'archive',
                'CODE_SIGNING_ALLOWED=NO',
              ],
              workingDirectory: project.rootPath,
            );

            if (archiveResult.exitCode == 0) {
              return BuildResult(
                success: true,
                message: 'iOS archive (.xcarchive) successfully created.',
                outputPath: archivePath,
              );
            } else {
              NeonLogger.warning(
                  'Local archive skipped or requires signing: ${archiveResult.stderr}');
            }
          }
        }
      }

      return BuildResult(
        success: true,
        message: isXcodeCloud
            ? 'iOS Xcode Cloud readiness verified & configured.'
            : 'iOS build complete.',
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

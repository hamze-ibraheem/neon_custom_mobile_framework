import 'dart:io';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'cli.dart';
import 'project_template.dart';
import 'android/android_generator.dart';
import 'ios/ios_generator.dart';

class CreateCommand extends Command<int> {
  @override
  final String name = 'create';

  @override
  final String description = 'Create a new Neon project or platform files.';

  static const _platforms = {'android', 'ios'};

  CreateCommand() {
    argParser.addOption(
      'template',
      abbr: 't',
      help: 'Project template to use.',
      allowed: ['app', 'minimal'],
      defaultsTo: 'app',
    );
    argParser.addFlag(
      'dry-run',
      help: 'Show what would be created without writing files.',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final args = argResults!;
    final rest = args.rest;

    if (rest.isEmpty) {
      NeonLogger.error('Please provide a project name or platform.');
      NeonLogger.info('Usage:');
      NeonLogger.step('neon create <project_name>');
      NeonLogger.step('neon create android');
      return 1;
    }

    final target = rest.first;

    // ✅ PLATFORM CREATION PATH
    if (_platforms.contains(target)) {
      return _createPlatform(target);
    }

    // ✅ PROJECT CREATION PATH (existing behavior)
    return _createProject(args);
  }

  // -----------------------------
  // PLATFORM CREATION
  // -----------------------------
  int _createPlatform(String platform) {
    NeonLogger.header('Creating Platform Files');
    NeonLogger.info('Platform: $platform');

    switch (platform) {
      case 'android':
        NeonLogger.step('Generating Android project skeleton...');
        AndroidGenerator().generate();
        NeonLogger.success('Android platform created successfully.');
        NeonLogger.info('');
        NeonLogger.step('Next: neon run android');
        return 0;

      case 'ios':
        NeonLogger.step('Generating iOS project skeleton & Xcode Cloud configuration...');
        IosGenerator(projectRoot: Directory.current.path).generate();
        NeonLogger.success('iOS platform files and Xcode Cloud CI scripts configured.');
        NeonLogger.info('');
        NeonLogger.step('Next: neon build ios --xcode-cloud');
        return 0;

      default:
        NeonLogger.error('Unsupported platform: $platform');
        return 1;
    }
  }

  // -----------------------------
  // PROJECT CREATION (UNCHANGED)
  // -----------------------------
  int _createProject(ArgResults args) {
    final rest = args.rest;
    final projectName = rest.first;
    final template = args['template'] as String;
    final dryRun = args['dry-run'] as bool;

    if (!_isValidProjectName(projectName)) {
      NeonLogger.error(
        'Invalid project name "$projectName". '
        'Use lowercase letters, numbers, and underscores only.',
      );
      return 1;
    }

    NeonLogger.header('Creating Neon Project');
    NeonLogger.info('Project: $projectName');
    NeonLogger.info('Template: $template');

    final scaffolder = NeonProjectTemplate(
      projectName: projectName,
      template: template,
    );

    final files = scaffolder.generate();

    if (dryRun) {
      NeonLogger.info('');
      NeonLogger.info('Files that would be created:');
      for (final path in files.keys) {
        NeonLogger.step(path);
      }
      return 0;
    }

    final result = scaffolder.writeFiles(files);
    if (!result.success) {
      NeonLogger.error(result.message);
      return 1;
    }

    NeonLogger.success('Project "$projectName" created successfully!');
    NeonLogger.info('');
    NeonLogger.info('Next steps:');
    NeonLogger.step('cd $projectName');
    NeonLogger.step('neon doctor');
    NeonLogger.step('neon create android');
    NeonLogger.step('neon run android');
    return 0;
  }

  bool _isValidProjectName(String name) {
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);
  }
}

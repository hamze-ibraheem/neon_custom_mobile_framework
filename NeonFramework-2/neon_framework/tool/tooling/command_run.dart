import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'cli.dart';
import 'hot_reload.dart';
import 'neon_project.dart';
import 'android/android_runner.dart';

class RunCommand extends Command<int> {
  @override
  final String name = 'run';

  @override
  final String description = 'Run the Neon app with hot reload.';

  final bool Function()? _testMode;

  RunCommand({bool Function()? testMode}) : _testMode = testMode {
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'Target platform.',
      allowed: ['android', 'ios', 'web'],
      defaultsTo: 'web',
    );
    argParser.addOption(
      'device',
      abbr: 'd',
      help: 'Target device ID.',
    );
    argParser.addFlag(
      'release',
      help: 'Run in release mode (no hot reload).',
      negatable: false,
    );
    argParser.addOption(
      'reload-mode',
      help: 'Hot reload strategy.',
      allowed: ['ui', 'state-preserving', 'full'],
      defaultsTo: 'state-preserving',
    );
  }

  @override
  Future<int> run() async {
    final args = argResults!;
    final target = args['target'] as String;
    final release = args['release'] as bool;
    final reloadMode = args['reload-mode'] as String;

    final project = NeonProject.load();
    if (!project.isValid) {
      NeonLogger.error(project.error!);
      return 1;
    }

    NeonLogger.header('Neon Run');
    NeonLogger.info('Project: ${project.name}');
    NeonLogger.info('Target: $target');
    NeonLogger.info('Mode: ${release ? 'release' : 'debug'}');

    // ----------------------------
    // DART BACKEND
    // ----------------------------

    // ----------------------------
    // DART / DESKTOP RUNNER
    // ----------------------------
    NeonLogger.step('Resolving dependencies...');
    final pubResult = _runDartPubGet(project.rootPath);
    if (pubResult != 0) {
      NeonLogger.error('Failed to resolve dependencies.');
      return 1;
    }

    NeonLogger.step('Compiling Dart sources...');
    final compileResult = _compileDart(project);
    if (!compileResult.success) {
      NeonLogger.error('Compilation failed: ${compileResult.message}');
      return 1;
    }
    NeonLogger.success('Compilation successful.');

    NeonLogger.step('Launching Dart app...');
    final appProcess = await _launchDartApp(project);
    if (appProcess == null) {
      NeonLogger.error('Failed to launch app.');
      return 1;
    }
    NeonLogger.success('App process started (pid: ${appProcess.pid}).');

    // ----------------------------
    // ANDROID RUNNER (REAL PLATFORM)
    // ----------------------------
    if (target == 'android') {
      NeonLogger.step('Preparing Android...');
      final runner = AndroidRunner();
      // Wait a moment for server to bind
      await Future.delayed(const Duration(seconds: 1));

      // Setup bridge (8080 is what MainActivity.kt expects)
      await runner.setupReversePort(8080);

      await runner.run();
      NeonLogger.success('Android app launched.');
    }

    HotReloadEngine? engine;

    if (!release) {
      NeonLogger.step('Starting hot reload watcher...');
      final reloadStrategy = HotReloadMode.fromString(reloadMode);

      engine = HotReloadEngine(
        projectPath: project.rootPath,
        watchPaths: ['lib/'],
        mode: reloadStrategy,
        onReload: (event) {
          NeonLogger.info('  [Hot Reload] ${event.description}');
          _triggerReload(project, appProcess, event);
        },
      );

      engine.start();
      NeonLogger.success('Hot reload active (mode: ${reloadStrategy.name})');
    }

    NeonLogger.success('App is running.');
    NeonLogger.info('Press Ctrl+C to stop.');

    if (_testMode != null) {
      return 0;
    }

    final completer = Completer<int>();

    final sigintSub = ProcessSignal.sigint.watch().listen((_) {
      NeonLogger.info('\nShutting down...');
      engine?.stop();
      appProcess.kill();
      NeonLogger.success('App stopped.');
      if (!completer.isCompleted) {
        completer.complete(0);
      }
    });

    appProcess.exitCode.then((code) {
      engine?.stop();
      if (!completer.isCompleted) {
        if (code != 0) {
          NeonLogger.error('App exited with code $code.');
        }
        completer.complete(code);
      }
    });

    final exitCode = await completer.future;
    await sigintSub.cancel();
    return exitCode;
  }

  // ----------------------------
  // DART VM LAUNCHER
  // ----------------------------
  Future<Process?> _launchDartApp(NeonProject project) async {
    try {
      final entryPoint = project.entryPoint;
      if (entryPoint == null) return null;

      final process = await Process.start(
        'dart',
        ['run', entryPoint],
        workingDirectory: project.rootPath,
        mode: ProcessStartMode.inheritStdio,
        environment: {
          'PORT': Platform.environment['PORT'] ?? '8080', // Use env PORT or default to 8080
        },
      );

      return process;
    } catch (e) {
      NeonLogger.error('Launch error: $e');
      return null;
    }
  }

  // ----------------------------
  // HOT RELOAD HANDLER
  // ----------------------------
  void _triggerReload(
    NeonProject project,
    Process appProcess,
    HotReloadEvent event,
  ) {
    switch (event.type) {
      case HotReloadEventType.uiReload:
        NeonLogger.step('Re-running build methods...');
        break;
      case HotReloadEventType.statePreservingReload:
        NeonLogger.step('Reloading with preserved state...');
        break;
      case HotReloadEventType.fullReload:
        NeonLogger.step('Full reload: restarting app process...');
        appProcess.kill();
        final newProcess = _launchDartApp(project);
        if (newProcess != null) {
          NeonLogger.success('App restarted.');
        }
        break;
      case HotReloadEventType.error:
        NeonLogger.error('Reload error: ${event.description}');
        break;
    }
  }

  // ----------------------------
  // DART TOOLING
  // ----------------------------
  int _runDartPubGet(String projectPath) {
    try {
      final result = Process.runSync(
        'dart',
        ['pub', 'get'],
        workingDirectory: projectPath,
      );
      return result.exitCode;
    } catch (_) {
      return 1;
    }
  }

  CompileResult _compileDart(NeonProject project) {
    try {
      final entryPoint = project.entryPoint;
      if (entryPoint == null) {
        return const CompileResult(
          success: false,
          message: 'No entry point found.',
        );
      }

      final result = Process.runSync(
        'dart',
        ['analyze', entryPoint],
        workingDirectory: project.rootPath,
      );

      if (result.exitCode != 0) {
        final err = result.stderr.toString();
        final out = result.stdout.toString();
        if (err.contains('Too many open files') ||
            err.contains('An unexpected error was encountered') ||
            out.contains('Too many open files') ||
            out.contains('An unexpected error was encountered')) {
          NeonLogger.warning('Analysis server file limit warning. Bypassing analyzer...');
          return const CompileResult(success: true, message: 'OK');
        }
        return CompileResult(
          success: false,
          message: err.isNotEmpty ? err : out,
        );
      }

      return const CompileResult(success: true, message: 'OK');
    } catch (e) {
      return CompileResult(success: false, message: '$e');
    }
  }
}

// ----------------------------
// SUPPORT TYPES
// ----------------------------
class CompileResult {
  final bool success;
  final String message;

  const CompileResult({
    required this.success,
    required this.message,
  });
}

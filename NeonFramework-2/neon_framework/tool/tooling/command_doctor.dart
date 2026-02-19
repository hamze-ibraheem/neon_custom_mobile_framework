import 'dart:io';
import 'package:args/command_runner.dart';
import 'cli.dart';

class DoctorCommand extends Command<int> {
  @override
  final String name = 'doctor';

  @override
  final String description = 'Check your Neon development environment.';

  @override
  Future<int> run() async {
    NeonLogger.header('Neon Doctor');
    NeonLogger.info('Checking development environment...\n');

    int issues = 0;

    issues += _checkDartSdk();
    issues += _checkAndroidSdk();
    issues += _checkXcode();
    issues += _checkConnectedDevices();
    issues += _checkNeonProject();

    NeonLogger.info('');
    if (issues == 0) {
      NeonLogger.success('No issues found! Your environment is ready.');
    } else {
      NeonLogger.warning('$issues issue(s) found. See above for details.');
    }

    return issues > 0 ? 1 : 0;
  }

  int _checkDartSdk() {
    NeonLogger.info('[Dart SDK]');
    try {
      final result = Process.runSync('dart', ['--version']);
      final version = result.stdout.toString().trim();
      final stderrVersion = result.stderr.toString().trim();
      final displayVersion =
          version.isNotEmpty ? version : stderrVersion;

      if (result.exitCode == 0) {
        NeonLogger.success('  $displayVersion');
        return 0;
      } else {
        NeonLogger.error('  Dart SDK not found or not working.');
        return 1;
      }
    } catch (_) {
      NeonLogger.error('  Dart SDK not installed.');
      NeonLogger.step('Install from https://dart.dev/get-dart');
      return 1;
    }
  }

  int _checkAndroidSdk() {
    NeonLogger.info('[Android SDK]');
    final androidHome = Platform.environment['ANDROID_HOME'] ??
        Platform.environment['ANDROID_SDK_ROOT'];

    if (androidHome != null && Directory(androidHome).existsSync()) {
      NeonLogger.success('  Found at $androidHome');

      final adb = _findExecutable('adb');
      if (adb != null) {
        NeonLogger.success('  adb available');
      } else {
        NeonLogger.warning('  adb not found in PATH');
      }
      return 0;
    } else {
      NeonLogger.warning('  Android SDK not found (optional for iOS-only development).');
      NeonLogger.step('Set ANDROID_HOME environment variable.');
      return 0;
    }
  }

  int _checkXcode() {
    NeonLogger.info('[Xcode (iOS)]');
    if (!Platform.isMacOS) {
      NeonLogger.info('  Skipped (not macOS).');
      return 0;
    }

    try {
      final result = Process.runSync('xcodebuild', ['-version']);
      if (result.exitCode == 0) {
        final version = result.stdout.toString().trim().split('\n').first;
        NeonLogger.success('  $version');
        return 0;
      } else {
        NeonLogger.warning('  Xcode not installed (optional for Android-only development).');
        return 0;
      }
    } catch (_) {
      NeonLogger.warning('  Xcode not available (optional for Android-only development).');
      return 0;
    }
  }

  int _checkConnectedDevices() {
    NeonLogger.info('[Connected Devices]');
    try {
      final result = Process.runSync('adb', ['devices']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        final lines = output
            .split('\n')
            .skip(1)
            .where((l) => l.trim().isNotEmpty)
            .toList();

        if (lines.isEmpty) {
          NeonLogger.info('  No Android devices connected.');
        } else {
          for (final line in lines) {
            NeonLogger.success('  $line');
          }
        }
      }
    } catch (_) {
      NeonLogger.info('  Could not check devices (adb not available).');
    }
    return 0;
  }

  int _checkNeonProject() {
    NeonLogger.info('[Neon Project]');
    final neonYaml = File('neon.yaml');
    final pubspec = File('pubspec.yaml');

    if (neonYaml.existsSync()) {
      NeonLogger.success('  neon.yaml found');
    } else {
      NeonLogger.info('  No neon.yaml in current directory (run from project root).');
    }

    if (pubspec.existsSync()) {
      NeonLogger.success('  pubspec.yaml found');
    } else {
      NeonLogger.info('  No pubspec.yaml in current directory.');
    }

    return 0;
  }

  String? _findExecutable(String name) {
    try {
      final result = Process.runSync('which', [name]);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (_) {}
    return null;
  }
}

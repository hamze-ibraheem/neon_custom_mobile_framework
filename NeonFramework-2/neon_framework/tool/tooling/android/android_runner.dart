import 'dart:io';
import 'package:neon_framework/neon.dart';
import '../cli.dart';

class AndroidRunner {
  /// The main entry point to build and launch Android.
  Future<void> run() async {
    _checkAndroidProject();
    await _checkAdb();
    await _buildApk();
    await _installApk();
    await _launchApp();
  }

  /// Setup adb reverse to bridge the port from device to host.
  Future<void> setupReversePort(int port) async {
    NeonLogger.step('Setting up adb reverse for port $port...');
    try {
      final result =
          await Process.run('adb', ['reverse', 'tcp:8080', 'tcp:$port']);
      if (result.exitCode != 0) {
        NeonLogger.warning(
            'adb reverse failed. You may need to run it manually.');
      } else {
        NeonLogger.success('adb reverse set up (device:8080 -> host:$port).');
      }
    } catch (e) {
      NeonLogger.warning('Could not run adb reverse: $e');
    }
  }

  /// 1. Verify the Android project exists.
  void _checkAndroidProject() {
    final androidDir = Directory('android');
    if (!androidDir.existsSync()) {
      NeonLogger.error(
        'Android project not found.\n'
        'Run: neon create android',
      );
      exit(1);
    }
  }

  /// 2. Verify ADB is installed and accessible.
  Future<void> _checkAdb() async {
    NeonLogger.step('Checking adb...');
    try {
      final result = await Process.run('adb', ['devices']);
      if (result.exitCode != 0) {
        NeonLogger.error('adb is installed but exited with error.');
        exit(1);
      }
    } catch (e) {
      NeonLogger.error('adb not found in PATH.');
      NeonLogger.info('Please install Android SDK Platform-Tools.');
      exit(1);
    }
  }

  /// 3. Run Gradle to build the Debug APK.
  Future<void> _buildApk() async {
    NeonLogger.step('Building Android debug APK...');

    // Detect Windows vs Mac/Linux wrapper
    final gradleCmd = Platform.isWindows ? 'gradlew.bat' : './gradlew';

    try {
      // We use Process.start to stream the output to the user if needed,
      // or just wait for it to finish.
      final process = await Process.start(
        gradleCmd,
        ['assembleDebug'],
        workingDirectory: 'android', // Run inside the android/ folder
        runInShell: true,
      );

      // Pipe stdout/stderr so the user sees build progress (optional)
      // await stdout.addStream(process.stdout);
      // await stderr.addStream(process.stderr);

      // Wait for build to finish
      final code = await process.exitCode;
      if (code != 0) {
        NeonLogger.error('Gradle build failed.');
        exit(1);
      }
      NeonLogger.success('APK built successfully.');
    } catch (e) {
      NeonLogger.error('Failed to run Gradle: $e');
      exit(1);
    }
  }

  /// 4. Install the APK onto the connected device.
  Future<void> _installApk() async {
    NeonLogger.step('Installing APK via adb...');

    // The standard path where Gradle outputs the APK
    final apkPath = 'android/app/build/outputs/apk/debug/app-debug.apk';

    if (!File(apkPath).existsSync()) {
      NeonLogger.error('APK file not found at: $apkPath');
      exit(1);
    }

    final result = await Process.run(
      'adb',
      ['install', '-r', apkPath], // -r means "reinstall" (keep data)
    );

    if (result.exitCode != 0) {
      NeonLogger.error('APK installation failed.');
      NeonLogger.info('Error details:\n${result.stderr}');
      exit(1);
    }
    NeonLogger.success('APK installed.');
  }

  /// 5. Launch the MainActivity.
  Future<void> _launchApp() async {
    NeonLogger.step('Launching app...');

    // These must match what `AndroidGenerator` created
    const packageName = 'com.neon.myapp';
    const activityName = 'com.neon.myapp.MainActivity';

    final result = await Process.run(
      'adb',
      ['shell', 'am', 'start', '-n', '$packageName/$activityName'],
    );

    if (result.exitCode != 0) {
      NeonLogger.error('Failed to launch app.');
      NeonLogger.info('Error details:\n${result.stderr}');
      exit(1);
    }

    NeonLogger.success('Android app launched successfully.');
  }
}

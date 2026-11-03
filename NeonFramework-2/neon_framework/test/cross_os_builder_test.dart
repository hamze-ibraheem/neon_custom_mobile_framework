import 'dart:io';
import 'package:neon_framework/neon.dart';
import 'package:test/test.dart';
import '../neon_studio/packaging/build_desktop_ide.dart';
import '../tool/tooling/builder_android.dart';
import '../tool/tooling/builder_ios.dart';

void main() {
  group('Cross-OS Android, iOS, & Desktop IDE Builders (Phase 2 & Phase 6)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('neon_builder_suite_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('NeonAndroidBuilder builds .apk and .aab/.bundle across Windows, macOS, and Linux', () {
      const androidBuilder = NeonAndroidBuilder();
      for (final os in NeonHostOs.values) {
        final apk = androidBuilder.buildApk(
          appName: 'TodoNeon',
          bundleId: 'dev.neon.todo',
          outputDirectory: tempDir.path,
          hostOs: os,
        );
        expect(apk.success, isTrue);
        expect(File(apk.artifactPath).existsSync(), isTrue);

        final aab = androidBuilder.buildAppBundle(
          appName: 'TodoNeon',
          bundleId: 'dev.neon.todo',
          outputDirectory: tempDir.path,
          hostOs: os,
        );
        expect(aab.success, isTrue);
        expect(File(aab.artifactPath).existsSync(), isTrue);
      }
    });

    test('NeonIosBuilder builds .app and .ipa across Windows, Linux Ubuntu, and macOS', () {
      const iosBuilder = NeonIosBuilder();
      for (final os in NeonHostOs.values) {
        final app = iosBuilder.buildAppBundle(
          appName: 'TodoNeon',
          bundleId: 'dev.neon.todo',
          outputDirectory: tempDir.path,
          hostOs: os,
        );
        expect(app.success, isTrue);
        expect(Directory(app.artifactPath).existsSync(), isTrue);

        final ipa = iosBuilder.buildIpaArchive(
          appName: 'TodoNeon',
          bundleId: 'dev.neon.todo',
          outputDirectory: tempDir.path,
          hostOs: os,
        );
        expect(ipa.success, isTrue);
        expect(File(ipa.artifactPath).existsSync(), isTrue);
      }
    });

    test('NeonStudioDesktopPackager packages IDE for Windows (.exe), macOS (.dmg), and Ubuntu (.deb)', () {
      const desktopPackager = NeonStudioDesktopPackager();
      for (final fmt in NeonDesktopPackageFormat.values) {
        final pkg = desktopPackager.packageDesktopIde(
          format: fmt,
          outputDirectory: tempDir.path,
        );
        expect(pkg.existsSync(), isTrue);
      }
    });

    test('All 4 showcase .neon screens compile with 0 errors', () {
      const compiler = NeonCompiler();
      final files = <String>[
        'examples/task_studio.neon',
        'examples/create_task.neon',
        'examples/analytics_screen.neon',
        'examples/settings_diagnostics.neon',
      ];
      for (final path in files) {
        final content = File(path).readAsStringSync();
        final res = compiler.compileSource(content);
        expect(res.isSuccess, isTrue, reason: 'Failed compiling $path: ${res.diagnostics}');
      }
    });
  });
}


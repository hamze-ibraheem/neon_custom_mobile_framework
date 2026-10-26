import 'dart:io';
import 'package:path/path.dart' as p;
import 'xcode_cloud_setup.dart';

class IosGenerator {
  final String projectRoot;

  IosGenerator({required this.projectRoot});

  void generate({
    String appName = 'NeonApp',
    String bundleId = 'com.neon.myapp',
    String? teamId,
    String deploymentTarget = '15.0',
  }) {
    final iosDir = Directory(p.join(projectRoot, 'ios'));
    if (!iosDir.existsSync()) {
      iosDir.createSync(recursive: true);
    }

    stdout.writeln('[INFO] Configuring iOS project for $appName ($bundleId)...');

    // Setup Xcode Cloud CI Scripts
    final xcodeCloud = XcodeCloudSetup(projectRoot: projectRoot);
    xcodeCloud.setupCiScripts(bundleId: bundleId, schemeName: appName);
    stdout.writeln('[SUCCESS] Xcode Cloud CI scripts configured in ci_scripts/ and ios/ci_scripts/.');
  }

  /// Verifies if the iOS project has the necessary Xcode Cloud shared scheme and configuration.
  bool verifyXcodeCloudReadiness({String? schemeName}) {
    final schemeToCheck = schemeName ?? 'NeonApp';
    final xcodeProjDirs = Directory(p.join(projectRoot, 'ios'))
        .listSync()
        .whereType<Directory>()
        .where((d) => d.path.endsWith('.xcodeproj'));

    if (xcodeProjDirs.isEmpty) {
      stdout.writeln('[ERROR] No .xcodeproj found in ios/ directory.');
      return false;
    }

    bool hasSharedScheme = false;
    for (final proj in xcodeProjDirs) {
      final sharedSchemeDir = Directory(p.join(proj.path, 'xcshareddata', 'xcschemes'));
      if (sharedSchemeDir.existsSync()) {
        final schemes = sharedSchemeDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.xcscheme'));
        final matchingSchemes = schemes.where((f) => p.basename(f.path) == '$schemeToCheck.xcscheme');
        if (matchingSchemes.isNotEmpty) {
          hasSharedScheme = true;
          stdout.writeln('[INFO] Found matching shared scheme: $schemeToCheck.xcscheme in ${p.basename(proj.path)}');
        } else if (schemes.isNotEmpty) {
          hasSharedScheme = true;
          stdout.writeln('[INFO] Found shared scheme: ${p.basename(schemes.first.path)} in ${p.basename(proj.path)}');
        }
      }
    }

    if (!hasSharedScheme) {
      stdout.writeln('[WARN] No shared scheme found in xcshareddata/xcschemes/. Xcode Cloud requires a shared scheme.');
      return false;
    }

    final ciScriptsDir = Directory(p.join(projectRoot, 'ci_scripts'));
    final postClone = File(p.join(ciScriptsDir.path, 'ci_post_clone.sh'));
    if (!postClone.existsSync()) {
      stdout.writeln('[WARN] ci_scripts/ci_post_clone.sh is missing.');
      return false;
    }

    stdout.writeln('[SUCCESS] Project is fully configured and ready for Xcode Cloud!');
    return true;
  }
}

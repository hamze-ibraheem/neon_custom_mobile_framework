import 'dart:io';
import 'package:path/path.dart' as p;

class XcodeCloudSetup {
  final String projectRoot;

  XcodeCloudSetup({required this.projectRoot});

  /// Generates the standard Xcode Cloud ci_scripts directory and scripts.
  /// Xcode Cloud looks for ci_scripts/ either at the repository root or adjacent to the .xcodeproj.
  bool setupCiScripts({String? bundleId, String? schemeName}) {
    final rootCiScripts = Directory(p.join(projectRoot, 'ci_scripts'));
    final iosCiScripts = Directory(p.join(projectRoot, 'ios', 'ci_scripts'));

    rootCiScripts.createSync(recursive: true);
    iosCiScripts.createSync(recursive: true);

    final postCloneContent = _generatePostCloneScript(schemeName: schemeName);
    final preXcodebuildContent = _generatePreXcodebuildScript(bundleId: bundleId);
    final postXcodebuildContent = _generatePostXcodebuildScript();

    final scripts = [
      {'path': p.join(rootCiScripts.path, 'ci_post_clone.sh'), 'content': postCloneContent},
      {'path': p.join(rootCiScripts.path, 'ci_pre_xcodebuild.sh'), 'content': preXcodebuildContent},
      {'path': p.join(rootCiScripts.path, 'ci_post_xcodebuild.sh'), 'content': postXcodebuildContent},
      {'path': p.join(iosCiScripts.path, 'ci_post_clone.sh'), 'content': postCloneContent},
      {'path': p.join(iosCiScripts.path, 'ci_pre_xcodebuild.sh'), 'content': preXcodebuildContent},
      {'path': p.join(iosCiScripts.path, 'ci_post_xcodebuild.sh'), 'content': postXcodebuildContent},
    ];

    for (final s in scripts) {
      final file = File(s['path']!);
      file.writeAsStringSync(s['content']!);
      if (!Platform.isWindows) {
        Process.runSync('chmod', ['+x', file.path]);
      }
    }

    return true;
  }

  String _generatePostCloneScript({String? schemeName}) {
    return '''#!/bin/sh

# Xcode Cloud Post-Clone Script
# Executed by Xcode Cloud runners after cloning the repository.

set -e

echo "=== [Xcode Cloud] Post-Clone Initializing for Neon App ==="
echo "Workflow: \$CI_WORKFLOW"
echo "Product: \$CI_PRODUCT"
echo "Build Number: \$CI_BUILD_NUMBER"
echo "Branch: \$CI_BRANCH"
echo "Commit: \$CI_COMMIT"

# Verify Xcode version
xcodebuild -version

echo "=== [Xcode Cloud] Post-Clone Complete ==="
''';
  }

  String _generatePreXcodebuildScript({String? bundleId}) {
    return '''#!/bin/sh

# Xcode Cloud Pre-Xcodebuild Script
# Automatically bumps the build number using Xcode Cloud's CI_BUILD_NUMBER so TestFlight uploads never conflict.

set -e

echo "=== [Xcode Cloud] Pre-Xcodebuild Script Running ==="

BUILD_NUMBER=\${CI_BUILD_NUMBER:-"1"}
echo "Using CI Build Number: \$BUILD_NUMBER"

# Locate Info.plist files and update CFBundleVersion
find . -name "Info.plist" -not -path "*/Pods/*" -not -path "*/DerivedData/*" | while read plist_file; do
    if [ -f "\$plist_file" ]; then
        echo "Updating build version in \$plist_file to \$BUILD_NUMBER"
        plutil -replace CFBundleVersion -string "\$BUILD_NUMBER" "\$plist_file" 2>/dev/null || true
    fi
done

echo "=== [Xcode Cloud] Pre-Xcodebuild Setup Completed Successfully ==="
''';
  }

  String _generatePostXcodebuildScript() {
    return '''#!/bin/sh

# Xcode Cloud Post-Xcodebuild Script
# Executed after the archive/export step completes.

set -e

echo "=== [Xcode Cloud] Post-Xcodebuild Archive Finished ==="
if [ -n "\$CI_ARCHIVE_PATH" ]; then
    echo "Archive located at: \$CI_ARCHIVE_PATH"
fi
echo "Ready for TestFlight automatic distribution!"
''';
  }
}

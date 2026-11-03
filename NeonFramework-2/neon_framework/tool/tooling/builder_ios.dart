/// Dedicated Cross-OS iOS `.app` and `.ipa` packager for Windows, Linux Ubuntu, and Apple macOS.
library neon_builder_ios;

import 'package:neon_framework/neon.dart';

/// Packages and signs iOS `.app` and `.ipa` archives across Windows, Linux Ubuntu, and macOS.
class NeonIosBuilder {
  const NeonIosBuilder({NeonCrossOsBuilder? builder})
      : _builder = builder ?? const NeonCrossOsBuilder();

  final NeonCrossOsBuilder _builder;

  /// Builds an iOS `.app` bundle on Windows, Linux Ubuntu, or macOS.
  NeonPackageBuildResult buildAppBundle({
    required String appName,
    required String bundleId,
    required String outputDirectory,
    String version = '1.0.0',
    int buildNumber = 1,
    NeonHostOs? hostOs,
    NeonIosBuildMode mode = NeonIosBuildMode.precompiledShellInjection,
  }) =>
      _builder.build(NeonPackageBuildRequest(
        appName: appName,
        bundleId: bundleId,
        version: version,
        buildNumber: buildNumber,
        format: NeonPackageFormat.app,
        outputDirectory: outputDirectory,
        hostOs: hostOs,
        iosMode: mode,
      ));

  /// Builds a signed iOS `.ipa` archive (`Payload/<App>.app`) on Windows, Linux Ubuntu, or macOS.
  NeonPackageBuildResult buildIpaArchive({
    required String appName,
    required String bundleId,
    required String outputDirectory,
    String version = '1.0.0',
    int buildNumber = 1,
    NeonHostOs? hostOs,
    NeonIosBuildMode mode = NeonIosBuildMode.precompiledShellInjection,
  }) =>
      _builder.build(NeonPackageBuildRequest(
        appName: appName,
        bundleId: bundleId,
        version: version,
        buildNumber: buildNumber,
        format: NeonPackageFormat.ipa,
        outputDirectory: outputDirectory,
        hostOs: hostOs,
        iosMode: mode,
      ));
}


/// Dedicated Android `.apk` and `.aab` / `.bundle` builder module for Windows, macOS, and Linux Ubuntu.
library neon_builder_android;

import 'package:neon_framework/neon.dart';

/// Builds signed Android `.apk` and Google Play `.aab` / `.bundle` artifacts across host OSes.
class NeonAndroidBuilder {
  const NeonAndroidBuilder({NeonCrossOsBuilder? builder})
      : _builder = builder ?? const NeonCrossOsBuilder();

  final NeonCrossOsBuilder _builder;

  /// Builds a signed `.apk` on Windows, macOS, or Linux Ubuntu.
  NeonPackageBuildResult buildApk({
    required String appName,
    required String bundleId,
    required String outputDirectory,
    String version = '1.0.0',
    int buildNumber = 1,
    NeonHostOs? hostOs,
    bool releaseMode = true,
  }) =>
      _builder.build(NeonPackageBuildRequest(
        appName: appName,
        bundleId: bundleId,
        version: version,
        buildNumber: buildNumber,
        format: NeonPackageFormat.apk,
        outputDirectory: outputDirectory,
        hostOs: hostOs,
        releaseMode: releaseMode,
      ));

  /// Builds a signed Google Play `.aab` / `.bundle` on Windows, macOS, or Linux Ubuntu.
  NeonPackageBuildResult buildAppBundle({
    required String appName,
    required String bundleId,
    required String outputDirectory,
    String version = '1.0.0',
    int buildNumber = 1,
    NeonHostOs? hostOs,
  }) =>
      _builder.build(NeonPackageBuildRequest(
        appName: appName,
        bundleId: bundleId,
        version: version,
        buildNumber: buildNumber,
        format: NeonPackageFormat.bundle,
        outputDirectory: outputDirectory,
        hostOs: hostOs,
      ));
}


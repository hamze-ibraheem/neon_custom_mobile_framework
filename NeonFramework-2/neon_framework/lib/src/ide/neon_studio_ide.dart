/// Neon Studio IDE Workbench Controller — combining Apple Xcode, Android Studio,
/// Neon-exclusive value-add tools, and Google Antigravity Multi-Agent orchestration.
library neon_studio_ide;

import '../agents/antigravity_agent_hub.dart';
import '../core/feature_options.dart';
import '../language/neon_compiler.dart';
import '../lsp/neon_lsp_server.dart';
import '../packaging/cross_os_builder.dart';

/// Supported project language mode in Neon Studio IDE.
enum NeonProjectLanguageMode {
  /// Declarative `.neon` files compiled by `neonc`.
  neonLangOnly,

  /// Standard `.dart` files using Neon Framework classes directly.
  dartOnly,

  /// Hybrid workspace mixing `.neon` UI components and `.dart` services/widgets.
  hybridNeonAndDart,
}

/// Represents a node in the Xcode-style Visual Route Storyboard Graph.
class NeonStoryboardRouteNode {
  const NeonStoryboardRouteNode({
    required this.routePath,
    required this.componentName,
    required this.sourceFile,
  });

  final String routePath;
  final String componentName;
  final String sourceFile;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'routePath': routePath,
        'componentName': componentName,
        'sourceFile': sourceFile,
      };
}

/// Represents a 3D exploded layer node in the Android Studio-style 3D Layout Inspector.
class Neon3DInspectorLayer {
  const Neon3DInspectorLayer({
    required this.widgetType,
    required this.depthZ,
    required this.line,
    required this.children,
  });

  final String widgetType;
  final int depthZ;
  final int line;
  final List<Neon3DInspectorLayer> children;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'widgetType': widgetType,
        'depthZ': depthZ,
        'line': line,
        'children': children.map((c) => c.toJson()).toList(),
      };
}

/// Represents a recorded frame in the Neon Time-Travel State Scrubber.
class NeonTimeTravelFrame {
  const NeonTimeTravelFrame({
    required this.frameIndex,
    required this.timestampIso,
    required this.description,
    required this.statePayload,
  });

  final int frameIndex;
  final String timestampIso;
  final String description;
  final Map<String, dynamic> statePayload;
}

/// Unified Xcode-style Signing & Capabilities configurator for iOS + Android.
class NeonUnifiedCapabilities {
  const NeonUnifiedCapabilities({
    this.camera = false,
    this.location = false,
    this.pushNotifications = false,
    this.biometrics = false,
    this.networkClient = true,
  });

  final bool camera;
  final bool location;
  final bool pushNotifications;
  final bool biometrics;
  final bool networkClient;

  /// Generates Android permissions for `AndroidManifest.xml`.
  List<String> toAndroidPermissions() => <String>[
        if (networkClient) 'android.permission.INTERNET',
        if (camera) 'android.permission.CAMERA',
        if (location) 'android.permission.ACCESS_FINE_LOCATION',
        if (pushNotifications) 'android.permission.POST_NOTIFICATIONS',
        if (biometrics) 'android.permission.USE_BIOMETRIC',
      ];

  /// Generates iOS usage description keys for `Info.plist`.
  Map<String, String> toIosInfoPlistKeys() => <String, String>{
        if (camera) 'NSCameraUsageDescription': 'Camera access required by app features.',
        if (location)
          'NSLocationWhenInUseUsageDescription': 'Location access required by app features.',
        if (biometrics) 'NSFaceIDUsageDescription': 'FaceID authentication required.',
      };
}

/// Core workbench engine for **Neon Studio IDE**.
class NeonStudioIdeWorkbench {
  NeonStudioIdeWorkbench({
    this.languageMode = NeonProjectLanguageMode.hybridNeonAndDart,
    NeonCompiler? compiler,
    NeonLspServer? lspServer,
    NeonCrossOsBuilder? crossOsBuilder,
    NeonAntigravityAgentHub? agentHub,
    NeonFeatureOptionsManager? featureOptions,
  })  : compiler = compiler ?? const NeonCompiler(),
        lspServer = lspServer ?? NeonLspServer(),
        crossOsBuilder = crossOsBuilder ?? const NeonCrossOsBuilder(),
        agentHub = agentHub ?? NeonAntigravityAgentHub(),
        featureOptions =
            featureOptions ?? NeonFeatureOptionsManager(const NeonFeatureOptions());

  final NeonProjectLanguageMode languageMode;
  final NeonCompiler compiler;
  final NeonLspServer lspServer;
  final NeonCrossOsBuilder crossOsBuilder;
  final NeonAntigravityAgentHub agentHub;
  final NeonFeatureOptionsManager featureOptions;

  final Map<String, String> _workspaceFiles = <String, String>{};
  final List<NeonTimeTravelFrame> _timeTravelHistory = <NeonTimeTravelFrame>[];
  int _activeTimeTravelIndex = -1;

  /// Returns all files currently registered in the IDE workspace.
  Map<String, String> get workspaceFiles => Map<String, String>.unmodifiable(_workspaceFiles);

  /// Returns the recorded Time-Travel state history frames.
  List<NeonTimeTravelFrame> get timeTravelHistory =>
      List<NeonTimeTravelFrame>.unmodifiable(_timeTravelHistory);

  /// Returns the currently selected Time-Travel frame index.
  int get activeTimeTravelIndex => _activeTimeTravelIndex;

  /// Opens or updates a `.neon` or `.dart` file in the IDE workspace.
  List<NeonDiagnostic> openOrUpdateFile(String path, String content) {
    _workspaceFiles[path] = content;
    if (path.endsWith('.neon')) {
      return lspServer.updateDocument(path, content);
    }
    return const <NeonDiagnostic>[];
  }

  /// Extracts the Xcode-style Visual Route Storyboard Graph across all `.neon` files.
  List<NeonStoryboardRouteNode> extractStoryboardGraph() {
    final nodes = <NeonStoryboardRouteNode>[];
    _workspaceFiles.forEach((path, content) {
      if (path.endsWith('.neon')) {
        final compiled = compiler.compileSource(content);
        compiled.routes.forEach((routePath, compName) {
          nodes.add(NeonStoryboardRouteNode(
            routePath: routePath,
            componentName: compName,
            sourceFile: path,
          ));
        });
      }
    });
    return nodes;
  }

  /// Builds the Android Studio-style 3D Exploded Widget Layer Hierarchy for a `.neon` file.
  List<Neon3DInspectorLayer> inspect3DWidgetHierarchy(String path) {
    final content = _workspaceFiles[path];
    if (content == null || !path.endsWith('.neon')) {
      return const <Neon3DInspectorLayer>[];
    }
    final compiled = compiler.compileSource(content);
    final layers = <Neon3DInspectorLayer>[];
    for (final comp in compiled.program.components) {
      for (final rootWidget in comp.viewChildren) {
        layers.add(_mapWidgetTo3DLayer(rootWidget, 0));
      }
    }
    return layers;
  }

  Neon3DInspectorLayer _mapWidgetTo3DLayer(NeonWidgetNode node, int depth) =>
      Neon3DInspectorLayer(
        widgetType: node.widgetName,
        depthZ: depth * 12,
        line: node.line,
        children: node.children.map((c) => _mapWidgetTo3DLayer(c, depth + 1)).toList(),
      );

  /// Records a new state snapshot into the Time-Travel Scrubber timeline.
  NeonTimeTravelFrame recordStateSnapshot({
    required String description,
    required Map<String, dynamic> statePayload,
  }) {
    final frame = NeonTimeTravelFrame(
      frameIndex: _timeTravelHistory.length,
      timestampIso: DateTime.now().toUtc().toIso8601String(),
      description: description,
      statePayload: Map<String, dynamic>.from(statePayload),
    );
    _timeTravelHistory.add(frame);
    _activeTimeTravelIndex = frame.frameIndex;
    return frame;
  }

  /// Scrubs the IDE live preview backward or forward to [frameIndex].
  NeonTimeTravelFrame scrubToFrame(int frameIndex) {
    if (frameIndex < 0 || frameIndex >= _timeTravelHistory.length) {
      throw RangeError.index(frameIndex, _timeTravelHistory, 'frameIndex');
    }
    _activeTimeTravelIndex = frameIndex;
    return _timeTravelHistory[frameIndex];
  }

  /// Builds any mobile package (`.apk`, `.bundle`, `.app`, `.ipa`) from the IDE on
  /// Windows, Apple macOS, or Linux Ubuntu.
  NeonPackageBuildResult buildMobilePackage({
    required String appName,
    required String bundleId,
    required NeonPackageFormat format,
    required String outputDirectory,
    NeonHostOs? hostOs,
    String version = '1.0.0',
    int buildNumber = 1,
  }) {
    final compiledBuffers = StringBuffer();
    _workspaceFiles.forEach((path, content) {
      if (path.endsWith('.neon')) {
        compiledBuffers.writeln(compiler.compileSource(content).dartCode);
      } else if (path.endsWith('.dart')) {
        compiledBuffers.writeln(content);
      }
    });

    return crossOsBuilder.build(NeonPackageBuildRequest(
      appName: appName,
      bundleId: bundleId,
      version: version,
      buildNumber: buildNumber,
      format: format,
      outputDirectory: outputDirectory,
      hostOs: hostOs,
      compiledNeonDartCode: compiledBuffers.toString(),
    ));
  }
}


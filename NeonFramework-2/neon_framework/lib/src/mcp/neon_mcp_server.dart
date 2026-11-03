/// Model Context Protocol (MCP) Server (`neon-mcp-server`) for Neon Framework & Neon Studio IDE.
///
/// Exposes `.neon` compilation, Cross-OS `.apk`/`.bundle`/`.app`/`.ipa` building,
/// live widget tree inspection, RFC-6902 patch metrics, and `NeonFeatureOptions` management
/// to Google Antigravity Agents and external MCP clients.
library neon_mcp_server;

import '../core/feature_options.dart';
import '../language/neon_compiler.dart';
import '../packaging/cross_os_builder.dart';

/// Descriptor for an MCP tool exposed by [NeonMcpServer].
class NeonMcpToolDescriptor {
  const NeonMcpToolDescriptor({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'description': description,
        'inputSchema': inputSchema,
      };
}

/// Model Context Protocol (MCP) server for Neon Studio IDE and Google Antigravity Agents.
class NeonMcpServer {
  NeonMcpServer({
    NeonCompiler? compiler,
    NeonCrossOsBuilder? builder,
    NeonFeatureOptionsManager? featureOptionsManager,
  })  : _compiler = compiler ?? const NeonCompiler(),
        _builder = builder ?? const NeonCrossOsBuilder(),
        _featureManager =
            featureOptionsManager ?? NeonFeatureOptionsManager(const NeonFeatureOptions());

  final NeonCompiler _compiler;
  final NeonCrossOsBuilder _builder;
  final NeonFeatureOptionsManager _featureManager;

  /// Lists all MCP tools registered on this server.
  List<NeonMcpToolDescriptor> listTools() => const <NeonMcpToolDescriptor>[
        NeonMcpToolDescriptor(
          name: 'neon_compile_file',
          description:
              'Compiles declarative NeonLang (.neon) source code into Neon Framework Dart (.dart) code with AST diagnostics and source maps.',
          inputSchema: <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              'source': <String, String>{
                'type': 'string',
                'description': 'The .neon declarative source code to compile.',
              },
            },
            'required': <String>['source'],
          },
        ),
        NeonMcpToolDescriptor(
          name: 'neon_build_package',
          description:
              'Builds signed Android (.apk, .bundle / .aab) or iOS (.app, .ipa) packages on Windows, Apple macOS, or Linux Ubuntu.',
          inputSchema: <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              'appName': <String, String>{'type': 'string'},
              'bundleId': <String, String>{'type': 'string'},
              'format': <String, dynamic>{
                'type': 'string',
                'enum': <String>['apk', 'bundle', 'app', 'ipa'],
              },
              'hostOs': <String, dynamic>{
                'type': 'string',
                'enum': <String>['windows', 'macos', 'linux'],
              },
              'outputDirectory': <String, String>{'type': 'string'},
            },
            'required': <String>['appName', 'bundleId', 'format', 'outputDirectory'],
          },
        ),
        NeonMcpToolDescriptor(
          name: 'neon_update_feature_options',
          description:
              'Inspects or updates live NeonFeatureOptions (RFC-6902 diffing, navigation transitions, rendering, diagnostics).',
          inputSchema: <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              'patch': <String, String>{
                'type': 'object',
                'description': 'Partial JSON map of feature options to update.',
              },
            },
          },
        ),
        NeonMcpToolDescriptor(
          name: 'neon_transpile_flutter_to_neon',
          description:
              'Transpiles Flutter widget source code into NeonLang (.neon) or Neon Framework (.dart) code.',
          inputSchema: <String, dynamic>{
            'type': 'object',
            'properties': <String, dynamic>{
              'flutterCode': <String, String>{'type': 'string'},
            },
            'required': <String>['flutterCode'],
          },
        ),
      ];

  /// Executes an MCP tool call by [toolName] and [arguments].
  Map<String, dynamic> callTool(String toolName, Map<String, dynamic> arguments) {
    switch (toolName) {
      case 'neon_compile_file':
        final source = arguments['source'] as String? ?? '';
        final res = _compiler.compileSource(source);
        return <String, dynamic>{
          'isSuccess': res.isSuccess,
          'dartCode': res.dartCode,
          'routes': res.routes,
          'diagnostics': res.diagnostics.map((d) => d.toJson()).toList(),
          'sourceMap': res.sourceMap.map((s) => s.toJson()).toList(),
        };

      case 'neon_build_package':
        final formatStr = arguments['format'] as String? ?? 'apk';
        final hostStr = arguments['hostOs'] as String?;
        final format = NeonPackageFormat.values.firstWhere(
          (f) => f.name == formatStr,
          orElse: () => NeonPackageFormat.apk,
        );
        final host = hostStr != null
            ? NeonHostOs.values.firstWhere(
                (h) => h.name == hostStr,
                orElse: NeonHostOs.detect,
              )
            : NeonHostOs.detect();

        final result = _builder.build(NeonPackageBuildRequest(
          appName: arguments['appName'] as String? ?? 'NeonApp',
          bundleId: arguments['bundleId'] as String? ?? 'dev.neonframework.app',
          version: arguments['version'] as String? ?? '1.0.0',
          buildNumber: (arguments['buildNumber'] as int?) ?? 1,
          format: format,
          hostOs: host,
          outputDirectory: arguments['outputDirectory'] as String? ?? 'build/mcp_out',
        ));
        return result.toJson();

      case 'neon_update_feature_options':
        final patch = arguments['patch'] as Map<String, dynamic>?;
        if (patch != null && patch.isNotEmpty) {
          _featureManager.updateFromJson(patch);
        }
        return <String, dynamic>{
          'status': 'updated',
          'featureOptions': _featureManager.current.toJson(),
        };

      case 'neon_transpile_flutter_to_neon':
        final flutterCode = arguments['flutterCode'] as String? ?? '';
        final neonDart = flutterCode
            .replaceAll("import 'package:flutter/material.dart';", "import 'package:neon_framework/neon.dart';")
            .replaceAll(RegExp(r'\bStatelessWidget\b'), 'NeonStatelessWidget')
            .replaceAll(RegExp(r'\bStatefulWidget\b'), 'NeonStatefulWidget')
            .replaceAll(RegExp(r'\bBuildContext\b'), 'NeonBuildContext')
            .replaceAll(RegExp(r'\bScaffold\b'), 'NeonScaffold')
            .replaceAll(RegExp(r'\bAppBar\b'), 'NeonAppBar')
            .replaceAll(RegExp(r'\bColumn\b'), 'NeonColumn')
            .replaceAll(RegExp(r'\bRow\b'), 'NeonRow')
            .replaceAll(RegExp(r'\bText\b'), 'NeonText')
            .replaceAll(RegExp(r'\bElevatedButton\b'), 'NeonButton')
            .replaceAll(RegExp(r'\bContainer\b'), 'NeonContainer');
        return <String, dynamic>{
          'status': 'transpiled',
          'neonDartCode': neonDart,
        };

      default:
        return <String, dynamic>{
          'error': 'Unknown MCP tool: $toolName',
        };
    }
  }
}

/// Google Antigravity SDK Multi-Agent Hub & Model Router for Neon Studio IDE.
///
/// Orchestrates autonomous and interactive coding subagents powered by the
/// Google Antigravity SDK (`google-antigravity`), supporting both hosted Gemini models
/// (`LocalAgentConfig`) and 100% offline on-device models (`LiteRTAgentConfig` / `LocalOpenAIAgentConfig`).
library neon_antigravity_agent_hub;

import '../mcp/neon_mcp_server.dart';

/// Model execution backend supported in Neon Studio IDE via Google Antigravity SDK.
enum NeonAntigravityModelBackend {
  /// Hosted Gemini models via `LocalAgentConfig` (defaults to `gemini-3.8-flash`).
  geminiCloud,

  /// Gemini Enterprise Agent Platform (Vertex AI Standard ADC or Express API Key).
  geminiVertexEnterprise,

  /// Managed on-device local execution via Google's `LiteRTAgentConfig` (e.g., Gemma 4 26B).
  liteRtOnDevice,

  /// External OpenAI-compatible local server via `LocalOpenAIAgentConfig` (Ollama, LM Studio).
  localOpenAiCompatible,
}

/// Specialist subagent role inside Neon Studio IDE.
enum NeonSubagentRole {
  uiArchitect,
  bridgeDoctor,
  flutterMigrator,
  releasePackager,
}

/// Configuration for a specialist subagent in the Neon Studio Antigravity fleet.
class NeonSubagentSpec {
  const NeonSubagentSpec({
    required this.name,
    required this.role,
    required this.description,
    required this.enabledMcpTools,
    this.autonomous = true,
  });

  final String name;
  final NeonSubagentRole role;
  final String description;
  final List<String> enabledMcpTools;
  final bool autonomous;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'role': role.name,
        'description': description,
        'enabledMcpTools': enabledMcpTools,
        'agentBehavior': autonomous ? 'AUTONOMOUS' : 'INTERACTIVE',
      };
}

/// Orchestrates Google Antigravity Agents, Subagents, and MCP Tools inside Neon Studio IDE.
class NeonAntigravityAgentHub {
  NeonAntigravityAgentHub({
    this.backend = NeonAntigravityModelBackend.geminiCloud,
    this.localModelPath = '~/.litert-lm/models/gemma4-26b/model.litertlm',
    this.localServerBaseUrl = 'http://localhost:11434/v1',
    this.maxSubagentDepth = 3,
    NeonMcpServer? mcpServer,
  }) : mcpServer = mcpServer ?? NeonMcpServer();

  final NeonAntigravityModelBackend backend;
  final String localModelPath;
  final String localServerBaseUrl;
  final int maxSubagentDepth;
  final NeonMcpServer mcpServer;

  /// Returns the 4 built-in specialist subagents configured for Neon Studio IDE.
  List<NeonSubagentSpec> get subagents => const <NeonSubagentSpec>[
        NeonSubagentSpec(
          name: 'neon_ui_architect',
          role: NeonSubagentRole.uiArchitect,
          description:
              'Designs and compiles declarative .neon UI components and previews them on the Dual-OS iOS/Android Canvas.',
          enabledMcpTools: <String>['neon_compile_file', 'neon_update_feature_options'],
        ),
        NeonSubagentSpec(
          name: 'neon_bridge_doctor',
          role: NeonSubagentRole.bridgeDoctor,
          description:
              'Audits RFC-6902 JSON patch diffs, state boundaries, and live feature options to keep frame latency <16ms.',
          enabledMcpTools: <String>['neon_update_feature_options'],
        ),
        NeonSubagentSpec(
          name: 'neon_flutter_migrator',
          role: NeonSubagentRole.flutterMigrator,
          description:
              'Autonomously transpiles Flutter widgets and screens into NeonLang (.neon) or Neon Framework (.dart).',
          enabledMcpTools: <String>['neon_transpile_flutter_to_neon', 'neon_compile_file'],
        ),
        NeonSubagentSpec(
          name: 'neon_release_packager',
          role: NeonSubagentRole.releasePackager,
          description:
              'Builds and signs Android (.apk, .bundle/.aab) and iOS (.app, .ipa) packages on Windows, macOS, and Linux Ubuntu.',
          enabledMcpTools: <String>['neon_build_package'],
        ),
      ];

  /// Dispatches a task to a specific [NeonSubagentRole] and executes any associated MCP tool action.
  Map<String, dynamic> dispatchSubagentTask({
    required NeonSubagentRole role,
    required String prompt,
    Map<String, dynamic> toolArgs = const <String, dynamic>{},
  }) {
    final spec = subagents.firstWhere((s) => s.role == role);
    Map<String, dynamic>? toolOutput;

    if (role == NeonSubagentRole.uiArchitect && toolArgs.containsKey('source')) {
      toolOutput = mcpServer.callTool('neon_compile_file', toolArgs);
    } else if (role == NeonSubagentRole.flutterMigrator &&
        toolArgs.containsKey('flutterCode')) {
      toolOutput = mcpServer.callTool('neon_transpile_flutter_to_neon', toolArgs);
    } else if (role == NeonSubagentRole.releasePackager &&
        toolArgs.containsKey('format')) {
      toolOutput = mcpServer.callTool('neon_build_package', toolArgs);
    } else if (role == NeonSubagentRole.bridgeDoctor) {
      toolOutput = mcpServer.callTool('neon_update_feature_options', toolArgs);
    }

    return <String, dynamic>{
      'subagent': spec.name,
      'backend': backend.name,
      'prompt': prompt,
      'status': 'completed',
      if (toolOutput != null) 'toolOutput': toolOutput,
    };
  }

  /// Generates a ready-to-run Python `google-antigravity` SDK configuration script
  /// matching the selected [backend] and subagent hierarchy.
  String generateAntigravitySdkPythonConfig() => '''
import os
from google.antigravity import (
    Agent,
    LiteRTAgentConfig,
    LiteRTBackend,
    LocalAgentConfig,
    LocalOpenAIAgentConfig,
    types,
)

def create_neon_studio_agent(mode: str = "${backend.name}"):
    neon_mcp = types.McpStdioServer(
        name="neon_mcp_server",
        command="dart",
        args=["run", "tool/mcp/neon_mcp_main.dart"],
    )

    subagents = [
        types.SubagentConfig(
            name="neon_ui_architect",
            description="Designs and compiles .neon UI components for iOS and Android.",
            capabilities=types.SubagentCapabilities(
                agent_behavior=types.AgentBehavior.AUTONOMOUS,
            ),
        ),
        types.SubagentConfig(
            name="neon_bridge_doctor",
            description="Optimizes RFC-6902 tree diffing and frame latency.",
            capabilities=types.SubagentCapabilities(
                agent_behavior=types.AgentBehavior.AUTONOMOUS,
            ),
        ),
        types.SubagentConfig(
            name="neon_flutter_migrator",
            description="Migrates Flutter codebases to NeonLang (.neon) and Neon Dart.",
            capabilities=types.SubagentCapabilities(
                agent_behavior=types.AgentBehavior.AUTONOMOUS,
            ),
        ),
        types.SubagentConfig(
            name="neon_release_packager",
            description="Builds .apk, .bundle, .app, and .ipa across Windows, macOS, and Linux.",
            capabilities=types.SubagentCapabilities(
                agent_behavior=types.AgentBehavior.AUTONOMOUS,
            ),
        ),
    ]

    capabilities = types.CapabilitiesConfig(
        enable_subagents=True,
        max_subagent_depth=$maxSubagentDepth,
        allowed_subagents=[s.name for s in subagents],
    )

    if mode == "liteRtOnDevice":
        return Agent(
            LiteRTAgentConfig(
                model_path=os.path.expanduser("$localModelPath"),
                backend=LiteRTBackend.GPU,
                mcp_servers=[neon_mcp],
                subagents=subagents,
                capabilities=capabilities,
            )
        )
    elif mode == "localOpenAiCompatible":
        return Agent(
            LocalOpenAIAgentConfig(
                base_url="$localServerBaseUrl",
                model="gemma4:latest",
                mcp_servers=[neon_mcp],
                subagents=subagents,
                capabilities=capabilities,
            )
        )
    else:
        # Default Hosted Gemini via LocalAgentConfig (uses GEMINI_API_KEY)
        return Agent(
            LocalAgentConfig(
                mcp_servers=[neon_mcp],
                subagents=subagents,
                capabilities=capabilities,
            )
        )
''';
}


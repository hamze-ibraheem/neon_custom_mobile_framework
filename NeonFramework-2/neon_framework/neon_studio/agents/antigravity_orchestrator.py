"""
Neon Studio IDE — Google Antigravity SDK Multi-Agent Orchestrator
Supports Hosted Gemini Models (LocalAgentConfig / Vertex) and 100% Offline Local Models
(LiteRTAgentConfig with Gemma 4 & LocalOpenAIAgentConfig with Ollama/LM Studio).
"""

import asyncio
import os
from google.antigravity import (
    Agent,
    LiteRTAgentConfig,
    LiteRTBackend,
    LocalAgentConfig,
    LocalOpenAIAgentConfig,
    types,
)


def build_neon_studio_config(backend_mode: str = "geminiCloud"):
    neon_mcp = types.McpStdioServer(
        name="neon_mcp_server",
        command="dart",
        args=["run", "tool/mcp/neon_mcp_main.dart"],
    )

    ui_architect = types.SubagentConfig(
        name="neon_ui_architect",
        description="Generates and compiles declarative .neon UI components with <100ms live preview.",
        capabilities=types.SubagentCapabilities(
            agent_behavior=types.AgentBehavior.AUTONOMOUS,
        ),
    )

    bridge_doctor = types.SubagentConfig(
        name="neon_bridge_doctor",
        description="Monitors RFC-6902 tree diff patches and optimizes NeonFeatureOptions.",
        capabilities=types.SubagentCapabilities(
            agent_behavior=types.AgentBehavior.AUTONOMOUS,
        ),
    )

    flutter_migrator = types.SubagentConfig(
        name="neon_flutter_migrator",
        description="Transpiles Flutter widgets and apps into NeonLang (.neon) or Neon Dart (.dart).",
        capabilities=types.SubagentCapabilities(
            agent_behavior=types.AgentBehavior.AUTONOMOUS,
        ),
    )

    release_packager = types.SubagentConfig(
        name="neon_release_packager",
        description="Builds signed Android (.apk, .bundle/.aab) and iOS (.app, .ipa) on Windows, macOS, and Ubuntu.",
        capabilities=types.SubagentCapabilities(
            agent_behavior=types.AgentBehavior.AUTONOMOUS,
        ),
    )

    subagents = [ui_architect, bridge_doctor, flutter_migrator, release_packager]
    capabilities = types.CapabilitiesConfig(
        enable_subagents=True,
        max_subagent_depth=3,
        allowed_subagents=[s.name for s in subagents],
    )

    if backend_mode == "liteRtOnDevice":
        model_path = os.path.expanduser("~/.litert-lm/models/gemma4-26b/model.litertlm")
        return LiteRTAgentConfig(
            model_path=model_path,
            backend=LiteRTBackend.GPU,
            mcp_servers=[neon_mcp],
            subagents=subagents,
            capabilities=capabilities,
        )

    if backend_mode == "localOpenAiCompatible":
        return LocalOpenAIAgentConfig(
            base_url=os.environ.get("NEON_LOCAL_LLM_URL", "http://localhost:11434/v1"),
            model=os.environ.get("NEON_LOCAL_LLM_MODEL", "gemma4:latest"),
            mcp_servers=[neon_mcp],
            subagents=subagents,
            capabilities=capabilities,
        )

    return LocalAgentConfig(
        mcp_servers=[neon_mcp],
        subagents=subagents,
        capabilities=capabilities,
    )


async def run_interactive_session(prompt: str, backend_mode: str = "geminiCloud"):
    config = build_neon_studio_config(backend_mode=backend_mode)
    async with Agent(config=config) as agent:
        response = await agent.chat(prompt)
        print(await response.text())


if __name__ == "__main__":
    sample_prompt = (
        "Use neon_ui_architect to compile our TaskStudioScreen.neon component and "
        "use neon_release_packager to build both Android .apk and iOS .ipa packages."
    )
    asyncio.run(run_interactive_session(sample_prompt))


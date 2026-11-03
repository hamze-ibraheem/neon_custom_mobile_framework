/// Stdio Model Context Protocol (MCP) Server entrypoint (`neon-mcp-server`).
///
/// Invoked by the Google Antigravity SDK (`types.McpStdioServer`) and Neon Studio IDE.
library neon_mcp_main;

import 'dart:convert';
import 'dart:io';
import 'package:neon_framework/neon.dart';

Future<void> main() async {
  final mcp = NeonMcpServer();
  await for (final String line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    try {
      final req = jsonDecode(line) as Map<String, dynamic>;
      final id = req['id'];
      final method = req['method'] as String? ?? '';
      final params = (req['params'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

      if (method == 'tools/list') {
        stdout.writeln(jsonEncode(<String, dynamic>{
          'jsonrpc': '2.0',
          'id': id,
          'result': <String, dynamic>{
            'tools': mcp.listTools().map((t) => t.toJson()).toList(),
          },
        }));
      } else if (method == 'tools/call') {
        final name = params['name'] as String? ?? '';
        final args =
            (params['arguments'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
        final output = mcp.callTool(name, args);
        stdout.writeln(jsonEncode(<String, dynamic>{
          'jsonrpc': '2.0',
          'id': id,
          'result': <String, dynamic>{
            'content': <Map<String, String>>[
              <String, String>{
                'type': 'text',
                'text': jsonEncode(output),
              },
            ],
          },
        }));
      } else {
        stdout.writeln(jsonEncode(<String, dynamic>{
          'jsonrpc': '2.0',
          'id': id,
          'result': <String, dynamic>{
            'protocolVersion': '2024-11-05',
            'serverInfo': <String, String>{
              'name': 'neon-mcp-server',
              'version': '1.0.0',
            },
          },
        }));
      }
    } catch (_) {
      // Ignore invalid JSON-RPC frame
    }
  }
}


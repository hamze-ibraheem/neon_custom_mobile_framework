/// Stdio JSON-RPC 2.0 entrypoint for `neon-lsp` (Language Server Protocol).
library neon_lsp_main;

import 'dart:convert';
import 'dart:io';
import 'package:neon_framework/neon.dart';

Future<void> main() async {
  final lsp = NeonLspServer();
  await for (final String line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().isEmpty || line.startsWith('Content-Length:')) {
      continue;
    }
    try {
      final req = jsonDecode(line) as Map<String, dynamic>;
      final resp = lsp.handleRequest(req);
      stdout.writeln(jsonEncode(resp));
    } catch (_) {
      // Ignore malformed stdio frame
    }
  }
}


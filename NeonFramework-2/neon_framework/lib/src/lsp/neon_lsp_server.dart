/// Language Server Protocol (LSP) engine (`neon-lsp`) for `.neon` files.
///
/// Provides real-time syntax & semantic diagnostics, context-aware autocomplete,
/// hover documentation, and go-to-definition for Neon Studio IDE, VS Code, and Antigravity.
library neon_lsp_server;

import '../language/neon_compiler.dart';

/// Represents an autocomplete suggestion returned by [NeonLspServer].
class NeonCompletionItem {
  const NeonCompletionItem({
    required this.label,
    required this.kind,
    required this.detail,
    required this.insertText,
  });

  final String label;
  final String kind;
  final String detail;
  final String insertText;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'kind': kind,
        'detail': detail,
        'insertText': insertText,
      };
}

/// JSON-RPC 2.0 Language Server for `.neon` and `.dart` hybrid workspaces.
class NeonLspServer {
  NeonLspServer({NeonCompiler? compiler})
      : _compiler = compiler ?? const NeonCompiler();

  final NeonCompiler _compiler;
  final Map<String, String> _openDocuments = <String, String>{};
  final Map<String, NeonCompilationResult> _cachedCompilations =
      <String, NeonCompilationResult>{};

  static const Map<String, String> _widgetDocs = <String, String>{
    'Scaffold': 'Top-level Material 3 / Cupertino page structure with AppBar, Body, and FloatingActionButton.',
    'Column': 'Arranges child widgets vertically with optional `padding` and `gap` spacing.',
    'Row': 'Arranges child widgets horizontally with alignment and spacing.',
    'Text': 'Renders native typography (`UILabel` on iOS, `TextView` on Android) with `.font()` and `.color()` modifiers.',
    'Card': 'Elevated surface container with rounded corners and shadow elevation.',
    'Button': 'Interactive native button that automatically wraps state mutations in `setState()`.',
    'Badge': 'Compact status indicator pill.',
    'ForEach': 'Reactive collection repeater (`ForEach(items) -> item { ... }`).',
    'If': 'Conditional declarative branch (`If (condition) { ... } Else { ... }`).',
  };

  /// Handles an incoming JSON-RPC 2.0 LSP request map and returns a response map.
  Map<String, dynamic> handleRequest(Map<String, dynamic> request) {
    final id = request['id'];
    final method = request['method'] as String? ?? '';
    final params = (request['params'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    switch (method) {
      case 'initialize':
        return <String, dynamic>{
          'jsonrpc': '2.0',
          'id': id,
          'result': <String, dynamic>{
            'serverInfo': <String, String>{
              'name': 'neon-lsp',
              'version': '1.0.0',
            },
            'capabilities': <String, dynamic>{
              'textDocumentSync': 1,
              'completionProvider': <String, dynamic>{
                'triggerCharacters': <String>['.', '@', '('],
              },
              'hoverProvider': true,
              'definitionProvider': true,
            },
          },
        };

      case 'textDocument/didOpen':
      case 'textDocument/didChange':
        final uri = params['uri'] as String? ?? 'untitled.neon';
        final text = params['text'] as String? ?? '';
        final diagnostics = updateDocument(uri, text);
        return <String, dynamic>{
          'jsonrpc': '2.0',
          'method': 'textDocument/publishDiagnostics',
          'params': <String, dynamic>{
            'uri': uri,
            'diagnostics': diagnostics.map((d) => d.toJson()).toList(),
          },
        };

      case 'textDocument/completion':
        final prefix = params['prefix'] as String? ?? '';
        final items = provideCompletions(prefix: prefix);
        return <String, dynamic>{
          'jsonrpc': '2.0',
          'id': id,
          'result': items.map((i) => i.toJson()).toList(),
        };

      case 'textDocument/hover':
        final symbol = params['symbol'] as String? ?? '';
        final hoverText = provideHover(symbol);
        return <String, dynamic>{
          'jsonrpc': '2.0',
          'id': id,
          'result': <String, dynamic>{
            'contents': hoverText,
          },
        };

      case 'textDocument/definition':
        final uri = params['uri'] as String? ?? '';
        final symbol = params['symbol'] as String? ?? '';
        final defLoc = provideDefinition(uri, symbol);
        return <String, dynamic>{
          'jsonrpc': '2.0',
          'id': id,
          'result': defLoc,
        };

      default:
        return <String, dynamic>{
          'jsonrpc': '2.0',
          'id': id,
          'result': <String, dynamic>{'status': 'ok'},
        };
    }
  }

  /// Updates an open `.neon` document in memory, compiles it, and returns diagnostics.
  List<NeonDiagnostic> updateDocument(String uri, String content) {
    _openDocuments[uri] = content;
    final result = _compiler.compileSource(content);
    _cachedCompilations[uri] = result;
    return result.diagnostics;
  }

  /// Returns context-aware autocomplete suggestions for `.neon` code.
  List<NeonCompletionItem> provideCompletions({String prefix = ''}) {
    if (prefix.startsWith('.')) {
      return NeonSemanticAnalyzer.supportedModifiers
          .map(
            (mod) => NeonCompletionItem(
              label: '.$mod',
              kind: 'Method',
              detail: 'NeonLang Widget Modifier',
              insertText: '$mod()',
            ),
          )
          .toList();
    }

    if (prefix.startsWith('@')) {
      return const <NeonCompletionItem>[
        NeonCompletionItem(
          label: '@state',
          kind: 'Keyword',
          detail: 'Reactive state field triggering RFC-6902 incremental patches',
          insertText: '@state name: Int = 0',
        ),
        NeonCompletionItem(
          label: '@computed',
          kind: 'Keyword',
          detail: 'Derived reactive getter',
          insertText: '@computed total: Int = 0',
        ),
        NeonCompletionItem(
          label: '@persist',
          kind: 'Keyword',
          detail: 'Locally persisted reactive state field',
          insertText: '@persist theme: String = "dark"',
        ),
      ];
    }

    return NeonSemanticAnalyzer.builtInWidgets
        .map(
          (w) => NeonCompletionItem(
            label: w,
            kind: 'Class',
            detail: _widgetDocs[w] ?? 'Neon Framework Declarative Widget',
            insertText: '$w {\n  \n}',
          ),
        )
        .toList();
  }

  /// Returns markdown hover documentation for a widget, modifier, or keyword.
  String provideHover(String symbol) {
    final clean = symbol.replaceFirst('.', '');
    if (_widgetDocs.containsKey(clean)) {
      return '### `$clean` (NeonLang Widget)\n${_widgetDocs[clean]}';
    }
    if (NeonSemanticAnalyzer.supportedModifiers.contains(clean)) {
      return '### `.$clean(...)` (NeonLang Modifier)\nChains styling or layout configuration onto the target widget.';
    }
    return '### `$symbol`\nNeonLang symbol in active workspace.';
  }

  /// Resolves go-to-definition coordinates for a component or `@state` variable in [uri].
  Map<String, dynamic> provideDefinition(String uri, String symbol) {
    final compiled = _cachedCompilations[uri];
    if (compiled != null) {
      for (final comp in compiled.program.components) {
        if (comp.name == symbol) {
          return <String, dynamic>{
            'uri': uri,
            'line': comp.line,
            'column': comp.column,
          };
        }
        for (final st in comp.states) {
          if (st.name == symbol) {
            return <String, dynamic>{
              'uri': uri,
              'line': st.line,
              'column': st.column,
            };
          }
        }
      }
      for (final st in compiled.program.topLevelStates) {
        if (st.name == symbol) {
          return <String, dynamic>{
            'uri': uri,
            'line': st.line,
            'column': st.column,
          };
        }
      }
    }
    return <String, dynamic>{
      'uri': uri,
      'line': 1,
      'column': 1,
    };
  }
}


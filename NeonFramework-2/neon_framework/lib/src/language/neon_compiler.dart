/// High-level NeonLang (`.neon`) compiler uniting Lexer, Parser, Semantic Analyzer, and Codegen.
library neon_compiler;

import 'analyzer.dart';
import 'ast.dart';
import 'codegen.dart';
import 'lexer.dart';
import 'parser.dart';

export 'analyzer.dart';
export 'ast.dart';
export 'codegen.dart';
export 'lexer.dart';
export 'parser.dart';

/// Complete result of compiling a `.neon` source file.
class NeonCompilationResult {
  const NeonCompilationResult({
    required this.program,
    required this.dartCode,
    required this.diagnostics,
    required this.sourceMap,
    required this.routes,
  });

  final NeonProgramNode program;
  final String dartCode;
  final List<NeonDiagnostic> diagnostics;
  final List<NeonSourceMapEntry> sourceMap;
  final Map<String, String> routes;

  /// Returns `true` if no error-level diagnostics were emitted.
  bool get isSuccess =>
      !diagnostics.any((d) => d.severity == NeonDiagnosticSeverity.error);
}

/// Primary compiler façade (`neonc`) for compiling `.neon` declarative source code
/// into Neon Framework `.dart` code with full 1:1 source maps and diagnostics.
class NeonCompiler {
  const NeonCompiler();

  /// Compiles a `.neon` [source] string and returns a [NeonCompilationResult].
  NeonCompilationResult compileSource(String source) {
    final lexer = NeonLexer(source);
    final tokens = lexer.tokenize();

    final parser = NeonParser(tokens);
    final program = parser.parse();

    final analyzer = NeonSemanticAnalyzer();
    final semanticDiagnostics = analyzer.analyze(program);

    final allDiagnostics = <NeonDiagnostic>[
      ...parser.diagnostics,
      ...semanticDiagnostics,
    ];

    final codegen = NeonCodeGenerator();
    final output = codegen.generate(program);

    return NeonCompilationResult(
      program: program,
      dartCode: output.dartCode,
      diagnostics: allDiagnostics,
      sourceMap: output.sourceMap,
      routes: output.routes,
    );
  }
}


import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:neon_framework/neon.dart';
import 'cli.dart';

/// CLI command (`neon compile <file.neon>`) to compile declarative `.neon` files into `.dart`.
class CompileCommand extends Command<int> {
  CompileCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output .dart file path (defaults to <input>.neon.dart).',
    );
  }

  @override
  final String name = 'compile';

  @override
  final String description =
      'Compile declarative NeonLang (.neon) source files into Neon Framework Dart (.dart).';

  @override
  Future<int> run() async {
    final args = argResults!;
    if (args.rest.isEmpty) {
      NeonLogger.error('Usage: neon compile <file.neon> [-o output.dart]');
      return 1;
    }

    final inputPath = args.rest.first;
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) {
      NeonLogger.error('Input file not found: $inputPath');
      return 1;
    }

    final outputPath = (args['output'] as String?) ?? '$inputPath.dart';
    final source = inputFile.readAsStringSync();

    NeonLogger.header('NeonLang Compiler (neonc)');
    NeonLogger.step('Compiling $inputPath -> $outputPath');

    const compiler = NeonCompiler();
    final result = compiler.compileSource(source);

    for (final diag in result.diagnostics) {
      if (diag.severity == NeonDiagnosticSeverity.error) {
        NeonLogger.error('$diag');
      } else {
        NeonLogger.warning('$diag');
      }
    }

    if (!result.isSuccess) {
      NeonLogger.error('Compilation failed with syntax/semantic errors.');
      return 1;
    }

    File(outputPath).writeAsStringSync(result.dartCode);
    NeonLogger.success(
      'Compiled ${result.program.components.length} component(s) to $outputPath '
      '(${result.sourceMap.length} source-map entries).',
    );
    return 0;
  }
}


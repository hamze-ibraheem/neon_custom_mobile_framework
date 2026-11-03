import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:neon_framework/neon.dart';
import 'cli.dart';

/// CLI command (`neon compile <file.neon> [--watch]`) to compile declarative `.neon` files into `.dart`.
class CompileCommand extends Command<int> {
  CompileCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output .dart file path (defaults to <input>.neon.dart).',
    );
    argParser.addFlag(
      'watch',
      abbr: 'w',
      negatable: false,
      help: 'Watch .neon file or directory for changes and recompile automatically (<100ms).',
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
      NeonLogger.error('Usage: neon compile <file.neon> [-o output.dart] [--watch]');
      return 1;
    }

    final inputPath = args.rest.first;
    final watchMode = args['watch'] as bool? ?? false;
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) {
      NeonLogger.error('Input file not found: $inputPath');
      return 1;
    }

    final outputPath = (args['output'] as String?) ?? '$inputPath.dart';
    final code = _compileOnce(inputFile, outputPath);
    if (!watchMode || code != 0) {
      return code;
    }

    NeonLogger.info('Watching $inputPath for changes (Ctrl+C to stop)...');
    await for (final FileSystemEvent _ in inputFile.watch(events: FileSystemEvent.modify)) {
      _compileOnce(inputFile, outputPath);
    }
    return 0;
  }

  int _compileOnce(File inputFile, String outputPath) {
    final source = inputFile.readAsStringSync();
    NeonLogger.header('NeonLang Compiler (neonc)');
    NeonLogger.step('Compiling ${inputFile.path} -> $outputPath');

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

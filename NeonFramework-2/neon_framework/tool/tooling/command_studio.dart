import 'dart:io';
import 'package:args/command_runner.dart';
import 'cli.dart';

/// CLI command (`neon studio`) to launch the Neon Studio IDE Workbench.
class StudioCommand extends Command<int> {
  StudioCommand() {
    argParser.addOption(
      'port',
      abbr: 'p',
      help: 'Port to run the Neon Studio IDE server on.',
      defaultsTo: '9090',
    );
  }

  @override
  final String name = 'studio';

  @override
  final String description =
      'Launch Neon Studio IDE Workbench (Xcode + Android Studio + Antigravity Agents).';

  @override
  Future<int> run() async {
    final port = argResults!['port'] as String;
    NeonLogger.header('Launching Neon Studio IDE on http://localhost:$port');
    final proc = await Process.start(
      'dart',
      ['run', 'neon_studio/neon_studio_server.dart', port],
      mode: ProcessStartMode.inheritStdio,
    );
    return proc.exitCode;
  }
}


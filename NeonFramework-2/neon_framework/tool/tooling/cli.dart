import 'package:args/command_runner.dart';
import 'command_create.dart';
import 'command_run.dart';
import 'command_build.dart';
import 'command_compile.dart';
import 'command_studio.dart';
import 'command_doctor.dart';
import 'command_clean.dart';

class NeonCli {
  static const String version = '0.1.0';

  late final CommandRunner<int> _runner;

  NeonCli() {
    _runner = CommandRunner<int>(
      'neon',
      'Neon Framework CLI — Build mobile apps with NeonLang (.neon) & Dart (.dart).',
    );

    _runner.addCommand(CreateCommand());
    _runner.addCommand(RunCommand());
    _runner.addCommand(BuildCommand());
    _runner.addCommand(CompileCommand());
    _runner.addCommand(StudioCommand());
    _runner.addCommand(DoctorCommand());
    _runner.addCommand(CleanCommand());

    _runner.argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print the Neon CLI version.',
    );
  }

  Future<int> run(List<String> args) async {
    try {
      final topResults = _runner.argParser.parse(args);
      if (topResults['version'] == true) {
        NeonLogger.info('Neon CLI v$version');
        return 0;
      }

      final result = await _runner.run(args);
      return result ?? 0;
    } on UsageException catch (e) {
      NeonLogger.error(e.message);
      NeonLogger.info('');
      NeonLogger.info(e.usage);
      return 1;
    } on FormatException catch (e) {
      NeonLogger.error(e.message);
      return 1;
    } catch (e) {
      NeonLogger.error('$e');
      return 1;
    }
  }
}

class NeonLogger {
  static void info(String message) {
    print(message);
  }

  static void success(String message) {
    print('[OK] $message');
  }

  static void warning(String message) {
    print('[WARN] $message');
  }

  static void error(String message) {
    print('[ERROR] $message');
  }

  static void step(String message) {
    print('  > $message');
  }

  static void header(String title) {
    print('');
    print('--- $title ---');
  }
}

import 'dart:io';
import 'package:args/command_runner.dart';
import 'cli.dart';

class CleanCommand extends Command<int> {
  @override
  final String name = 'clean';

  @override
  final String description = 'Clean build artifacts and caches.';

  CleanCommand() {
    argParser.addFlag(
      'deep',
      help: 'Also remove .dart_tool and pubspec.lock.',
      negatable: false,
    );
  }

  @override
  Future<int> run() async {
    final args = argResults!;
    final deep = args['deep'] as bool;

    NeonLogger.header('Neon Clean');

    int cleaned = 0;

    cleaned += _removeDir('build');
    cleaned += _removeDir('.dart_tool/hot_reload');

    if (deep) {
      cleaned += _removeDir('.dart_tool');
      cleaned += _removeFile('pubspec.lock');
    }

    if (cleaned == 0) {
      NeonLogger.info('Nothing to clean.');
    } else {
      NeonLogger.success('Cleaned $cleaned item(s).');
    }

    if (deep) {
      NeonLogger.step('Run "dart pub get" to restore dependencies.');
    }

    return 0;
  }

  int _removeDir(String path) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
      NeonLogger.step('Removed $path/');
      return 1;
    }
    return 0;
  }

  int _removeFile(String path) {
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
      NeonLogger.step('Removed $path');
      return 1;
    }
    return 0;
  }
}

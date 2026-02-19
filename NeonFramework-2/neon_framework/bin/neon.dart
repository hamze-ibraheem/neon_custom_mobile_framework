import 'dart:io';
import '../tool/tooling/cli.dart';

Future<void> main(List<String> args) async {
  final cli = NeonCli();
  final exitCode = await cli.run(args);
  exit(exitCode);
}

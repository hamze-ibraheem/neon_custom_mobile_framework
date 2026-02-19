import 'dart:io';
import 'package:path/path.dart' as p;

class ScaffoldResult {
  final bool success;
  final String message;
  final int filesCreated;

  const ScaffoldResult({
    required this.success,
    required this.message,
    this.filesCreated = 0,
  });
}

class NeonProjectTemplate {
  final String projectName;
  final String template;

  const NeonProjectTemplate({
    required this.projectName,
    required this.template,
  });

  Map<String, String> generate() {
    switch (template) {
      case 'minimal':
        return _generateMinimal();
      case 'app':
      default:
        return _generateApp();
    }
  }

  ScaffoldResult writeFiles(Map<String, String> files) {
    final projectDir = Directory(projectName);
    if (projectDir.existsSync()) {
      return ScaffoldResult(
        success: false,
        message: 'Directory "$projectName" already exists.',
      );
    }

    int count = 0;
    for (final entry in files.entries) {
      final filePath = p.join(projectName, entry.key);
      final file = File(filePath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
      count++;
    }

    return ScaffoldResult(
      success: true,
      message: 'Created $count files.',
      filesCreated: count,
    );
  }

  Map<String, String> _generateApp() {
    return {
      'pubspec.yaml': _pubspec(),
      'analysis_options.yaml': _analysisOptions(),
      'lib/main.dart': _mainApp(),
      'lib/app.dart': _appWidget(),
      'lib/screens/home_screen.dart': _homeScreen(),
      'neon.yaml': _neonConfig(),
      '.gitignore': _gitignore(),
    };
  }

  Map<String, String> _generateMinimal() {
    return {
      'pubspec.yaml': _pubspec(),
      'analysis_options.yaml': _analysisOptions(),
      'lib/main.dart': _mainMinimal(),
      'neon.yaml': _neonConfig(),
      '.gitignore': _gitignore(),
    };
  }

  String _pubspec() {
    return '''name: $projectName
description: A Neon Framework application.
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  neon_framework: ^0.1.0
''';
  }

  String _analysisOptions() {
    return '''include: package:neon_framework/analysis_options.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_print: false
''';
  }

  String _mainApp() {
    return '''import 'package:neon_framework/neon.dart';
import 'app.dart';

void main() {
  NeonApp.run(
    MyApp(),
    config: NeonConfig(
      environment: NeonEnvironment.development,
    ),
  );
}
''';
  }

  String _mainMinimal() {
    return '''import 'package:neon_framework/neon.dart';

class MyApp extends StatelessWidget {
  @override
  NeonWidget build(NeonBuildContext context) {
    return Text('Hello, Neon!');
  }
}

void main() {
  NeonApp.run(MyApp());
}
''';
  }

  String _appWidget() {
    return '''import 'package:neon_framework/neon.dart';
import 'screens/home_screen.dart';

class MyApp extends StatelessWidget {
  @override
  NeonWidget build(NeonBuildContext context) {
    return HomeScreen();
  }
}
''';
  }

  String _homeScreen() {
    return '''import 'package:neon_framework/neon.dart';

class HomeScreen extends StatefulWidget {
  @override
  NeonState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends NeonState<HomeScreen> {
  int _counter = 0;

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  @override
  NeonWidget build(NeonBuildContext context) {
    return Column(children: [
      Text(
        'Welcome to Neon!',
        style: NeonTextStyle(fontSize: 24.0),
      ),
      Text(
        'Counter: \$_counter',
        style: NeonTextStyle(fontSize: 18.0),
      ),
      Button(
        label: 'Increment',
        onTap: _increment,
      ),
    ]);
  }
}
''';
  }

  String _neonConfig() {
    return '''name: $projectName
version: 1.0.0

platforms:
  android:
    min_sdk: 21
    target_sdk: 34
    package: com.example.$projectName
  ios:
    min_version: "13.0"
    bundle_id: com.example.$projectName

build:
  output: build/
  obfuscate: false

hot_reload:
  enabled: true
  mode: state_preserving
''';
  }

  String _gitignore() {
    return '''.dart_tool/
.packages
build/
pubspec.lock
*.iml
.idea/
.vscode/
*.log
''';
  }
}

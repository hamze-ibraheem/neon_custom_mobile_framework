import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import 'widget_mapping.dart';

void main(List<String> args) {
  print('╔══════════════════════════════════════╗');
  print('║   Neon Transpiler v1.0               ║');
  print('║   Flutter → Neon Widget Converter    ║');
  print('╚══════════════════════════════════════╝');

  final inputDir = args.isNotEmpty ? args[0] : 'flutter_input';
  final outputDir = args.length > 1 ? args[1] : 'lib/neon_compat';

  final inputPath = Directory(inputDir);
  if (!inputPath.existsSync()) {
    print('');
    print('📂 Input directory "$inputDir" not found.');
    print('   Create it and place Flutter .dart files inside to convert.');
    print('   Usage: dart run tools/transpiler/main.dart [input_dir] [output_dir]');
    print('');
    _generateEmptyBarrel(outputDir);
    print('✅ Empty neon_compat.dart barrel file generated.');
    return;
  }

  final dartFiles = inputPath
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  if (dartFiles.isEmpty) {
    print('⚠️  No .dart files found in "$inputDir".');
    _generateEmptyBarrel(outputDir);
    return;
  }

  print('');
  print('📂 Input:  $inputDir');
  print('📂 Output: $outputDir');
  print('📄 Found ${dartFiles.length} Dart file(s) to transpile');
  print('');

  final outDir = Directory(outputDir);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final convertedFiles = <String>[];
  var totalWidgets = 0;
  var totalReplacements = 0;

  for (final file in dartFiles) {
    final source = file.readAsStringSync();
    final fileName = p.basenameWithoutExtension(file.path);

    if (!_containsFlutterCode(source)) {
      print('⏭️  Skipping ${p.basename(file.path)} (no Flutter imports detected)');
      continue;
    }

    print('🔄 Transpiling ${p.basename(file.path)}...');

    final result = _transpileFile(source, fileName);
    totalWidgets += result.widgetCount;
    totalReplacements += result.replacementCount;

    if (result.warnings.isNotEmpty) {
      for (final w in result.warnings) {
        print('   ⚠️  $w');
      }
    }

    final outFile = File(p.join(outputDir, '${fileName}_neon.dart'));
    outFile.writeAsStringSync(result.output);
    convertedFiles.add('${fileName}_neon.dart');

    print('   ✅ ${result.widgetCount} widget(s), ${result.replacementCount} replacement(s)');
  }

  _generateBarrelFile(outputDir, convertedFiles);

  print('');
  print('═══════════════════════════════════════');
  print('📊 Transpilation Summary');
  print('   Files converted: ${convertedFiles.length}');
  print('   Widgets found:   $totalWidgets');
  print('   Replacements:    $totalReplacements');
  print('   Barrel export:   $outputDir/neon_compat.dart');
  print('═══════════════════════════════════════');
  print('');
  print('✅ Done! Import with:');
  print("   import 'package:neon_app_deploy/neon_compat/neon_compat.dart';");
  print('');
}

bool _containsFlutterCode(String source) {
  return source.contains('package:flutter/') ||
      source.contains('StatelessWidget') ||
      source.contains('StatefulWidget');
}

class TranspileResult {
  final String output;
  final int widgetCount;
  final int replacementCount;
  final List<String> warnings;

  TranspileResult(this.output, this.widgetCount, this.replacementCount, this.warnings);
}

TranspileResult _transpileFile(String source, String fileName) {
  final warnings = <String>[];
  var replacementCount = 0;

  final parseResult = parseString(content: source);
  final unit = parseResult.unit;

  final collector = _AstCollector();
  unit.accept(collector);

  final edits = <_SourceEdit>[];

  for (final imp in collector.flutterImports) {
    final uri = imp.uri.stringValue ?? '';
    final neonImport = flutterToNeonImportMap[uri];
    if (neonImport != null) {
      edits.add(_SourceEdit(imp.offset, imp.end, "import '$neonImport';"));
      replacementCount++;
    } else {
      edits.add(_SourceEdit(imp.offset, imp.end,
          "// TODO(neon): Unsupported Flutter import removed: $uri"));
      warnings.add('Unsupported Flutter import: $uri');
      replacementCount++;
    }
  }

  for (final cls in collector.widgetClasses) {
    final superclass = cls.extendsClause!.superclass;
    final superName = superclass.name2.lexeme;

    if (superName == 'StatelessWidget' || superName == 'StatefulWidget') {
      // already Neon-compatible names
    }

    if (superName == 'State') {
      final typeArgs = superclass.typeArguments;
      if (typeArgs != null) {
        edits.add(_SourceEdit(
          superclass.offset,
          superclass.end,
          'NeonState${typeArgs.toSource()}',
        ));
        replacementCount++;
      }
    }

    for (final member in cls.members) {
      if (member is MethodDeclaration) {
        _processMethod(member, edits, replacementCount, warnings);
      }
      if (member is ConstructorDeclaration) {
        _processConstructor(member, edits, replacementCount);
      }
    }
  }

  for (final method in collector.createStateMethods) {
    final returnType = method.returnType;
    if (returnType != null) {
      final src = returnType.toSource();
      if (src.startsWith('State<')) {
        final mapped = src.replaceFirst('State<', 'NeonState<');
        edits.add(_SourceEdit(returnType.offset, returnType.end, mapped));
        replacementCount++;
      }
    }
  }

  for (final buildMethod in collector.buildMethods) {
    final returnType = buildMethod.returnType;
    if (returnType != null && returnType.toSource() == 'Widget') {
      edits.add(_SourceEdit(returnType.offset, returnType.end, 'NeonWidget'));
      replacementCount++;
    }

    final params = buildMethod.parameters;
    if (params != null) {
      for (final param in params.parameters) {
        final paramSrc = param.toSource();
        if (paramSrc.contains('BuildContext')) {
          final newParam = paramSrc.replaceAll('BuildContext', 'NeonBuildContext');
          edits.add(_SourceEdit(param.offset, param.end, newParam));
          replacementCount++;
        }
      }
    }
  }

  for (final inv in collector.widgetInvocations) {
    final name = inv.name;
    final neonName = flutterToNeonWidgetMap[name];
    if (neonName != null && name != neonName) {
      edits.add(_SourceEdit(inv.offset, inv.offset + name.length, neonName));
      replacementCount++;
    } else if (skipWidgets.contains(name)) {
      warnings.add('Skipped unsupported widget: $name (line ~${_lineOf(source, inv.offset)})');
    }
  }

  for (final ref in collector.typeReferences) {
    final name = ref.name;
    final mapped = flutterToNeonEnumMap[name];
    if (mapped != null && name != mapped) {
      edits.add(_SourceEdit(ref.offset, ref.offset + name.length, mapped));
      replacementCount++;
    }
  }

  for (final keyParam in collector.keyParams) {
    final src = keyParam.toSource();
    if (src.contains('Key?')) {
      final newSrc = src
          .replaceAll('const Key? key', 'String? key')
          .replaceAll('Key? key', 'String? key');
      if (newSrc != src) {
        edits.add(_SourceEdit(keyParam.offset, keyParam.end, newSrc));
        replacementCount++;
      }
    }
  }

  var output = _applyEdits(source, edits);

  output = output.replaceAll(RegExp(r"import\s+'package:flutter/[^']*';\s*\n?"), '');

  final remaining = _findRemainingFlutterTypes(output);
  for (final r in remaining) {
    warnings.add('Remaining Flutter reference: $r');
  }

  final header = '''
// ══════════════════════════════════════════════════════════
// AUTO-GENERATED by Neon Transpiler
// Source: $fileName.dart
// Do not edit manually — re-run the transpiler to update.
// ══════════════════════════════════════════════════════════

''';

  return TranspileResult(
    header + output,
    collector.widgetClasses.length,
    replacementCount,
    warnings,
  );
}

int _lineOf(String source, int offset) {
  return source.substring(0, offset).split('\n').length;
}

void _processMethod(MethodDeclaration method, List<_SourceEdit> edits, int count, List<String> warnings) {
  // handled separately for build methods
}

void _processConstructor(ConstructorDeclaration ctor, List<_SourceEdit> edits, int count) {
  // key param handling done via collector
}

List<String> _findRemainingFlutterTypes(String source) {
  final remaining = <String>[];
  final checks = <String, RegExp>{
    'BuildContext': RegExp(r'\bBuildContext\b'),
    'MaterialApp': RegExp(r'\bMaterialApp\b'),
    'CupertinoApp': RegExp(r'\bCupertinoApp\b'),
    'WidgetsApp': RegExp(r'\bWidgetsApp\b'),
    'ThemeData': RegExp(r'\bThemeData\b'),
    'MediaQuery': RegExp(r'\bMediaQuery\b'),
    'Navigator': RegExp(r'\bNavigator\.'),
    'MaterialPageRoute': RegExp(r'\bMaterialPageRoute\b'),
    'package:flutter': RegExp(r"package:flutter/"),
  };
  for (final entry in checks.entries) {
    if (entry.value.hasMatch(source)) {
      remaining.add(entry.key);
    }
  }
  return remaining;
}

String _applyEdits(String source, List<_SourceEdit> edits) {
  edits.sort((a, b) => b.offset.compareTo(a.offset));

  final seen = <int>{};
  final deduped = <_SourceEdit>[];
  for (final edit in edits) {
    if (!seen.contains(edit.offset)) {
      seen.add(edit.offset);
      deduped.add(edit);
    }
  }

  var result = source;
  for (final edit in deduped) {
    if (edit.offset >= 0 && edit.end <= result.length && edit.offset <= edit.end) {
      result = result.substring(0, edit.offset) + edit.replacement + result.substring(edit.end);
    }
  }
  return result;
}

class _SourceEdit {
  final int offset;
  final int end;
  final String replacement;
  _SourceEdit(this.offset, this.end, this.replacement);
}

class _AstCollector extends RecursiveAstVisitor<void> {
  final flutterImports = <ImportDirective>[];
  final widgetClasses = <ClassDeclaration>[];
  final buildMethods = <MethodDeclaration>[];
  final createStateMethods = <MethodDeclaration>[];
  final widgetInvocations = <_NamedOffset>[];
  final typeReferences = <_NamedOffset>[];
  final keyParams = <FormalParameter>[];

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue ?? '';
    if (uri.startsWith('package:flutter/')) {
      flutterImports.add(node);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause != null) {
      final superName = extendsClause.superclass.name2.lexeme;
      if (superName == 'StatelessWidget' ||
          superName == 'StatefulWidget' ||
          superName == 'State') {
        widgetClasses.add(node);
      }
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final name = node.name.lexeme;
    if (name == 'build') {
      final params = node.parameters;
      if (params != null) {
        final paramStr = params.toSource();
        if (paramStr.contains('BuildContext')) {
          buildMethods.add(node);
        }
      }
    }
    if (name == 'createState') {
      createStateMethods.add(node);
    }
    super.visitMethodDeclaration(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final name = node.constructorName.type.name2.lexeme;
    if (flutterToNeonWidgetMap.containsKey(name) || skipWidgets.contains(name)) {
      widgetInvocations.add(_NamedOffset(name, node.constructorName.type.name2.offset));
    }
    if (flutterToNeonEnumMap.containsKey(name)) {
      typeReferences.add(_NamedOffset(name, node.constructorName.type.name2.offset));
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (target is SimpleIdentifier) {
      final name = target.name;
      if (flutterToNeonEnumMap.containsKey(name)) {
        typeReferences.add(_NamedOffset(name, target.offset));
      }
    }
    final methodName = node.methodName.name;
    if (node.target == null) {
      if (flutterToNeonWidgetMap.containsKey(methodName)) {
        widgetInvocations.add(_NamedOffset(methodName, node.methodName.offset));
      }
      if (flutterToNeonEnumMap.containsKey(methodName)) {
        typeReferences.add(_NamedOffset(methodName, node.methodName.offset));
      }
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    final prefix = node.prefix.name;
    if (flutterToNeonEnumMap.containsKey(prefix)) {
      typeReferences.add(_NamedOffset(prefix, node.prefix.offset));
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitNamedType(NamedType node) {
    final name = node.name2.lexeme;
    if (flutterToNeonEnumMap.containsKey(name)) {
      typeReferences.add(_NamedOffset(name, node.name2.offset));
    }
    super.visitNamedType(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (final param in node.parameters) {
      final src = param.toSource();
      if (src.contains('Key?') || src.contains('Key ')) {
        keyParams.add(param);
      }
    }
    super.visitFormalParameterList(node);
  }
}

class _NamedOffset {
  final String name;
  final int offset;
  _NamedOffset(this.name, this.offset);
}

void _generateBarrelFile(String outputDir, List<String> files) {
  final buffer = StringBuffer();
  buffer.writeln('/// Auto-generated barrel file for Neon-compatible widgets.');
  buffer.writeln('/// Re-run the transpiler to update.');
  buffer.writeln('library neon_compat;');
  buffer.writeln('');
  buffer.writeln("export 'package:neon_framework/neon.dart';");
  buffer.writeln('');

  for (final file in files) {
    buffer.writeln("export '$file';");
  }

  File(p.join(outputDir, 'neon_compat.dart')).writeAsStringSync(buffer.toString());
}

void _generateEmptyBarrel(String outputDir) {
  final outDir = Directory(outputDir);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final buffer = StringBuffer();
  buffer.writeln('/// Auto-generated barrel file for Neon-compatible widgets.');
  buffer.writeln('/// Place Flutter .dart files in flutter_input/ and re-run the transpiler.');
  buffer.writeln('library neon_compat;');
  buffer.writeln('');
  buffer.writeln("export 'package:neon_framework/neon.dart';");

  File(p.join(outputDir, 'neon_compat.dart')).writeAsStringSync(buffer.toString());
}

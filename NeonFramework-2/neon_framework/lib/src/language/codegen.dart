/// Code generator that compiles [NeonProgramNode] AST into Neon Framework Dart source code.
library neon_codegen;

import 'ast.dart';

/// Represents a 1:1 line mapping between `.neon` source code and generated `.dart` code.
class NeonSourceMapEntry {
  const NeonSourceMapEntry({
    required this.neonLine,
    required this.dartLine,
    required this.symbol,
  });

  final int neonLine;
  final int dartLine;
  final String symbol;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'neonLine': neonLine,
        'dartLine': dartLine,
        'symbol': symbol,
      };
}

/// Output of [NeonCodeGenerator.generate].
class NeonCompiledOutput {
  const NeonCompiledOutput({
    required this.dartCode,
    required this.sourceMap,
    required this.routes,
  });

  final String dartCode;
  final List<NeonSourceMapEntry> sourceMap;
  final Map<String, String> routes;
}

/// Compiles a [NeonProgramNode] AST into production Neon Framework Dart code.
class NeonCodeGenerator {
  NeonCodeGenerator();

  static const Map<String, String> _typeMappings = <String, String>{
    'Int': 'int',
    'Double': 'double',
    'Float': 'double',
    'Bool': 'bool',
    'Boolean': 'bool',
    'String': 'String',
  };

  /// Generates valid Neon Dart source code and source maps from [program].
  NeonCompiledOutput generate(NeonProgramNode program) {
    final lines = <String>[];
    final sourceMap = <NeonSourceMapEntry>[];
    final routes = <String, String>{};

    void emit(String line, {int? neonLine, String? symbol}) {
      lines.add(line);
      if (neonLine != null && symbol != null) {
        sourceMap.add(NeonSourceMapEntry(
          neonLine: neonLine,
          dartLine: lines.length,
          symbol: symbol,
        ));
      }
    }

    emit('// GENERATED CODE - COMPILED BY NEONLANG COMPILER (neonc)');
    if (program.moduleName != null) {
      emit('// Module: ${program.moduleName}');
    }
    emit("import 'package:neon_framework/neon.dart';");

    for (final imp in program.imports) {
      final importPath = imp.uri.endsWith('.neon')
          ? imp.uri.replaceAll(RegExp(r'\.neon$'), '.neon.dart')
          : imp.uri;
      emit("import '$importPath';", neonLine: imp.line, symbol: 'import:${imp.uri}');
    }
    emit('');

    for (final comp in program.components) {
      final allStates = <NeonStateFieldNode>[
        ...program.topLevelStates,
        ...comp.states,
      ];

      if (comp.route != null) {
        routes[comp.route!] = comp.name;
      }

      if (allStates.isEmpty) {
        _emitStatelessComponent(comp, emit);
      } else {
        _emitStatefulComponent(comp, allStates, emit);
      }
      emit('');
    }

    return NeonCompiledOutput(
      dartCode: '${lines.join('\n')}\n',
      sourceMap: sourceMap,
      routes: routes,
    );
  }

  void _emitStatelessComponent(
    NeonComponentNode comp,
    void Function(String, {int? neonLine, String? symbol}) emit,
  ) {
    emit(
      'class ${comp.name} extends NeonStatelessWidget {',
      neonLine: comp.line,
      symbol: comp.name,
    );
    emit('  const ${comp.name}({super.key});');
    if (comp.route != null) {
      emit("  static const String routeName = '${comp.route}';");
    }
    emit('');
    emit('  @override');
    emit('  NeonWidget build(NeonBuildContext context) {');
    final bodyExpr = comp.viewChildren.isEmpty
        ? 'const NeonContainer()'
        : _generateWidgetExpr(comp.viewChildren.first, '    ', false);
    emit('    return $bodyExpr;');
    emit('  }');
    emit('}');
  }

  void _emitStatefulComponent(
    NeonComponentNode comp,
    List<NeonStateFieldNode> states,
    void Function(String, {int? neonLine, String? symbol}) emit,
  ) {
    emit(
      'class ${comp.name} extends NeonStatefulWidget {',
      neonLine: comp.line,
      symbol: comp.name,
    );
    emit('  const ${comp.name}({super.key});');
    if (comp.route != null) {
      emit("  static const String routeName = '${comp.route}';");
    }
    emit('');
    emit('  @override');
    emit('  NeonState<${comp.name}> createState() => _${comp.name}State();');
    emit('}');
    emit('');
    emit('class _${comp.name}State extends NeonState<${comp.name}> {');
    for (final st in states) {
      final dartType = _mapType(st.declaredType);
      final prefix = dartType != null ? dartType : 'var';
      emit(
        '  $prefix ${st.name} = ${st.initialValue};',
        neonLine: st.line,
        symbol: '@state:${st.name}',
      );
    }
    emit('');
    emit('  @override');
    emit('  NeonWidget build(NeonBuildContext context) {');
    final bodyExpr = comp.viewChildren.isEmpty
        ? 'const NeonContainer()'
        : _generateWidgetExpr(comp.viewChildren.first, '    ', true);
    emit('    return $bodyExpr;');
    emit('  }');
    emit('}');
  }

  String? _mapType(String? neonType) {
    if (neonType == null || neonType.isEmpty) return null;
    var mapped = neonType;
    _typeMappings.forEach((key, value) {
      mapped = mapped.replaceAll(RegExp('\\b$key\\b'), value);
    });
    return mapped;
  }

  String _generateWidgetExpr(NeonWidgetNode node, String indent, bool isStateful) {
    if (node.isForEach) {
      final childExpr = node.children.isEmpty
          ? 'const NeonContainer()'
          : _generateWidgetExpr(node.children.first, '$indent  ', isStateful);
      return '...${node.iterableExpr}.map((${node.itemVariable}) => $childExpr)';
    }

    if (node.isConditional) {
      final thenExpr = node.children.isEmpty
          ? 'const NeonContainer()'
          : _generateWidgetExpr(node.children.first, '$indent  ', isStateful);
      if (node.elseChildren.isNotEmpty) {
        final elseExpr = _generateWidgetExpr(node.elseChildren.first, '$indent  ', isStateful);
        return '(${node.conditionExpr}) ? $thenExpr : $elseExpr';
      }
      return 'if (${node.conditionExpr}) $thenExpr';
    }

    var expr = _generateCoreWidget(node, indent, isStateful);

    // Apply chained modifiers such as .padding(16.dp)
    for (final mod in node.modifiers) {
      if (mod.name == 'padding' && mod.args.isNotEmpty) {
        final padVal = mod.args.first.value;
        expr = 'NeonPadding(padding: const NeonEdgeInsets.all($padVal), child: $expr)';
      }
    }

    return expr;
  }

  String _generateCoreWidget(NeonWidgetNode node, String indent, bool isStateful) {
    switch (node.widgetName) {
      case 'Scaffold':
        final titleArg = _findArg(node.args, 'title') ?? (node.args.isNotEmpty ? node.args.first.value : null);
        final bodyChild = node.children.isEmpty
            ? 'const NeonContainer()'
            : _generateWidgetExpr(node.children.first, '$indent  ', isStateful);
        final appBarPart = titleArg != null ? 'appBar: NeonAppBar(title: $titleArg), ' : '';
        return 'NeonScaffold(${appBarPart}body: $bodyChild)';

      case 'Column':
      case 'Row':
        final isRow = node.widgetName == 'Row';
        final className = isRow ? 'NeonRow' : 'NeonColumn';
        final gapArg = _findArg(node.args, 'gap') ?? _findArg(node.args, 'spacing');
        final padArg = _findArg(node.args, 'padding');
        final alignArg = _findArgObj(node.args, 'align');
        final parts = <String>[];
        if (gapArg != null) {
          parts.add('spacing: $gapArg');
        }
        if (alignArg != null) {
          parts.add('mainAxisAlignment: NeonMainAxisAlignment.${alignArg.value}');
        }
        final childExprs = node.children
            .map((c) => _generateWidgetExpr(c, '$indent  ', isStateful))
            .join(', ');
        parts.add('children: <NeonWidget>[$childExprs]');
        final colRow = '$className(${parts.join(', ')})';
        if (padArg != null) {
          return 'NeonPadding(padding: const NeonEdgeInsets.all($padArg), child: $colRow)';
        }
        return colRow;

      case 'Text':
        final textVal = node.args.isNotEmpty ? node.args.first.value : "''";
        final styleParts = <String>[];
        for (final mod in node.modifiers) {
          if (mod.name == 'font') {
            final size = _findArg(mod.args, 'size');
            final weight = _findArgObj(mod.args, 'weight');
            if (size != null) styleParts.add('fontSize: $size');
            if (weight != null) styleParts.add('fontWeight: NeonFontWeight.${weight.value}');
          } else if (mod.name == 'color' && mod.args.isNotEmpty) {
            styleParts.add('color: ${_resolveColor(mod.args.first)}');
          }
        }
        if (styleParts.isNotEmpty) {
          return 'NeonText($textVal, style: NeonTextStyle(${styleParts.join(', ')}))';
        }
        return 'NeonText($textVal)';

      case 'Card':
        final elev = _findArg(node.args, 'elevation');
        final childExpr = node.children.isEmpty
            ? 'const NeonContainer()'
            : _generateWidgetExpr(node.children.first, '$indent  ', isStateful);
        final elevPart = elev != null ? 'elevation: $elev, ' : '';
        return 'NeonCard(${elevPart}child: $childExpr)';

      case 'Badge':
        final label = node.args.isNotEmpty ? node.args.first.value : "''";
        return 'NeonBadge(label: $label)';

      case 'Button':
      case 'FilledButton':
      case 'OutlinedButton':
        final label = node.args.isNotEmpty ? node.args.first.value : "'Button'";
        String onPressedCode = '() {}';
        if (node.actionStatements.isNotEmpty) {
          final stmts = node.actionStatements.join('; ');
          onPressedCode = isStateful
              ? '() => setState(() { $stmts; })'
              : '() { $stmts; }';
        }
        return 'NeonButton(label: $label, onPressed: $onPressedCode)';

      default:
        final neonClass = node.widgetName.startsWith('Neon')
            ? node.widgetName
            : 'Neon${node.widgetName}';
        if (node.children.isNotEmpty) {
          final childExpr = _generateWidgetExpr(node.children.first, '$indent  ', isStateful);
          return '$neonClass(child: $childExpr)';
        }
        return 'const $neonClass()';
    }
  }

  String? _findArg(List<NeonPropertyArg> args, String name) {
    for (final a in args) {
      if (a.name == name) return a.value;
    }
    return null;
  }

  NeonPropertyArg? _findArgObj(List<NeonPropertyArg> args, String name) {
    for (final a in args) {
      if (a.name == name) return a;
    }
    return null;
  }

  String _resolveColor(NeonPropertyArg arg) {
    if (arg.isHexColor) {
      final clean = arg.value.replaceFirst('#', '');
      final hex = clean.length == 6 ? 'FF$clean' : clean;
      return 'const NeonColor(0x${hex.toUpperCase()})';
    }
    if (arg.isEnumShorthand) {
      return 'NeonColor.${arg.value}';
    }
    return arg.value;
  }
}


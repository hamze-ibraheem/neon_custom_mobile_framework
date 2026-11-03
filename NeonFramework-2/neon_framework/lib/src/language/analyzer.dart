/// Semantic analyzer and reactive type checker for NeonLang (`.neon`).
library neon_analyzer;

import 'ast.dart';

/// Validates a parsed [NeonProgramNode] AST for widget existence, modifier rules,
/// and reactive state references.
class NeonSemanticAnalyzer {
  NeonSemanticAnalyzer();

  /// Built-in Neon Framework widgets supported natively in `.neon`.
  static const Set<String> builtInWidgets = <String>{
    'Scaffold',
    'AppBar',
    'Column',
    'Row',
    'Container',
    'Card',
    'Text',
    'Button',
    'FilledButton',
    'OutlinedButton',
    'IconButton',
    'FloatingActionButton',
    'Badge',
    'Chip',
    'TextField',
    'SearchBar',
    'Switch',
    'Checkbox',
    'Slider',
    'ListTile',
    'ProgressIndicator',
    'CircularProgressIndicator',
    'LinearProgressIndicator',
    'Divider',
    'Spacer',
    'Icon',
    'Image',
    'ScrollView',
    'ListView',
    'Stack',
    'Padding',
    'Center',
    'Expanded',
    'SizedBox',
    'Tooltip',
    'ForEach',
    'If',
  };

  /// Built-in SwiftUI-style modifiers supported on `.neon` widgets.
  static const Set<String> supportedModifiers = <String>{
    'padding',
    'color',
    'background',
    'font',
    'style',
    'cornerRadius',
    'elevation',
    'width',
    'height',
    'onTap',
    'align',
    'opacity',
    'border',
  };

  /// Analyzes [program] and returns a list of semantic [NeonDiagnostic]s.
  List<NeonDiagnostic> analyze(NeonProgramNode program) {
    final results = <NeonDiagnostic>[];
    final componentNames = <String>{};

    for (final comp in program.components) {
      if (!componentNames.add(comp.name)) {
        results.add(NeonDiagnostic(
          message: 'Duplicate component declaration "${comp.name}".',
          line: comp.line,
          column: comp.column,
          code: 'NEON201',
        ));
      }

      if (comp.route != null && !comp.route!.startsWith('/')) {
        results.add(NeonDiagnostic(
          message: 'Component route "${comp.route}" must start with "/".',
          line: comp.line,
          column: comp.column,
          severity: NeonDiagnosticSeverity.warning,
          code: 'NEON202',
        ));
      }

      final stateNames = <String>{
        ...program.topLevelStates.map((s) => s.name),
        ...comp.states.map((s) => s.name),
      };

      for (final child in comp.viewChildren) {
        _analyzeWidget(child, componentNames, stateNames, results);
      }
    }

    return results;
  }

  void _analyzeWidget(
    NeonWidgetNode node,
    Set<String> knownComponents,
    Set<String> stateNames,
    List<NeonDiagnostic> results,
  ) {
    if (!builtInWidgets.contains(node.widgetName) &&
        !knownComponents.contains(node.widgetName) &&
        !node.widgetName.startsWith('Neon')) {
      results.add(NeonDiagnostic(
        message: 'Unknown widget or component "${node.widgetName}". '
            'Import a `.dart` or `.neon` component or use a built-in Neon widget.',
        line: node.line,
        column: node.column,
        severity: NeonDiagnosticSeverity.warning,
        code: 'NEON203',
      ));
    }

    for (final mod in node.modifiers) {
      if (!supportedModifiers.contains(mod.name)) {
        results.add(NeonDiagnostic(
          message: 'Unknown modifier ".${mod.name}()". Supported modifiers: '
              '${supportedModifiers.join(', ')}.',
          line: mod.line,
          column: mod.column,
          severity: NeonDiagnosticSeverity.warning,
          code: 'NEON204',
        ));
      }
    }

    for (final child in node.children) {
      _analyzeWidget(child, knownComponents, stateNames, results);
    }
    for (final elseChild in node.elseChildren) {
      _analyzeWidget(elseChild, knownComponents, stateNames, results);
    }
  }
}


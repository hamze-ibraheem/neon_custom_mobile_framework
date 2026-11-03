/// Abstract Syntax Tree (AST) nodes for the NeonLang (`.neon`) compiler.
library neon_ast;

/// Severity of a compiler or LSP diagnostic.
enum NeonDiagnosticSeverity {
  error,
  warning,
  info,
}

/// Represents a syntax or semantic diagnostic at a specific source location.
class NeonDiagnostic {
  const NeonDiagnostic({
    required this.message,
    required this.line,
    required this.column,
    this.severity = NeonDiagnosticSeverity.error,
    this.code = 'NEON001',
  });

  final String message;
  final int line;
  final int column;
  final NeonDiagnosticSeverity severity;
  final String code;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'severity': severity.name,
        'message': message,
        'line': line,
        'column': column,
      };

  @override
  String toString() => '[$code:${severity.name.toUpperCase()}] Line $line:$column - $message';
}

/// Root AST node representing a parsed `.neon` file.
class NeonProgramNode {
  const NeonProgramNode({
    required this.moduleName,
    required this.imports,
    required this.topLevelStates,
    required this.components,
  });

  final String? moduleName;
  final List<NeonImportNode> imports;
  final List<NeonStateFieldNode> topLevelStates;
  final List<NeonComponentNode> components;
}

/// Represents an `import` statement (can import either `.neon` or `.dart` files/packages).
class NeonImportNode {
  const NeonImportNode({
    required this.uri,
    required this.line,
    required this.column,
  });

  final String uri;
  final int line;
  final int column;

  bool get isDartImport => uri.endsWith('.dart') || uri.startsWith('package:') || uri.startsWith('dart:');
}

/// Reactive state annotation kind (`@state`, `@computed`, `@persist`).
enum NeonStateKind {
  state,
  computed,
  persist,
}

/// Represents a reactive state variable declaration.
class NeonStateFieldNode {
  const NeonStateFieldNode({
    required this.name,
    required this.kind,
    required this.initialValue,
    required this.line,
    required this.column,
    this.declaredType,
  });

  final String name;
  final NeonStateKind kind;
  final String? declaredType;
  final String initialValue;
  final int line;
  final int column;
}

/// Represents a declarative `component` declaration in `.neon`.
class NeonComponentNode {
  const NeonComponentNode({
    required this.name,
    required this.states,
    required this.viewChildren,
    required this.line,
    required this.column,
    this.route,
  });

  final String name;
  final String? route;
  final List<NeonStateFieldNode> states;
  final List<NeonWidgetNode> viewChildren;
  final int line;
  final int column;
}

/// Represents a named or positional argument passed to a widget or modifier.
class NeonPropertyArg {
  const NeonPropertyArg({
    required this.value,
    this.name,
    this.isHexColor = false,
    this.isEnumShorthand = false,
    this.unitSuffix,
  });

  final String? name;
  final String value;
  final bool isHexColor;
  final bool isEnumShorthand;
  final String? unitSuffix;
}

/// Represents a SwiftUI-style modifier chained onto a widget (e.g., `.padding(16.dp)`).
class NeonModifierNode {
  const NeonModifierNode({
    required this.name,
    required this.args,
    required this.line,
    required this.column,
  });

  final String name;
  final List<NeonPropertyArg> args;
  final int line;
  final int column;
}

/// Represents a UI widget, `ForEach` loop, or `If` conditional node in the `.neon` view tree.
class NeonWidgetNode {
  const NeonWidgetNode({
    required this.widgetName,
    required this.args,
    required this.children,
    required this.modifiers,
    required this.line,
    required this.column,
    this.actionStatements = const <String>[],
    this.isForEach = false,
    this.iterableExpr,
    this.itemVariable,
    this.isConditional = false,
    this.conditionExpr,
    this.elseChildren = const <NeonWidgetNode>[],
  });

  final String widgetName;
  final List<NeonPropertyArg> args;
  final List<NeonWidgetNode> children;
  final List<NeonModifierNode> modifiers;
  final List<String> actionStatements;
  final int line;
  final int column;

  // ForEach metadata
  final bool isForEach;
  final String? iterableExpr;
  final String? itemVariable;

  // If/Else metadata
  final bool isConditional;
  final String? conditionExpr;
  final List<NeonWidgetNode> elseChildren;
}


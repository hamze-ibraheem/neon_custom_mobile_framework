/// Recursive-descent parser for the NeonLang (`.neon`) declarative language.
library neon_parser;

import 'ast.dart';
import 'lexer.dart';

/// Parses a list of [NeonToken]s into a [NeonProgramNode] AST.
class NeonParser {
  NeonParser(this.tokens);

  final List<NeonToken> tokens;
  final List<NeonDiagnostic> diagnostics = <NeonDiagnostic>[];
  int _current = 0;

  /// Parses the token stream and returns the root [NeonProgramNode].
  NeonProgramNode parse() {
    String? moduleName;
    final imports = <NeonImportNode>[];
    final topLevelStates = <NeonStateFieldNode>[];
    final components = <NeonComponentNode>[];

    while (!_isAtEnd) {
      if (_match(NeonTokenType.keywordModule)) {
        moduleName = _parseQualifiedIdentifier();
      } else if (_match(NeonTokenType.keywordImport)) {
        imports.add(_parseImport());
      } else if (_checkAnnotation()) {
        topLevelStates.add(_parseStateDecl());
      } else if (_match(NeonTokenType.keywordComponent)) {
        components.add(_parseComponent());
      } else {
        final unexpected = _advance();
        diagnostics.add(NeonDiagnostic(
          message: 'Unexpected token "${unexpected.lexeme}" at top level.',
          line: unexpected.line,
          column: unexpected.column,
          code: 'NEON100',
        ));
      }
    }

    return NeonProgramNode(
      moduleName: moduleName,
      imports: imports,
      topLevelStates: topLevelStates,
      components: components,
    );
  }

  String _parseQualifiedIdentifier() {
    final buffer = StringBuffer();
    if (_check(NeonTokenType.identifier)) {
      buffer.write(_advance().lexeme);
      while (_match(NeonTokenType.dot)) {
        buffer.write('.');
        if (_check(NeonTokenType.identifier)) {
          buffer.write(_advance().lexeme);
        }
      }
    }
    return buffer.toString();
  }

  NeonImportNode _parseImport() {
    final token = _peek();
    if (_match(NeonTokenType.stringLiteral)) {
      return NeonImportNode(
        uri: token.lexeme,
        line: token.line,
        column: token.column,
      );
    }
    final qualified = _parseQualifiedIdentifier();
    return NeonImportNode(
      uri: qualified,
      line: token.line,
      column: token.column,
    );
  }

  bool _checkAnnotation() =>
      _check(NeonTokenType.annotationState) ||
      _check(NeonTokenType.annotationComputed) ||
      _check(NeonTokenType.annotationPersist);

  NeonStateFieldNode _parseStateDecl() {
    final annToken = _advance();
    final kind = annToken.type == NeonTokenType.annotationComputed
        ? NeonStateKind.computed
        : annToken.type == NeonTokenType.annotationPersist
            ? NeonStateKind.persist
            : NeonStateKind.state;

    final nameToken = _consumeIdentifier('Expected state variable name.');
    String? declaredType;
    if (_match(NeonTokenType.colon)) {
      declaredType = _parseTypeRef();
    }

    var initialValue = 'null';
    if (_match(NeonTokenType.equals)) {
      initialValue = _parseExpressionString();
    }

    return NeonStateFieldNode(
      name: nameToken.lexeme,
      kind: kind,
      declaredType: declaredType,
      initialValue: initialValue,
      line: annToken.line,
      column: annToken.column,
    );
  }

  String _parseTypeRef() {
    final buf = StringBuffer();
    if (_check(NeonTokenType.identifier)) {
      buf.write(_advance().lexeme);
      if (_peek().lexeme == '<') {
        buf.write(_advance().lexeme); // '<'
        while (!_isAtEnd && _peek().lexeme != '>') {
          buf.write(_advance().lexeme);
        }
        if (!_isAtEnd && _peek().lexeme == '>') {
          buf.write(_advance().lexeme);
        }
      }
    }
    return buf.toString();
  }

  NeonComponentNode _parseComponent() {
    final nameToken = _consumeIdentifier('Expected component name after "component".');
    _consume(NeonTokenType.lBrace, 'Expected "{" after component name.');

    String? route;
    final states = <NeonStateFieldNode>[];
    final viewChildren = <NeonWidgetNode>[];

    while (!_isAtEnd && !_check(NeonTokenType.rBrace)) {
      if (_match(NeonTokenType.keywordRoute)) {
        _consume(NeonTokenType.colon, 'Expected ":" after route.');
        if (_check(NeonTokenType.stringLiteral)) {
          route = _advance().lexeme;
        }
      } else if (_checkAnnotation()) {
        states.add(_parseStateDecl());
      } else if (_match(NeonTokenType.keywordView)) {
        _consume(NeonTokenType.lBrace, 'Expected "{" after view.');
        while (!_isAtEnd && !_check(NeonTokenType.rBrace)) {
          viewChildren.add(_parseWidgetNode());
        }
        _consume(NeonTokenType.rBrace, 'Expected "}" after view block.');
      } else {
        // Allow direct widgets inside component if `view` wrapper omitted
        viewChildren.add(_parseWidgetNode());
      }
    }

    _consume(NeonTokenType.rBrace, 'Expected "}" at end of component.');

    return NeonComponentNode(
      name: nameToken.lexeme,
      route: route,
      states: states,
      viewChildren: viewChildren,
      line: nameToken.line,
      column: nameToken.column,
    );
  }

  NeonWidgetNode _parseWidgetNode() {
    if (_match(NeonTokenType.keywordForEach)) {
      return _parseForEachNode();
    }
    if (_match(NeonTokenType.keywordIf)) {
      return _parseIfNode();
    }

    final widgetToken = _consumeIdentifier('Expected widget name.');
    final args = <NeonPropertyArg>[];

    if (_match(NeonTokenType.lParen)) {
      if (!_check(NeonTokenType.rParen)) {
        args.addAll(_parseArgList());
      }
      _consume(NeonTokenType.rParen, 'Expected ")" after widget arguments.');
    }

    final children = <NeonWidgetNode>[];
    final actionStatements = <String>[];

    if (_match(NeonTokenType.lBrace)) {
      final isActionWidget = widgetToken.lexeme == 'Button' ||
          widgetToken.lexeme == 'FilledButton' ||
          widgetToken.lexeme == 'OutlinedButton' ||
          widgetToken.lexeme == 'IconButton';

      while (!_isAtEnd && !_check(NeonTokenType.rBrace)) {
        if (isActionWidget && _looksLikeActionStatement()) {
          actionStatements.add(_parseStatementString());
        } else {
          children.add(_parseWidgetNode());
        }
      }
      _consume(NeonTokenType.rBrace, 'Expected "}" after widget block.');
    }

    final modifiers = <NeonModifierNode>[];
    while (_match(NeonTokenType.dot)) {
      final modName = _consumeIdentifier('Expected modifier name after ".".');
      final modArgs = <NeonPropertyArg>[];
      if (_match(NeonTokenType.lParen)) {
        if (!_check(NeonTokenType.rParen)) {
          modArgs.addAll(_parseArgList());
        }
        _consume(NeonTokenType.rParen, 'Expected ")" after modifier arguments.');
      }
      modifiers.add(NeonModifierNode(
        name: modName.lexeme,
        args: modArgs,
        line: modName.line,
        column: modName.column,
      ));
    }

    return NeonWidgetNode(
      widgetName: widgetToken.lexeme,
      args: args,
      children: children,
      modifiers: modifiers,
      actionStatements: actionStatements,
      line: widgetToken.line,
      column: widgetToken.column,
    );
  }

  NeonWidgetNode _parseForEachNode() {
    final startToken = _previous();
    _consume(NeonTokenType.lParen, 'Expected "(" after ForEach.');
    final iterableToken = _consumeIdentifier('Expected iterable collection name in ForEach.');
    _consume(NeonTokenType.rParen, 'Expected ")" after ForEach iterable.');
    _consume(NeonTokenType.arrow, 'Expected "->" after ForEach(...).');
    final itemVarToken = _consumeIdentifier('Expected loop variable name after "->".');
    _consume(NeonTokenType.lBrace, 'Expected "{" to open ForEach body.');

    final children = <NeonWidgetNode>[];
    while (!_isAtEnd && !_check(NeonTokenType.rBrace)) {
      children.add(_parseWidgetNode());
    }
    _consume(NeonTokenType.rBrace, 'Expected "}" after ForEach body.');

    return NeonWidgetNode(
      widgetName: 'ForEach',
      args: const <NeonPropertyArg>[],
      children: children,
      modifiers: const <NeonModifierNode>[],
      line: startToken.line,
      column: startToken.column,
      isForEach: true,
      iterableExpr: iterableToken.lexeme,
      itemVariable: itemVarToken.lexeme,
    );
  }

  NeonWidgetNode _parseIfNode() {
    final startToken = _previous();
    _consume(NeonTokenType.lParen, 'Expected "(" after If.');
    final condBuffer = StringBuffer();
    while (!_isAtEnd && !_check(NeonTokenType.rParen)) {
      condBuffer.write(_advance().lexeme);
    }
    _consume(NeonTokenType.rParen, 'Expected ")" after If condition.');
    _consume(NeonTokenType.lBrace, 'Expected "{" after If condition.');

    final thenChildren = <NeonWidgetNode>[];
    while (!_isAtEnd && !_check(NeonTokenType.rBrace)) {
      thenChildren.add(_parseWidgetNode());
    }
    _consume(NeonTokenType.rBrace, 'Expected "}" after If block.');

    final elseChildren = <NeonWidgetNode>[];
    if (_match(NeonTokenType.keywordElse)) {
      _consume(NeonTokenType.lBrace, 'Expected "{" after Else.');
      while (!_isAtEnd && !_check(NeonTokenType.rBrace)) {
        elseChildren.add(_parseWidgetNode());
      }
      _consume(NeonTokenType.rBrace, 'Expected "}" after Else block.');
    }

    return NeonWidgetNode(
      widgetName: 'If',
      args: const <NeonPropertyArg>[],
      children: thenChildren,
      elseChildren: elseChildren,
      modifiers: const <NeonModifierNode>[],
      line: startToken.line,
      column: startToken.column,
      isConditional: true,
      conditionExpr: condBuffer.toString().trim(),
    );
  }

  List<NeonPropertyArg> _parseArgList() {
    final list = <NeonPropertyArg>[];
    do {
      if (_check(NeonTokenType.rParen)) break;
      String? argName;
      if (_check(NeonTokenType.identifier) && _peekNext().type == NeonTokenType.colon) {
        argName = _advance().lexeme;
        _advance(); // ':'
      }
      list.add(_parsePropertyArg(argName));
    } while (_match(NeonTokenType.comma));
    return list;
  }

  NeonPropertyArg _parsePropertyArg(String? name) {
    final tok = _peek();
    if (_match(NeonTokenType.hexColorLiteral)) {
      return NeonPropertyArg(
        name: name,
        value: tok.lexeme,
        isHexColor: true,
      );
    }
    if (_match(NeonTokenType.enumShorthand)) {
      return NeonPropertyArg(
        name: name,
        value: tok.lexeme,
        isEnumShorthand: true,
      );
    }
    if (_match(NeonTokenType.unitLiteral)) {
      return NeonPropertyArg(
        name: name,
        value: tok.lexeme,
        unitSuffix: tok.unitSuffix,
      );
    }
    if (_match(NeonTokenType.stringLiteral)) {
      return NeonPropertyArg(
        name: name,
        value: "'${tok.lexeme}'",
      );
    }
    final expr = _parseExpressionString();
    return NeonPropertyArg(
      name: name,
      value: expr,
    );
  }

  String _parseExpressionString() {
    if (_match(NeonTokenType.lBracket)) {
      final items = <String>[];
      while (!_isAtEnd && !_check(NeonTokenType.rBracket)) {
        if (_match(NeonTokenType.stringLiteral)) {
          items.add("'${_previous().lexeme}'");
        } else if (!_match(NeonTokenType.comma)) {
          items.add(_advance().lexeme);
        }
      }
      _consume(NeonTokenType.rBracket, 'Expected "]" at end of list literal.');
      return '[${items.join(', ')}]';
    }
    if (_match(NeonTokenType.stringLiteral)) {
      return "'${_previous().lexeme}'";
    }
    if (_match(NeonTokenType.numberLiteral) ||
        _match(NeonTokenType.booleanLiteral) ||
        _match(NeonTokenType.hexColorLiteral) ||
        _match(NeonTokenType.unitLiteral)) {
      return _previous().lexeme;
    }
    if (_match(NeonTokenType.identifier)) {
      final buf = StringBuffer(_previous().lexeme);
      while (_match(NeonTokenType.dot) && _check(NeonTokenType.identifier)) {
        buf.write('.${_advance().lexeme}');
      }
      if (_match(NeonTokenType.lParen)) {
        buf.write('(');
        while (!_isAtEnd && !_check(NeonTokenType.rParen)) {
          final t = _advance();
          buf.write(t.type == NeonTokenType.stringLiteral ? "'${t.lexeme}'" : t.lexeme);
        }
        if (_match(NeonTokenType.rParen)) {
          buf.write(')');
        }
      }
      return buf.toString();
    }
    return _isAtEnd ? '' : _advance().lexeme;
  }

  bool _looksLikeActionStatement() {
    if (!_check(NeonTokenType.identifier)) return false;
    final next = _peekNext().type;
    return next == NeonTokenType.plusEquals ||
        next == NeonTokenType.minusEquals ||
        next == NeonTokenType.equals ||
        next == NeonTokenType.dot ||
        next == NeonTokenType.lParen;
  }

  String _parseStatementString() {
    final buf = StringBuffer();
    final startLine = _peek().line;
    while (!_isAtEnd && !_check(NeonTokenType.rBrace) && _peek().line == startLine) {
      final tok = _advance();
      if (tok.type == NeonTokenType.stringLiteral) {
        buf.write("'${tok.lexeme}'");
      } else if (tok.type == NeonTokenType.plusEquals ||
          tok.type == NeonTokenType.minusEquals ||
          tok.type == NeonTokenType.equals) {
        buf.write(' ${tok.lexeme} ');
      } else {
        buf.write(tok.lexeme);
      }
    }
    return buf.toString().trim();
  }

  NeonToken _consumeIdentifier(String errorMessage) {
    if (_check(NeonTokenType.identifier)) {
      return _advance();
    }
    final tok = _peek();
    diagnostics.add(NeonDiagnostic(
      message: errorMessage,
      line: tok.line,
      column: tok.column,
      code: 'NEON101',
    ));
    if (!_isAtEnd) _advance();
    return NeonToken(
      type: NeonTokenType.identifier,
      lexeme: 'UnknownId',
      line: tok.line,
      column: tok.column,
    );
  }

  void _consume(NeonTokenType expected, String errorMessage) {
    if (_check(expected)) {
      _advance();
      return;
    }
    final tok = _peek();
    diagnostics.add(NeonDiagnostic(
      message: errorMessage,
      line: tok.line,
      column: tok.column,
      code: 'NEON102',
    ));
  }

  bool _match(NeonTokenType type) {
    if (_check(type)) {
      _advance();
      return true;
    }
    return false;
  }

  bool _check(NeonTokenType type) => !_isAtEnd && _peek().type == type;

  NeonToken _advance() {
    if (!_isAtEnd) _current++;
    return _previous();
  }

  bool get _isAtEnd => _peek().type == NeonTokenType.eof;

  NeonToken _peek() => tokens[_current];

  NeonToken _peekNext() =>
      (_current + 1 < tokens.length) ? tokens[_current + 1] : tokens.last;

  NeonToken _previous() => tokens[_current - 1];
}


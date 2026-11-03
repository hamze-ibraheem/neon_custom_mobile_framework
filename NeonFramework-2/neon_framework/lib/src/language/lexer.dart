/// Lexer and tokenizer for the NeonLang (`.neon`) declarative language.
library neon_lexer;

/// Token categories recognized by [NeonLexer].
enum NeonTokenType {
  keywordModule,
  keywordImport,
  keywordComponent,
  keywordRoute,
  keywordView,
  keywordForEach,
  keywordIf,
  keywordElse,
  annotationState,
  annotationComputed,
  annotationPersist,
  identifier,
  stringLiteral,
  numberLiteral,
  unitLiteral,
  hexColorLiteral,
  enumShorthand,
  booleanLiteral,
  lParen,
  rParen,
  lBrace,
  rBrace,
  lBracket,
  rBracket,
  colon,
  comma,
  dot,
  equals,
  plusEquals,
  minusEquals,
  arrow,
  operatorSymbol,
  eof,
}

/// Represents a lexical token in a `.neon` source file with 1-based line/column coordinates.
class NeonToken {
  const NeonToken({
    required this.type,
    required this.lexeme,
    required this.line,
    required this.column,
    this.unitSuffix,
  });

  final NeonTokenType type;
  final String lexeme;
  final int line;
  final int column;
  final String? unitSuffix;

  @override
  String toString() => 'NeonToken($type, "$lexeme", $line:$column)';
}

/// Tokenizes `.neon` source code into a stream of [NeonToken]s.
class NeonLexer {
  NeonLexer(this.source);

  final String source;
  int _pos = 0;
  int _line = 1;
  int _column = 1;

  static const Map<String, NeonTokenType> _keywords = <String, NeonTokenType>{
    'module': NeonTokenType.keywordModule,
    'import': NeonTokenType.keywordImport,
    'component': NeonTokenType.keywordComponent,
    'route': NeonTokenType.keywordRoute,
    'view': NeonTokenType.keywordView,
    'ForEach': NeonTokenType.keywordForEach,
    'If': NeonTokenType.keywordIf,
    'Else': NeonTokenType.keywordElse,
    'true': NeonTokenType.booleanLiteral,
    'false': NeonTokenType.booleanLiteral,
  };

  /// Scans the entire [source] string and returns all tokens ending with [NeonTokenType.eof].
  List<NeonToken> tokenize() {
    final tokens = <NeonToken>[];

    while (!_isAtEnd) {
      _skipWhitespaceAndComments();
      if (_isAtEnd) break;

      final startLine = _line;
      final startCol = _column;
      final ch = _peek();

      if (ch == '@') {
        tokens.add(_readAnnotation(startLine, startCol));
      } else if (ch == '#') {
        tokens.add(_readHexColor(startLine, startCol));
      } else if (ch == '"' || ch == "'") {
        tokens.add(_readString(startLine, startCol));
      } else if (_isDigit(ch)) {
        tokens.add(_readNumberOrUnit(startLine, startCol));
      } else if (ch == '.' && _isAlpha(_peekNext())) {
        // Check if this is a modifier call after `)` or `}` or identifier vs enum shorthand
        final prev = tokens.isNotEmpty ? tokens.last.type : null;
        final isModifierTarget = prev == NeonTokenType.rParen ||
            prev == NeonTokenType.rBrace ||
            prev == NeonTokenType.identifier ||
            prev == NeonTokenType.stringLiteral;
        if (isModifierTarget) {
          _advance();
          tokens.add(NeonToken(
            type: NeonTokenType.dot,
            lexeme: '.',
            line: startLine,
            column: startCol,
          ));
        } else {
          tokens.add(_readEnumShorthand(startLine, startCol));
        }
      } else if (_isAlpha(ch) || ch == '_') {
        tokens.add(_readIdentifierOrKeyword(startLine, startCol));
      } else {
        tokens.add(_readPunctuation(startLine, startCol));
      }
    }

    tokens.add(NeonToken(
      type: NeonTokenType.eof,
      lexeme: '',
      line: _line,
      column: _column,
    ));
    return tokens;
  }

  NeonToken _readAnnotation(int startLine, int startCol) {
    final buffer = StringBuffer()..write(_advance()); // '@'
    while (!_isAtEnd && (_isAlphaNumeric(_peek()) || _peek() == '_')) {
      buffer.write(_advance());
    }
    final text = buffer.toString();
    switch (text) {
      case '@state':
        return NeonToken(
          type: NeonTokenType.annotationState,
          lexeme: text,
          line: startLine,
          column: startCol,
        );
      case '@computed':
        return NeonToken(
          type: NeonTokenType.annotationComputed,
          lexeme: text,
          line: startLine,
          column: startCol,
        );
      case '@persist':
        return NeonToken(
          type: NeonTokenType.annotationPersist,
          lexeme: text,
          line: startLine,
          column: startCol,
        );
      default:
        return NeonToken(
          type: NeonTokenType.annotationState,
          lexeme: text,
          line: startLine,
          column: startCol,
        );
    }
  }

  NeonToken _readHexColor(int startLine, int startCol) {
    final buffer = StringBuffer()..write(_advance()); // '#'
    while (!_isAtEnd && _isHexDigit(_peek())) {
      buffer.write(_advance());
    }
    return NeonToken(
      type: NeonTokenType.hexColorLiteral,
      lexeme: buffer.toString(),
      line: startLine,
      column: startCol,
    );
  }

  NeonToken _readString(int startLine, int startCol) {
    final quote = _advance();
    final buffer = StringBuffer();
    while (!_isAtEnd && _peek() != quote) {
      if (_peek() == r'\' && _pos + 1 < source.length) {
        _advance();
      }
      buffer.write(_advance());
    }
    if (!_isAtEnd && _peek() == quote) {
      _advance();
    }
    return NeonToken(
      type: NeonTokenType.stringLiteral,
      lexeme: buffer.toString(),
      line: startLine,
      column: startCol,
    );
  }

  NeonToken _readNumberOrUnit(int startLine, int startCol) {
    final buffer = StringBuffer();
    while (!_isAtEnd && _isDigit(_peek())) {
      buffer.write(_advance());
    }
    if (!_isAtEnd && _peek() == '.' && _isDigit(_peekNext())) {
      buffer.write(_advance());
      while (!_isAtEnd && _isDigit(_peek())) {
        buffer.write(_advance());
      }
    }
    // Check unit suffix like .dp, .sp, .ms, .px
    if (!_isAtEnd && _peek() == '.' && _isAlpha(_peekNext())) {
      final savedPos = _pos;
      final savedCol = _column;
      _advance(); // '.'
      final unitBuf = StringBuffer();
      while (!_isAtEnd && _isAlpha(_peek())) {
        unitBuf.write(_advance());
      }
      final unit = unitBuf.toString();
      if (unit == 'dp' || unit == 'sp' || unit == 'ms' || unit == 'px') {
        return NeonToken(
          type: NeonTokenType.unitLiteral,
          lexeme: buffer.toString(),
          line: startLine,
          column: startCol,
          unitSuffix: unit,
        );
      } else {
        _pos = savedPos;
        _column = savedCol;
      }
    }

    return NeonToken(
      type: NeonTokenType.numberLiteral,
      lexeme: buffer.toString(),
      line: startLine,
      column: startCol,
    );
  }

  NeonToken _readEnumShorthand(int startLine, int startCol) {
    _advance(); // '.'
    final buffer = StringBuffer();
    while (!_isAtEnd && (_isAlphaNumeric(_peek()) || _peek() == '_')) {
      buffer.write(_advance());
    }
    return NeonToken(
      type: NeonTokenType.enumShorthand,
      lexeme: buffer.toString(),
      line: startLine,
      column: startCol,
    );
  }

  NeonToken _readIdentifierOrKeyword(int startLine, int startCol) {
    final buffer = StringBuffer();
    while (!_isAtEnd && (_isAlphaNumeric(_peek()) || _peek() == '_')) {
      buffer.write(_advance());
    }
    final text = buffer.toString();
    final keywordType = _keywords[text];
    return NeonToken(
      type: keywordType ?? NeonTokenType.identifier,
      lexeme: text,
      line: startLine,
      column: startCol,
    );
  }

  NeonToken _readPunctuation(int startLine, int startCol) {
    final ch = _advance();
    if (ch == '-' && !_isAtEnd && _peek() == '>') {
      _advance();
      return NeonToken(
        type: NeonTokenType.arrow,
        lexeme: '->',
        line: startLine,
        column: startCol,
      );
    }
    if (ch == '+' && !_isAtEnd && _peek() == '=') {
      _advance();
      return NeonToken(
        type: NeonTokenType.plusEquals,
        lexeme: '+=',
        line: startLine,
        column: startCol,
      );
    }
    if (ch == '-' && !_isAtEnd && _peek() == '=') {
      _advance();
      return NeonToken(
        type: NeonTokenType.minusEquals,
        lexeme: '-=',
        line: startLine,
        column: startCol,
      );
    }
    switch (ch) {
      case '(':
        return NeonToken(
          type: NeonTokenType.lParen,
          lexeme: ch,
          line: startLine,
          column: startCol,
        );
      case ')':
        return NeonToken(
          type: NeonTokenType.rParen,
          lexeme: ch,
          line: startLine,
          column: startCol,
        );
      case '{':
        return NeonToken(
          type: NeonTokenType.lBrace,
          lexeme: ch,
          line: startLine,
          column: startCol,
        );
      case '}':
        return NeonToken(
          type: NeonTokenType.rBrace,
          lexeme: ch,
          line: startLine,
          column: startCol,
        );
      case '[':
        return NeonToken(
          type: NeonTokenType.lBracket,
          lexeme: ch,
          line: startLine,
          column: startCol,
        );
      case ']':
        return NeonToken(
          type: NeonTokenType.rBracket,
          lexeme: ch,
          line: startLine,
          column: startCol,
        );
      case ':':
        return NeonToken(
          type: NeonTokenType.colon,
          lexeme: ch,
          line: startLine,
          column: startCol,
        );
      case ',':
        return NeonToken(
          type: NeonTokenType.comma,
          lexeme: ch,
          line: startLine,
          column: startCol,
        );
      case '.':
        return NeonToken(
          type: NeonTokenType.dot,
          lexeme: ch,
          line: startLine,
          column: startCol,
        );
      case '=':
        return NeonToken(
          type: NeonTokenType.equals,
          lexeme: ch,
          line: startLine,
          column: startCol,
        );
      default:
        return NeonToken(
          type: NeonTokenType.operatorSymbol,
          lexeme: ch,
          line: startLine,
          column: startCol,
        );
    }
  }

  void _skipWhitespaceAndComments() {
    while (!_isAtEnd) {
      final ch = _peek();
      if (ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n') {
        _advance();
      } else if (ch == '/' && _peekNext() == '/') {
        while (!_isAtEnd && _peek() != '\n') {
          _advance();
        }
      } else if (ch == '/' && _peekNext() == '*') {
        _advance();
        _advance();
        while (!_isAtEnd && !(_peek() == '*' && _peekNext() == '/')) {
          _advance();
        }
        if (!_isAtEnd) {
          _advance();
          _advance();
        }
      } else {
        break;
      }
    }
  }

  bool get _isAtEnd => _pos >= source.length;

  String _peek() => _isAtEnd ? '' : source[_pos];

  String _peekNext() => (_pos + 1 < source.length) ? source[_pos + 1] : '';

  String _advance() {
    final ch = source[_pos++];
    if (ch == '\n') {
      _line++;
      _column = 1;
    } else {
      _column++;
    }
    return ch;
  }

  bool _isDigit(String ch) =>
      ch.isNotEmpty && ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

  bool _isAlpha(String ch) {
    if (ch.isEmpty) return false;
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  bool _isAlphaNumeric(String ch) => _isAlpha(ch) || _isDigit(ch);

  bool _isHexDigit(String ch) {
    if (_isDigit(ch)) return true;
    if (ch.isEmpty) return false;
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 70) || (code >= 97 && code <= 102);
  }
}


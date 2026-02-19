import 'dart:async';

enum NeonColumnType { integer, real, text, blob }

class NeonColumn {
  final String name;
  final NeonColumnType type;
  final bool primaryKey;
  final bool autoIncrement;
  final bool nullable;
  final dynamic defaultValue;
  final bool unique;

  const NeonColumn({
    required this.name,
    required this.type,
    this.primaryKey = false,
    this.autoIncrement = false,
    this.nullable = true,
    this.defaultValue,
    this.unique = false,
  });

  String toSql() {
    final buf = StringBuffer();
    buf.write('$name ');

    switch (type) {
      case NeonColumnType.integer:
        buf.write('INTEGER');
        break;
      case NeonColumnType.real:
        buf.write('REAL');
        break;
      case NeonColumnType.text:
        buf.write('TEXT');
        break;
      case NeonColumnType.blob:
        buf.write('BLOB');
        break;
    }

    if (primaryKey) buf.write(' PRIMARY KEY');
    if (autoIncrement) buf.write(' AUTOINCREMENT');
    if (!nullable && !primaryKey) buf.write(' NOT NULL');
    if (unique) buf.write(' UNIQUE');
    if (defaultValue != null) buf.write(' DEFAULT $defaultValue');

    return buf.toString();
  }
}

class NeonTableSchema {
  final String name;
  final List<NeonColumn> columns;

  const NeonTableSchema({required this.name, required this.columns});

  String toCreateSql() {
    final cols = columns.map((c) => c.toSql()).join(', ');
    return 'CREATE TABLE IF NOT EXISTS $name ($cols)';
  }

  String toDropSql() => 'DROP TABLE IF EXISTS $name';
}

class NeonMigration {
  final int version;
  final String description;
  final List<String> upStatements;
  final List<String> downStatements;

  const NeonMigration({
    required this.version,
    required this.description,
    required this.upStatements,
    this.downStatements = const [],
  });
}

class NeonQueryResult {
  final List<Map<String, dynamic>> rows;
  final int rowsAffected;
  final int? lastInsertId;

  const NeonQueryResult({
    this.rows = const [],
    this.rowsAffected = 0,
    this.lastInsertId,
  });

  bool get isEmpty => rows.isEmpty;
  bool get isNotEmpty => rows.isNotEmpty;
  int get length => rows.length;

  Map<String, dynamic>? get first => rows.isNotEmpty ? rows.first : null;
  List<Map<String, dynamic>> get all => rows;
}

abstract class NeonDatabaseBackend {
  Future<void> open(String path);
  Future<void> close();
  Future<NeonQueryResult> execute(String sql, [List<dynamic>? params]);
  Future<NeonQueryResult> query(String sql, [List<dynamic>? params]);
  bool get isOpen;
}

class NeonMemoryDatabaseBackend implements NeonDatabaseBackend {
  bool _isOpen = false;
  final Map<String, List<Map<String, dynamic>>> _data = {};
  final List<String> _executedSql = [];

  @override
  bool get isOpen => _isOpen;

  List<String> get executedSql => List.unmodifiable(_executedSql);

  @override
  Future<void> open(String path) async {
    _isOpen = true;
  }

  @override
  Future<void> close() async {
    _isOpen = false;
  }

  @override
  Future<NeonQueryResult> execute(String sql, [List<dynamic>? params]) async {
    _ensureOpen();
    _executedSql.add(sql);

    if (sql.toUpperCase().startsWith('CREATE TABLE')) {
      final tableName = _extractTableName(sql);
      if (tableName != null) {
        _data.putIfAbsent(tableName, () => []);
      }
      return const NeonQueryResult(rowsAffected: 0);
    }

    if (sql.toUpperCase().startsWith('INSERT')) {
      final tableName = _extractInsertTableName(sql);
      if (tableName != null && _data.containsKey(tableName)) {
        final row = _buildRowFromParams(sql, params ?? []);
        _data[tableName]!.add(row);
        return NeonQueryResult(
          rowsAffected: 1,
          lastInsertId: _data[tableName]!.length,
        );
      }
      return const NeonQueryResult(rowsAffected: 1);
    }

    if (sql.toUpperCase().startsWith('DELETE')) {
      final tableName = _extractFromTableName(sql);
      if (tableName != null && _data.containsKey(tableName)) {
        final before = _data[tableName]!.length;
        _data[tableName]!.clear();
        return NeonQueryResult(rowsAffected: before);
      }
      return const NeonQueryResult(rowsAffected: 0);
    }

    return const NeonQueryResult(rowsAffected: 0);
  }

  @override
  Future<NeonQueryResult> query(String sql, [List<dynamic>? params]) async {
    _ensureOpen();
    _executedSql.add(sql);

    final tableName = _extractFromTableName(sql);
    if (tableName != null && _data.containsKey(tableName)) {
      return NeonQueryResult(rows: List.from(_data[tableName]!));
    }

    return const NeonQueryResult();
  }

  void _ensureOpen() {
    if (!_isOpen) {
      throw StateError('Database is not open.');
    }
  }

  String? _extractTableName(String sql) {
    final match = RegExp(r'CREATE TABLE\s+(?:IF NOT EXISTS\s+)?(\w+)', caseSensitive: false)
        .firstMatch(sql);
    return match?.group(1);
  }

  String? _extractInsertTableName(String sql) {
    final match = RegExp(r'INSERT\s+INTO\s+(\w+)', caseSensitive: false)
        .firstMatch(sql);
    return match?.group(1);
  }

  String? _extractFromTableName(String sql) {
    final match = RegExp(r'FROM\s+(\w+)', caseSensitive: false)
        .firstMatch(sql);
    return match?.group(1);
  }

  Map<String, dynamic> _buildRowFromParams(String sql, List<dynamic> params) {
    final match = RegExp(r'\(([^)]+)\)\s*VALUES', caseSensitive: false)
        .firstMatch(sql);
    if (match != null) {
      final columns = match.group(1)!.split(',').map((c) => c.trim()).toList();
      final row = <String, dynamic>{};
      for (var i = 0; i < columns.length && i < params.length; i++) {
        row[columns[i]] = params[i];
      }
      return row;
    }
    return {'_data': params};
  }

  Map<String, List<Map<String, dynamic>>> get dataSnapshot =>
      Map.unmodifiable(_data);
}

class NeonDatabase {
  final NeonDatabaseBackend _backend;
  final String path;
  final List<NeonTableSchema> _schemas = [];
  final List<NeonMigration> _migrations = [];
  int _version = 0;

  NeonDatabase({
    required this.path,
    NeonDatabaseBackend? backend,
  }) : _backend = backend ?? NeonMemoryDatabaseBackend();

  bool get isOpen => _backend.isOpen;
  int get version => _version;
  NeonDatabaseBackend get backend => _backend;

  void defineTable(NeonTableSchema schema) {
    _schemas.add(schema);
  }

  void addMigration(NeonMigration migration) {
    _migrations.add(migration);
    _migrations.sort((a, b) => a.version.compareTo(b.version));
  }

  Future<void> open() async {
    await _backend.open(path);
    await _createTables();
    await _runMigrations();
  }

  Future<void> close() async {
    await _backend.close();
  }

  Future<void> _createTables() async {
    for (final schema in _schemas) {
      await _backend.execute(schema.toCreateSql());
    }
  }

  Future<void> _runMigrations() async {
    for (final migration in _migrations) {
      if (migration.version > _version) {
        for (final sql in migration.upStatements) {
          await _backend.execute(sql);
        }
        _version = migration.version;
      }
    }
  }

  Future<NeonQueryResult> rawQuery(String sql, [List<dynamic>? params]) {
    return _backend.query(sql, params);
  }

  Future<NeonQueryResult> rawExecute(String sql, [List<dynamic>? params]) {
    return _backend.execute(sql, params);
  }

  Future<NeonQueryResult> insert(
    String table,
    Map<String, dynamic> values,
  ) {
    final columns = values.keys.join(', ');
    final placeholders = values.keys.map((_) => '?').join(', ');
    final sql = 'INSERT INTO $table ($columns) VALUES ($placeholders)';
    return _backend.execute(sql, values.values.toList());
  }

  Future<NeonQueryResult> queryTable(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
    final buf = StringBuffer('SELECT * FROM $table');
    if (where != null) buf.write(' WHERE $where');
    if (orderBy != null) buf.write(' ORDER BY $orderBy');
    if (limit != null) buf.write(' LIMIT $limit');
    if (offset != null) buf.write(' OFFSET $offset');
    return _backend.query(buf.toString(), whereArgs);
  }

  Future<NeonQueryResult> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) {
    final sets = values.keys.map((k) => '$k = ?').join(', ');
    final buf = StringBuffer('UPDATE $table SET $sets');
    if (where != null) buf.write(' WHERE $where');
    final params = [...values.values, ...?whereArgs];
    return _backend.execute(buf.toString(), params);
  }

  Future<NeonQueryResult> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) {
    final buf = StringBuffer('DELETE FROM $table');
    if (where != null) buf.write(' WHERE $where');
    return _backend.execute(buf.toString(), whereArgs);
  }
}

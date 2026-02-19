import 'dart:async';
import 'dart:convert';

abstract class NeonKVBackend {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
  Future<void> clear();
  Future<List<String>> keys();
  Future<bool> containsKey(String key);
}

class NeonMemoryKVBackend implements NeonKVBackend {
  final Map<String, String> _store = {};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  Future<List<String>> keys() async => _store.keys.toList();

  @override
  Future<bool> containsKey(String key) async => _store.containsKey(key);

  Map<String, String> get snapshot => Map.unmodifiable(_store);
}

class NeonKeyValueStore {
  final NeonKVBackend _backend;
  final String _prefix;

  NeonKeyValueStore({
    NeonKVBackend? backend,
    String prefix = '',
  })  : _backend = backend ?? NeonMemoryKVBackend(),
        _prefix = prefix;

  String _prefixedKey(String key) => _prefix.isEmpty ? key : '$_prefix.$key';

  Future<String?> getString(String key) {
    return _backend.read(_prefixedKey(key));
  }

  Future<void> setString(String key, String value) {
    return _backend.write(_prefixedKey(key), value);
  }

  Future<int?> getInt(String key) async {
    final raw = await _backend.read(_prefixedKey(key));
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<void> setInt(String key, int value) {
    return _backend.write(_prefixedKey(key), value.toString());
  }

  Future<double?> getDouble(String key) async {
    final raw = await _backend.read(_prefixedKey(key));
    if (raw == null) return null;
    return double.tryParse(raw);
  }

  Future<void> setDouble(String key, double value) {
    return _backend.write(_prefixedKey(key), value.toString());
  }

  Future<bool?> getBool(String key) async {
    final raw = await _backend.read(_prefixedKey(key));
    if (raw == null) return null;
    return raw == 'true';
  }

  Future<void> setBool(String key, bool value) {
    return _backend.write(_prefixedKey(key), value.toString());
  }

  Future<List<String>?> getStringList(String key) async {
    final raw = await _backend.read(_prefixedKey(key));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.cast<String>();
      }
    } catch (_) {}
    return null;
  }

  Future<void> setStringList(String key, List<String> value) {
    return _backend.write(_prefixedKey(key), jsonEncode(value));
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await _backend.read(_prefixedKey(key));
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setJson(String key, Map<String, dynamic> value) {
    return _backend.write(_prefixedKey(key), jsonEncode(value));
  }

  Future<void> remove(String key) {
    return _backend.remove(_prefixedKey(key));
  }

  Future<void> clear() {
    return _backend.clear();
  }

  Future<List<String>> keys() {
    return _backend.keys();
  }

  Future<bool> containsKey(String key) {
    return _backend.containsKey(_prefixedKey(key));
  }

  NeonKVBackend get backend => _backend;
}

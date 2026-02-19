import 'dart:async';

enum NeonCachePolicyType {
  cacheFirst,
  networkFirst,
  cacheOnly,
  networkOnly,
  staleWhileRevalidate,
}

class NeonCacheEntry<T> {
  final String key;
  final T data;
  final DateTime cachedAt;
  final Duration? maxAge;

  NeonCacheEntry({
    required this.key,
    required this.data,
    DateTime? cachedAt,
    this.maxAge,
  }) : cachedAt = cachedAt ?? DateTime.now();

  bool get isExpired {
    if (maxAge == null) return false;
    return DateTime.now().difference(cachedAt) > maxAge!;
  }

  bool get isFresh => !isExpired;

  Duration get age => DateTime.now().difference(cachedAt);

  @override
  String toString() =>
      'NeonCacheEntry($key, age: ${age.inSeconds}s, expired: $isExpired)';
}

class NeonCacheStore {
  final Map<String, NeonCacheEntry<dynamic>> _entries = {};
  final Duration defaultMaxAge;

  NeonCacheStore({this.defaultMaxAge = const Duration(minutes: 5)});

  void put<T>(String key, T data, {Duration? maxAge}) {
    _entries[key] = NeonCacheEntry<T>(
      key: key,
      data: data,
      maxAge: maxAge ?? defaultMaxAge,
    );
  }

  NeonCacheEntry<T>? get<T>(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    return NeonCacheEntry<T>(
      key: entry.key,
      data: entry.data as T,
      cachedAt: entry.cachedAt,
      maxAge: entry.maxAge,
    );
  }

  bool has(String key) => _entries.containsKey(key);

  bool hasFresh(String key) {
    final entry = _entries[key];
    return entry != null && entry.isFresh;
  }

  void remove(String key) => _entries.remove(key);

  void clear() => _entries.clear();

  void evictExpired() {
    _entries.removeWhere((_, entry) => entry.isExpired);
  }

  int get size => _entries.length;
  List<String> get keys => _entries.keys.toList();

  Map<String, dynamic> get stats => {
    'size': size,
    'fresh': _entries.values.where((e) => e.isFresh).length,
    'expired': _entries.values.where((e) => e.isExpired).length,
  };
}

class NeonCachePolicy<T> {
  final NeonCachePolicyType type;
  final NeonCacheStore _store;
  final Future<T> Function(String key) _fetcher;
  final Duration? maxAge;
  final void Function(T data)? _onBackgroundRefresh;

  NeonCachePolicy({
    required this.type,
    required NeonCacheStore store,
    required Future<T> Function(String key) fetcher,
    this.maxAge,
    void Function(T data)? onBackgroundRefresh,
  })  : _store = store,
        _fetcher = fetcher,
        _onBackgroundRefresh = onBackgroundRefresh;

  factory NeonCachePolicy.cacheFirst({
    required NeonCacheStore store,
    required Future<T> Function(String key) fetcher,
    Duration? maxAge,
  }) {
    return NeonCachePolicy(
      type: NeonCachePolicyType.cacheFirst,
      store: store,
      fetcher: fetcher,
      maxAge: maxAge,
    );
  }

  factory NeonCachePolicy.networkFirst({
    required NeonCacheStore store,
    required Future<T> Function(String key) fetcher,
    Duration? maxAge,
  }) {
    return NeonCachePolicy(
      type: NeonCachePolicyType.networkFirst,
      store: store,
      fetcher: fetcher,
      maxAge: maxAge,
    );
  }

  factory NeonCachePolicy.cacheOnly({
    required NeonCacheStore store,
    required Future<T> Function(String key) fetcher,
  }) {
    return NeonCachePolicy(
      type: NeonCachePolicyType.cacheOnly,
      store: store,
      fetcher: fetcher,
    );
  }

  factory NeonCachePolicy.networkOnly({
    required NeonCacheStore store,
    required Future<T> Function(String key) fetcher,
    Duration? maxAge,
  }) {
    return NeonCachePolicy(
      type: NeonCachePolicyType.networkOnly,
      store: store,
      fetcher: fetcher,
      maxAge: maxAge,
    );
  }

  factory NeonCachePolicy.staleWhileRevalidate({
    required NeonCacheStore store,
    required Future<T> Function(String key) fetcher,
    Duration? maxAge,
    void Function(T data)? onBackgroundRefresh,
  }) {
    return NeonCachePolicy(
      type: NeonCachePolicyType.staleWhileRevalidate,
      store: store,
      fetcher: fetcher,
      maxAge: maxAge,
      onBackgroundRefresh: onBackgroundRefresh,
    );
  }

  Future<T> execute(String key) async {
    switch (type) {
      case NeonCachePolicyType.cacheFirst:
        return _executeCacheFirst(key);
      case NeonCachePolicyType.networkFirst:
        return _executeNetworkFirst(key);
      case NeonCachePolicyType.cacheOnly:
        return _executeCacheOnly(key);
      case NeonCachePolicyType.networkOnly:
        return _executeNetworkOnly(key);
      case NeonCachePolicyType.staleWhileRevalidate:
        return _executeStaleWhileRevalidate(key);
    }
  }

  Future<T> _executeCacheFirst(String key) async {
    final cached = _store.get<T>(key);
    if (cached != null && cached.isFresh) {
      return cached.data;
    }

    final data = await _fetcher(key);
    _store.put<T>(key, data, maxAge: maxAge);
    return data;
  }

  Future<T> _executeNetworkFirst(String key) async {
    try {
      final data = await _fetcher(key);
      _store.put<T>(key, data, maxAge: maxAge);
      return data;
    } catch (_) {
      final cached = _store.get<T>(key);
      if (cached != null) {
        return cached.data;
      }
      rethrow;
    }
  }

  Future<T> _executeCacheOnly(String key) async {
    final cached = _store.get<T>(key);
    if (cached != null) {
      return cached.data;
    }
    throw StateError('No cached data for key "$key".');
  }

  Future<T> _executeNetworkOnly(String key) async {
    final data = await _fetcher(key);
    _store.put<T>(key, data, maxAge: maxAge);
    return data;
  }

  Future<T> _executeStaleWhileRevalidate(String key) async {
    final cached = _store.get<T>(key);

    if (cached != null) {
      if (cached.isExpired) {
        _backgroundRefresh(key);
      }
      return cached.data;
    }

    final data = await _fetcher(key);
    _store.put<T>(key, data, maxAge: maxAge);
    return data;
  }

  void _backgroundRefresh(String key) {
    _fetcher(key).then((data) {
      _store.put<T>(key, data, maxAge: maxAge);
      _onBackgroundRefresh?.call(data);
    }).catchError((_) {});
  }
}

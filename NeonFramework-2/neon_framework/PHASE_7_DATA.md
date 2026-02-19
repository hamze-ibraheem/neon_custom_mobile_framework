# Neon Framework — Phase 7: Storage & Networking

## Status: Complete

## What Was Built

### Key-Value Store (`NeonKeyValueStore`)
Simple preferences and settings storage:
- **Type-safe accessors**: getString, setString, getInt, setInt, getDouble, setDouble, getBool, setBool
- **Complex types**: setStringList/getStringList, setJson/getJson
- **Backend abstraction**: `NeonKVBackend` interface with `NeonMemoryKVBackend` for testing
- **Key prefixing**: Namespace isolation via prefix parameter
- **CRUD**: containsKey, remove, clear, keys

### SQLite Database (`NeonDatabase`)
Structured data persistence:
- **Table schemas**: `NeonTableSchema` with `NeonColumn` definitions (INTEGER, REAL, TEXT, BLOB)
- **Column constraints**: PRIMARY KEY, AUTOINCREMENT, NOT NULL, UNIQUE, DEFAULT
- **Query builder**: insert, queryTable (with WHERE, ORDER BY, LIMIT, OFFSET), update, delete
- **Raw SQL**: rawQuery and rawExecute for custom operations
- **Migrations**: Ordered `NeonMigration` system with version tracking and up/down statements
- **Backend abstraction**: `NeonDatabaseBackend` interface with `NeonMemoryDatabaseBackend` for testing

### HTTP Client (`NeonHttpClient`)
REST API access:
- **All HTTP methods**: GET, POST, PUT, PATCH, DELETE, HEAD
- **Base URL**: Automatic path resolution against configurable base URL
- **Headers**: Case-insensitive `NeonHttpHeaders` with merge support
- **Request/Response interceptors**: Composable middleware pipeline for auth, logging, etc.
- **Response parsing**: `.json`, `.jsonList`, status code helpers (isSuccess, isClientError, etc.)
- **Backend abstraction**: `NeonDartHttpBackend` (real dart:io) and `NeonMockHttpBackend` for testing
- **Mock support**: URL pattern matching, default handlers, request tracking

### WebSocket Client (`NeonWebSocket`)
Real-time communication:
- **Connection lifecycle**: connect, close, reconnect with state tracking
- **Send**: Raw string and JSON serialization
- **Receive**: Message listeners with JSON parsing support
- **Auto-reconnect**: Configurable delay and max attempts
- **Event hooks**: onConnect, onDisconnect, onMessage
- **Backend abstraction**: `NeonMockWebSocketBackend` with message simulation

### Cache Policy System (`NeonCachePolicy`)
Offline-first strategies:
- **Cache-first**: Read from cache, fall back to network (default for offline-first)
- **Network-first**: Try network, fall back to cache (for data freshness)
- **Cache-only**: Strict offline mode, throws if no cache
- **Network-only**: Always fetch, caches result for later
- **Stale-while-revalidate**: Return stale immediately, refresh in background
- **Cache store**: TTL-based expiry, eviction, statistics
- **Background refresh**: Callback notification when stale data is refreshed

### Architecture
```
neon_framework/lib/src/data/
  kv_store.dart         # NeonKeyValueStore, NeonKVBackend, NeonMemoryKVBackend
  database.dart         # NeonDatabase, NeonTableSchema, NeonColumn, NeonMigration
  http_client.dart      # NeonHttpClient, NeonHttpRequest/Response, backends
  web_socket.dart       # NeonWebSocket, NeonWebSocketMessage, backends
  cache_policy.dart     # NeonCachePolicy, NeonCacheStore, NeonCacheEntry
```

## Tests
81 new tests added (250 total passing):
- Key-Value Store: string/int/double/bool/list/json, CRUD, prefix isolation
- Database: open/close, schema creation, insert/query/delete, migrations, raw SQL
- HTTP Client: mock backend, URL resolution, interceptors, all methods, response parsing
- WebSocket: connect/send/receive/close, reconnect, JSON messages, listeners
- Cache Policy: all 5 strategies with edge cases (miss, hit, fallback, background refresh)

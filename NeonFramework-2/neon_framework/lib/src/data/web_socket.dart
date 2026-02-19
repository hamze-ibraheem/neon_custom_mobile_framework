import 'dart:async';
import 'dart:convert';

enum NeonWebSocketState {
  connecting,
  connected,
  disconnecting,
  disconnected,
}

class NeonWebSocketMessage {
  final String data;
  final DateTime timestamp;

  NeonWebSocketMessage(this.data, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic>? get json {
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'NeonWebSocketMessage($data)';
}

abstract class NeonWebSocketBackend {
  Future<void> connect(String url, {Map<String, String>? headers});
  void send(String data);
  Future<void> close([int? code, String? reason]);
  Stream<NeonWebSocketMessage> get messages;
  NeonWebSocketState get state;
}

class NeonMockWebSocketBackend implements NeonWebSocketBackend {
  NeonWebSocketState _state = NeonWebSocketState.disconnected;
  final _controller = StreamController<NeonWebSocketMessage>.broadcast();
  final List<String> sentMessages = [];
  String? connectedUrl;

  @override
  NeonWebSocketState get state => _state;

  @override
  Stream<NeonWebSocketMessage> get messages => _controller.stream;

  @override
  Future<void> connect(String url, {Map<String, String>? headers}) async {
    _state = NeonWebSocketState.connecting;
    connectedUrl = url;
    _state = NeonWebSocketState.connected;
  }

  @override
  void send(String data) {
    if (_state != NeonWebSocketState.connected) {
      throw StateError('WebSocket is not connected.');
    }
    sentMessages.add(data);
  }

  @override
  Future<void> close([int? code, String? reason]) async {
    _state = NeonWebSocketState.disconnecting;
    _state = NeonWebSocketState.disconnected;
  }

  void simulateMessage(String data) {
    _controller.add(NeonWebSocketMessage(data));
  }

  void dispose() {
    _controller.close();
  }
}

class NeonWebSocket {
  final NeonWebSocketBackend _backend;
  final Duration _reconnectDelay;
  final int _maxReconnectAttempts;

  int _reconnectAttempts = 0;
  String? _url;
  Map<String, String>? _headers;
  bool _shouldAutoReconnect;
  final List<void Function(NeonWebSocketMessage)> _listeners = [];
  final List<void Function()> _connectListeners = [];
  final List<void Function(int?, String?)> _disconnectListeners = [];
  StreamSubscription? _messageSub;

  NeonWebSocket({
    NeonWebSocketBackend? backend,
    Duration reconnectDelay = const Duration(seconds: 3),
    int maxReconnectAttempts = 5,
    bool autoReconnect = true,
  })  : _backend = backend ?? NeonMockWebSocketBackend(),
        _reconnectDelay = reconnectDelay,
        _maxReconnectAttempts = maxReconnectAttempts,
        _shouldAutoReconnect = autoReconnect;

  NeonWebSocketState get state => _backend.state;
  bool get isConnected => _backend.state == NeonWebSocketState.connected;
  bool get autoReconnect => _shouldAutoReconnect;
  NeonWebSocketBackend get backend => _backend;

  Future<void> connect(String url, {Map<String, String>? headers}) async {
    _url = url;
    _headers = headers;
    _reconnectAttempts = 0;

    await _backend.connect(url, headers: headers);

    _messageSub = _backend.messages.listen((msg) {
      for (final listener in _listeners) {
        listener(msg);
      }
    });

    for (final listener in _connectListeners) {
      listener();
    }
  }

  void send(String data) {
    _backend.send(data);
  }

  void sendJson(Map<String, dynamic> data) {
    _backend.send(jsonEncode(data));
  }

  Future<void> close([int? code, String? reason]) async {
    _shouldAutoReconnect = false;
    await _messageSub?.cancel();
    await _backend.close(code, reason);

    for (final listener in _disconnectListeners) {
      listener(code, reason);
    }
  }

  void onMessage(void Function(NeonWebSocketMessage) listener) {
    _listeners.add(listener);
  }

  void onConnect(void Function() listener) {
    _connectListeners.add(listener);
  }

  void onDisconnect(void Function(int?, String?) listener) {
    _disconnectListeners.add(listener);
  }

  Future<void> reconnect() async {
    if (_url == null) {
      throw StateError('No previous connection to reconnect to.');
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      throw StateError('Max reconnection attempts ($_maxReconnectAttempts) exceeded.');
    }

    _reconnectAttempts++;
    await Future.delayed(_reconnectDelay);
    await connect(_url!, headers: _headers);
  }

  void dispose() {
    _messageSub?.cancel();
    _listeners.clear();
    _connectListeners.clear();
    _disconnectListeners.clear();
  }
}

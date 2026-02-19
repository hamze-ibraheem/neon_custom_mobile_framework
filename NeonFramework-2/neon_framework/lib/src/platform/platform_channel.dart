import 'dart:async';

typedef MessageHandler = Future<dynamic> Function(String method, dynamic arguments);

enum NeonChannelCodec { json, binary, standard }

class NeonPlatformChannel {
  final String name;
  final NeonChannelCodec codec;
  MessageHandler? _handler;
  final StreamController<NeonChannelMessage> _incomingController =
      StreamController<NeonChannelMessage>.broadcast();
  final List<NeonChannelMessage> _messageLog = [];
  bool _isOpen = true;

  NeonPlatformChannel({
    required this.name,
    this.codec = NeonChannelCodec.standard,
  });

  bool get isOpen => _isOpen;
  Stream<NeonChannelMessage> get incoming => _incomingController.stream;
  List<NeonChannelMessage> get messageLog => List.unmodifiable(_messageLog);

  void setMessageHandler(MessageHandler handler) {
    _handler = handler;
  }

  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async {
    _ensureOpen();

    final message = NeonChannelMessage(
      channel: name,
      method: method,
      arguments: arguments,
      direction: NeonMessageDirection.dartToNative,
      timestamp: DateTime.now(),
    );
    _messageLog.add(message);

    return NeonPlatformDispatcher.instance.sendMessage<T>(this, message);
  }

  Future<dynamic> handlePlatformMessage(String method, dynamic arguments) async {
    final message = NeonChannelMessage(
      channel: name,
      method: method,
      arguments: arguments,
      direction: NeonMessageDirection.nativeToDart,
      timestamp: DateTime.now(),
    );
    _messageLog.add(message);
    _incomingController.add(message);

    if (_handler != null) {
      return _handler!(method, arguments);
    }
    return null;
  }

  void close() {
    _isOpen = false;
    _incomingController.close();
  }

  void _ensureOpen() {
    if (!_isOpen) {
      throw StateError('Channel "$name" is closed.');
    }
  }

  @override
  String toString() => 'NeonPlatformChannel($name, codec: ${codec.name})';
}

enum NeonMessageDirection { dartToNative, nativeToDart }

class NeonChannelMessage {
  final String channel;
  final String method;
  final dynamic arguments;
  final NeonMessageDirection direction;
  final DateTime timestamp;

  const NeonChannelMessage({
    required this.channel,
    required this.method,
    this.arguments,
    required this.direction,
    required this.timestamp,
  });

  @override
  String toString() =>
      'NeonChannelMessage($channel.$method, ${direction.name})';
}

class NeonPlatformDispatcher {
  static NeonPlatformDispatcher? _instance;
  static NeonPlatformDispatcher get instance {
    _instance ??= NeonPlatformDispatcher._();
    return _instance!;
  }

  NeonPlatformDispatcher._();

  final Map<String, NeonPlatformChannel> _channels = {};
  PlatformMessageCallback? _mockDispatcher;

  void registerChannel(NeonPlatformChannel channel) {
    _channels[channel.name] = channel;
  }

  void unregisterChannel(String name) {
    _channels.remove(name);
  }

  NeonPlatformChannel? getChannel(String name) => _channels[name];

  Future<T?> sendMessage<T>(
      NeonPlatformChannel channel, NeonChannelMessage message) async {
    if (_mockDispatcher != null) {
      final result = await _mockDispatcher!(message);
      return result as T?;
    }
    return null;
  }

  Future<void> receivePlatformMessage(
      String channelName, String method, dynamic arguments) async {
    final channel = _channels[channelName];
    if (channel != null) {
      await channel.handlePlatformMessage(method, arguments);
    }
  }

  void setMockDispatcher(PlatformMessageCallback callback) {
    _mockDispatcher = callback;
  }

  void clearMockDispatcher() {
    _mockDispatcher = null;
  }

  void dispose() {
    for (final channel in _channels.values) {
      channel.close();
    }
    _channels.clear();
    _mockDispatcher = null;
  }

  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}

typedef PlatformMessageCallback = Future<dynamic> Function(NeonChannelMessage message);

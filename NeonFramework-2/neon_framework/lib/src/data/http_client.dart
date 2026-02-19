import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum NeonHttpMethod { get, post, put, patch, delete, head }

class NeonHttpHeaders {
  final Map<String, String> _headers;

  NeonHttpHeaders([Map<String, String>? headers])
      : _headers = Map.from(headers ?? {});

  String? operator [](String key) => _headers[key.toLowerCase()];
  void operator []=(String key, String value) {
    _headers[key.toLowerCase()] = value;
  }

  void set(String key, String value) => _headers[key.toLowerCase()] = value;
  void remove(String key) => _headers.remove(key.toLowerCase());
  bool containsKey(String key) => _headers.containsKey(key.toLowerCase());

  Map<String, String> toMap() => Map.unmodifiable(_headers);

  NeonHttpHeaders merge(NeonHttpHeaders other) {
    return NeonHttpHeaders({..._headers, ...other._headers});
  }
}

class NeonHttpRequest {
  final NeonHttpMethod method;
  final Uri url;
  final NeonHttpHeaders headers;
  final dynamic body;
  final Duration? timeout;

  NeonHttpRequest({
    required this.method,
    required this.url,
    NeonHttpHeaders? headers,
    this.body,
    this.timeout,
  }) : headers = headers ?? NeonHttpHeaders();

  NeonHttpRequest.get(String url, {NeonHttpHeaders? headers, Duration? timeout})
      : this(
          method: NeonHttpMethod.get,
          url: Uri.parse(url),
          headers: headers,
          timeout: timeout,
        );

  NeonHttpRequest.post(String url, {dynamic body, NeonHttpHeaders? headers, Duration? timeout})
      : this(
          method: NeonHttpMethod.post,
          url: Uri.parse(url),
          headers: headers,
          body: body,
          timeout: timeout,
        );

  NeonHttpRequest.put(String url, {dynamic body, NeonHttpHeaders? headers, Duration? timeout})
      : this(
          method: NeonHttpMethod.put,
          url: Uri.parse(url),
          headers: headers,
          body: body,
          timeout: timeout,
        );

  NeonHttpRequest.delete(String url, {NeonHttpHeaders? headers, Duration? timeout})
      : this(
          method: NeonHttpMethod.delete,
          url: Uri.parse(url),
          headers: headers,
          timeout: timeout,
        );
}

class NeonHttpResponse {
  final int statusCode;
  final NeonHttpHeaders headers;
  final String body;
  final Duration duration;
  final NeonHttpRequest request;

  NeonHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.duration,
    required this.request,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;

  Map<String, dynamic> get json {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Response body is not valid JSON: $e');
    }
  }

  List<dynamic> get jsonList {
    try {
      return jsonDecode(body) as List<dynamic>;
    } catch (e) {
      throw FormatException('Response body is not valid JSON array: $e');
    }
  }

  @override
  String toString() =>
      'NeonHttpResponse($statusCode, ${body.length} bytes, ${duration.inMilliseconds}ms)';
}

typedef NeonHttpInterceptor = Future<NeonHttpRequest> Function(NeonHttpRequest request);
typedef NeonHttpResponseInterceptor = Future<NeonHttpResponse> Function(NeonHttpResponse response);

abstract class NeonHttpBackend {
  Future<NeonHttpResponse> send(NeonHttpRequest request);
}

class NeonDartHttpBackend implements NeonHttpBackend {
  @override
  Future<NeonHttpResponse> send(NeonHttpRequest request) async {
    final client = HttpClient();
    final stopwatch = Stopwatch()..start();

    try {
      final ioRequest = await client.openUrl(
        request.method.name.toUpperCase(),
        request.url,
      );

      request.headers.toMap().forEach((key, value) {
        ioRequest.headers.set(key, value);
      });

      if (request.body != null) {
        String bodyStr;
        if (request.body is Map || request.body is List) {
          bodyStr = jsonEncode(request.body);
          ioRequest.headers.set('content-type', 'application/json');
        } else {
          bodyStr = request.body.toString();
        }
        ioRequest.write(bodyStr);
      }

      final ioResponse = await ioRequest.close();
      final responseBody = await ioResponse.transform(utf8.decoder).join();

      stopwatch.stop();

      final responseHeaders = NeonHttpHeaders();
      ioResponse.headers.forEach((name, values) {
        responseHeaders.set(name, values.join(', '));
      });

      return NeonHttpResponse(
        statusCode: ioResponse.statusCode,
        headers: responseHeaders,
        body: responseBody,
        duration: stopwatch.elapsed,
        request: request,
      );
    } finally {
      client.close();
    }
  }
}

class NeonMockHttpBackend implements NeonHttpBackend {
  final List<NeonHttpRequest> sentRequests = [];
  final Map<String, NeonHttpResponse Function(NeonHttpRequest)> _handlers = {};
  NeonHttpResponse Function(NeonHttpRequest)? _defaultHandler;

  void onRequest(String urlPattern, NeonHttpResponse Function(NeonHttpRequest) handler) {
    _handlers[urlPattern] = handler;
  }

  void onAnyRequest(NeonHttpResponse Function(NeonHttpRequest) handler) {
    _defaultHandler = handler;
  }

  NeonHttpResponse mockResponse({
    int statusCode = 200,
    String body = '',
    Map<String, String>? headers,
    required NeonHttpRequest request,
  }) {
    return NeonHttpResponse(
      statusCode: statusCode,
      headers: NeonHttpHeaders(headers ?? {}),
      body: body,
      duration: const Duration(milliseconds: 1),
      request: request,
    );
  }

  @override
  Future<NeonHttpResponse> send(NeonHttpRequest request) async {
    sentRequests.add(request);

    final url = request.url.toString();
    for (final entry in _handlers.entries) {
      if (url.contains(entry.key)) {
        return entry.value(request);
      }
    }

    if (_defaultHandler != null) {
      return _defaultHandler!(request);
    }

    return mockResponse(
      statusCode: 200,
      body: '{"mock": true}',
      request: request,
    );
  }
}

class NeonHttpClient {
  final NeonHttpBackend _backend;
  final NeonHttpHeaders _defaultHeaders;
  final String? _baseUrl;
  final Duration _defaultTimeout;
  final List<NeonHttpInterceptor> _requestInterceptors = [];
  final List<NeonHttpResponseInterceptor> _responseInterceptors = [];

  NeonHttpClient({
    NeonHttpBackend? backend,
    NeonHttpHeaders? defaultHeaders,
    String? baseUrl,
    Duration defaultTimeout = const Duration(seconds: 30),
  })  : _backend = backend ?? NeonDartHttpBackend(),
        _defaultHeaders = defaultHeaders ?? NeonHttpHeaders(),
        _baseUrl = baseUrl,
        _defaultTimeout = defaultTimeout;

  NeonHttpBackend get backend => _backend;

  void addRequestInterceptor(NeonHttpInterceptor interceptor) {
    _requestInterceptors.add(interceptor);
  }

  void addResponseInterceptor(NeonHttpResponseInterceptor interceptor) {
    _responseInterceptors.add(interceptor);
  }

  Uri _resolveUrl(String urlOrPath) {
    if (urlOrPath.startsWith('http://') || urlOrPath.startsWith('https://')) {
      return Uri.parse(urlOrPath);
    }
    if (_baseUrl != null) {
      final base = _baseUrl!.endsWith('/') ? _baseUrl! : '$_baseUrl/';
      final path = urlOrPath.startsWith('/') ? urlOrPath.substring(1) : urlOrPath;
      return Uri.parse('$base$path');
    }
    return Uri.parse(urlOrPath);
  }

  Future<NeonHttpResponse> send(NeonHttpRequest request) async {
    var req = request;
    for (final interceptor in _requestInterceptors) {
      req = await interceptor(req);
    }

    var response = await _backend.send(req);
    for (final interceptor in _responseInterceptors) {
      response = await interceptor(response);
    }

    return response;
  }

  Future<NeonHttpResponse> get(
    String url, {
    NeonHttpHeaders? headers,
    Duration? timeout,
  }) {
    return send(NeonHttpRequest(
      method: NeonHttpMethod.get,
      url: _resolveUrl(url),
      headers: _defaultHeaders.merge(headers ?? NeonHttpHeaders()),
      timeout: timeout ?? _defaultTimeout,
    ));
  }

  Future<NeonHttpResponse> post(
    String url, {
    dynamic body,
    NeonHttpHeaders? headers,
    Duration? timeout,
  }) {
    return send(NeonHttpRequest(
      method: NeonHttpMethod.post,
      url: _resolveUrl(url),
      headers: _defaultHeaders.merge(headers ?? NeonHttpHeaders()),
      body: body,
      timeout: timeout ?? _defaultTimeout,
    ));
  }

  Future<NeonHttpResponse> put(
    String url, {
    dynamic body,
    NeonHttpHeaders? headers,
    Duration? timeout,
  }) {
    return send(NeonHttpRequest(
      method: NeonHttpMethod.put,
      url: _resolveUrl(url),
      headers: _defaultHeaders.merge(headers ?? NeonHttpHeaders()),
      body: body,
      timeout: timeout ?? _defaultTimeout,
    ));
  }

  Future<NeonHttpResponse> patch(
    String url, {
    dynamic body,
    NeonHttpHeaders? headers,
    Duration? timeout,
  }) {
    return send(NeonHttpRequest(
      method: NeonHttpMethod.patch,
      url: _resolveUrl(url),
      headers: _defaultHeaders.merge(headers ?? NeonHttpHeaders()),
      body: body,
      timeout: timeout ?? _defaultTimeout,
    ));
  }

  Future<NeonHttpResponse> delete(
    String url, {
    NeonHttpHeaders? headers,
    Duration? timeout,
  }) {
    return send(NeonHttpRequest(
      method: NeonHttpMethod.delete,
      url: _resolveUrl(url),
      headers: _defaultHeaders.merge(headers ?? NeonHttpHeaders()),
      timeout: timeout ?? _defaultTimeout,
    ));
  }
}

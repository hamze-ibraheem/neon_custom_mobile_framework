/// Represents the status of an asynchronous operation.
enum NeonAsyncStatus { loading, success, error, cached }

/// A wrapper for asynchronous values that tracks loading, success, error, and cached states.
class NeonAsyncValue<T> {
  final NeonAsyncStatus status;
  final T? _data;
  final Object? _error;
  final StackTrace? _stackTrace;

  /// Whether a refresh is currently in progress (for cached values).
  final bool isRefreshing;

  const NeonAsyncValue._({
    required this.status,
    T? data,
    Object? error,
    StackTrace? stackTrace,
    this.isRefreshing = false,
  })  : _data = data,
        _error = error,
        _stackTrace = stackTrace;

  /// Creates an async value in the loading state.
  const NeonAsyncValue.loading()
      : this._(status: NeonAsyncStatus.loading);

  /// Creates an async value in the success state with the given data.
  const NeonAsyncValue.success(T data)
      : this._(status: NeonAsyncStatus.success, data: data);

  /// Creates an async value in the error state with the given error.
  NeonAsyncValue.error(Object error, [StackTrace? stackTrace])
      : this._(status: NeonAsyncStatus.error, error: error, stackTrace: stackTrace);

  /// Creates an async value in the cached state with optional refresh indicator.
  const NeonAsyncValue.cached(T data, {bool isRefreshing = false})
      : this._(status: NeonAsyncStatus.cached, data: data, isRefreshing: isRefreshing);

  /// Whether the value is currently loading.
  bool get isLoading => status == NeonAsyncStatus.loading;

  /// Whether the value completed successfully.
  bool get isSuccess => status == NeonAsyncStatus.success;

  /// Whether the value resulted in an error.
  bool get isError => status == NeonAsyncStatus.error;

  /// Whether the value is from cache.
  bool get isCached => status == NeonAsyncStatus.cached;

  /// Whether data is available.
  bool get hasData => _data != null;

  /// Whether an error is present.
  bool get hasError => _error != null;

  /// The data value; throws if no data is available.
  T get data {
    if (_data == null) {
      throw StateError('No data available. Status: $status');
    }
    return _data as T;
  }

  /// The data value, or null if not available.
  T? get dataOrNull => _data;

  /// The error object; throws if no error is present.
  Object get error {
    if (_error == null) {
      throw StateError('No error available. Status: $status');
    }
    return _error!;
  }

  /// The stack trace associated with the error, if any.
  StackTrace? get stackTrace => _stackTrace;

  /// Pattern-matches on the async status and returns the result of the matching callback.
  R when<R>({
    required R Function() loading,
    required R Function(T data) success,
    required R Function(Object error, StackTrace? stackTrace) error,
    R Function(T data, bool isRefreshing)? cached,
  }) {
    switch (status) {
      case NeonAsyncStatus.loading:
        return loading();
      case NeonAsyncStatus.success:
        return success(_data as T);
      case NeonAsyncStatus.error:
        return error(_error!, _stackTrace);
      case NeonAsyncStatus.cached:
        if (cached != null) {
          return cached(_data as T, isRefreshing);
        }
        return success(_data as T);
    }
  }

  /// Pattern-matches with optional callbacks and a required fallback.
  R maybeWhen<R>({
    R Function()? loading,
    R Function(T data)? success,
    R Function(Object error, StackTrace? stackTrace)? error,
    R Function(T data, bool isRefreshing)? cached,
    required R Function() orElse,
  }) {
    switch (status) {
      case NeonAsyncStatus.loading:
        return loading != null ? loading() : orElse();
      case NeonAsyncStatus.success:
        return success != null ? success(_data as T) : orElse();
      case NeonAsyncStatus.error:
        return error != null ? error(_error!, _stackTrace) : orElse();
      case NeonAsyncStatus.cached:
        return cached != null ? cached(_data as T, isRefreshing) : orElse();
    }
  }

  /// Returns a copy with optionally overridden fields.
  NeonAsyncValue<T> copyWith({
    NeonAsyncStatus? status,
    T? data,
    Object? error,
    StackTrace? stackTrace,
    bool? isRefreshing,
  }) {
    return NeonAsyncValue<T>._(
      status: status ?? this.status,
      data: data ?? _data,
      error: error ?? _error,
      stackTrace: stackTrace ?? _stackTrace,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  String toString() {
    switch (status) {
      case NeonAsyncStatus.loading:
        return 'NeonAsyncValue<$T>.loading()';
      case NeonAsyncStatus.success:
        return 'NeonAsyncValue<$T>.success($_data)';
      case NeonAsyncStatus.error:
        return 'NeonAsyncValue<$T>.error($_error)';
      case NeonAsyncStatus.cached:
        return 'NeonAsyncValue<$T>.cached($_data, refreshing: $isRefreshing)';
    }
  }
}

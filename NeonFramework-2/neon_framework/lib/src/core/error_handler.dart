import 'environment.dart';

/// Callback type for custom error handling.
typedef NeonErrorCallback = void Function(
    Object error, StackTrace stackTrace);

/// Defines how errors are handled based on the environment.
enum NeonErrorStrategy {
  crash,
  recoverAndLog,
  configurable,
}

/// Handles errors in the Neon framework with environment-aware strategies.
class NeonErrorHandler {
  /// The current environment used to determine error strategy.
  final NeonEnvironment environment;
  NeonErrorCallback? _customHandler;
  final List<NeonErrorRecord> _errorLog = [];

  /// Creates an error handler for the given [environment].
  NeonErrorHandler({
    this.environment = NeonEnvironment.development,
  });

  /// Returns an unmodifiable list of recorded errors.
  List<NeonErrorRecord> get errorLog => List.unmodifiable(_errorLog);

  /// Sets a custom error handler callback.
  void setCustomHandler(NeonErrorCallback handler) {
    _customHandler = handler;
  }

  /// Returns the error strategy based on the current environment.
  NeonErrorStrategy get strategy {
    switch (environment) {
      case NeonEnvironment.development:
        return NeonErrorStrategy.crash;
      case NeonEnvironment.staging:
        return NeonErrorStrategy.recoverAndLog;
      case NeonEnvironment.production:
        return NeonErrorStrategy.recoverAndLog;
    }
  }

  /// Handles an error by logging it and applying the current strategy.
  void handleError(Object error, StackTrace stackTrace) {
    final record = NeonErrorRecord(
      error: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      environment: environment,
    );
    _errorLog.add(record);

    if (_customHandler != null) {
      _customHandler!(error, stackTrace);
      return;
    }

    switch (strategy) {
      case NeonErrorStrategy.crash:
        _logError(record);
        throw error;
      case NeonErrorStrategy.recoverAndLog:
        _logError(record);
        break;
      case NeonErrorStrategy.configurable:
        _logError(record);
        break;
    }
  }

  void _logError(NeonErrorRecord record) {
    final buffer = StringBuffer()
      ..writeln('[Neon Error] ${record.timestamp}')
      ..writeln('Environment: ${record.environment.name}')
      ..writeln('Error: ${record.error}')
      ..writeln('Stack Trace:')
      ..writeln(record.stackTrace);

    if (environment == NeonEnvironment.development) {
      // ignore: avoid_print
      print(buffer.toString());
    }
  }

  /// Clears all recorded error logs.
  void clearLog() {
    _errorLog.clear();
  }
}

/// A record of a single error occurrence with metadata.
class NeonErrorRecord {
  /// The error object that was caught.
  final Object error;

  /// The stack trace at the time of the error.
  final StackTrace stackTrace;

  /// The time the error occurred.
  final DateTime timestamp;

  /// The environment in which the error occurred.
  final NeonEnvironment environment;

  /// Creates an error record with the given details.
  const NeonErrorRecord({
    required this.error,
    required this.stackTrace,
    required this.timestamp,
    required this.environment,
  });

  @override
  String toString() =>
      'NeonErrorRecord(${error.runtimeType}: $error at $timestamp)';
}

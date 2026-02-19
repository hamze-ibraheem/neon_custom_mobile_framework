/// Represents the possible states of the Neon application lifecycle.
enum NeonLifecycleState {
  created,
  initialized,
  running,
  paused,
  resumed,
  disposed,
}

/// Interface for observing lifecycle events in a Neon application.
abstract class NeonLifecycleObserver {
  /// Called when the application is initialized.
  void onInit() {}

  /// Called when the application is paused.
  void onPause() {}

  /// Called when the application is resumed.
  void onResume() {}

  /// Called when the application is disposed.
  void onDispose() {}

  /// Called when a hot reload is triggered.
  void onHotReload() {}
}

/// Manages application lifecycle state and notifies registered observers.
class NeonLifecycleManager {
  NeonLifecycleState _state = NeonLifecycleState.created;
  final List<NeonLifecycleObserver> _observers = [];

  /// The current lifecycle state.
  NeonLifecycleState get state => _state;

  /// Registers an observer to receive lifecycle callbacks.
  void addObserver(NeonLifecycleObserver observer) {
    _observers.add(observer);
  }

  /// Removes a previously registered observer.
  void removeObserver(NeonLifecycleObserver observer) {
    _observers.remove(observer);
  }

  /// Initializes the lifecycle and notifies all observers.
  void init() {
    _state = NeonLifecycleState.initialized;
    for (final observer in _observers) {
      observer.onInit();
    }
  }

  /// Marks the lifecycle state as running.
  void markRunning() {
    _state = NeonLifecycleState.running;
  }

  /// Pauses the lifecycle if currently running or resumed.
  void pause() {
    if (_state == NeonLifecycleState.running ||
        _state == NeonLifecycleState.resumed) {
      _state = NeonLifecycleState.paused;
      for (final observer in _observers) {
        observer.onPause();
      }
    }
  }

  /// Resumes the lifecycle from a paused state.
  void resume() {
    if (_state == NeonLifecycleState.paused) {
      _state = NeonLifecycleState.resumed;
      for (final observer in _observers) {
        observer.onResume();
      }
    }
  }

  /// Disposes the lifecycle manager and clears all observers.
  void dispose() {
    _state = NeonLifecycleState.disposed;
    for (final observer in _observers) {
      observer.onDispose();
    }
    _observers.clear();
  }

  /// Triggers a hot reload notification to all observers.
  void hotReload() {
    for (final observer in _observers) {
      observer.onHotReload();
    }
  }
}

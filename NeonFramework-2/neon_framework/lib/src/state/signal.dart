typedef VoidCallback = void Function();

abstract class _Reactive {
  final Set<NeonComputed> _dependentComputeds = {};
  final Set<NeonEffect> _dependentEffects = {};

  void _addDependentComputed(NeonComputed computed) {
    _dependentComputeds.add(computed);
  }

  void _removeDependentComputed(NeonComputed computed) {
    _dependentComputeds.remove(computed);
  }

  void _addDependentEffect(NeonEffect effect) {
    _dependentEffects.add(effect);
  }

  void _removeDependentEffect(NeonEffect effect) {
    _dependentEffects.remove(effect);
  }

  void _trackRead() {
    final tracker = _NeonDependencyTracker.current;
    if (tracker != null) {
      tracker._trackedReactives.add(this);
    }
  }

  void _notifyDependents() {
    for (final computed in Set<NeonComputed>.from(_dependentComputeds)) {
      computed._markDirty();
    }
    for (final effect in Set<NeonEffect>.from(_dependentEffects)) {
      effect._run();
    }
  }

  void _clearDependents() {
    _dependentComputeds.clear();
    _dependentEffects.clear();
  }
}

/// A reactive signal that holds a mutable value and notifies listeners on change.
class NeonSignal<T> extends _Reactive {
  T _value;
  final List<VoidCallback> _listeners = [];
  bool _disposed = false;

  /// Creates a signal with the given initial value.
  NeonSignal(this._value);

  /// The current value; reading this tracks the signal as a dependency.
  T get value {
    _trackRead();
    return _value;
  }

  /// Sets the signal's value and notifies listeners if changed.
  set value(T newValue) {
    if (_disposed) {
      throw StateError('Cannot set value on a disposed signal.');
    }
    if (identical(_value, newValue)) return;
    _value = newValue;
    _notify();
  }

  /// Reads the current value without tracking as a dependency.
  T peek() => _value;

  /// Updates the value using a function that receives the current value.
  void update(T Function(T current) updater) {
    value = updater(_value);
  }

  /// Adds a listener that is called when the value changes.
  void listen(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Removes a previously added listener.
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
    _notifyDependents();
  }

  /// Disposes the signal, clearing all listeners and dependencies.
  void dispose() {
    _disposed = true;
    _listeners.clear();
    _clearDependents();
  }

  /// Whether this signal has been disposed.
  bool get isDisposed => _disposed;

  /// The number of currently registered listeners.
  int get listenerCount => _listeners.length;

  @override
  String toString() => 'NeonSignal<$T>($_value)';
}

/// A computed reactive value derived from other reactive sources.
class NeonComputed<T> extends _Reactive {
  final T Function() _compute;
  T? _cachedValue;
  bool _dirty = true;
  final Set<_Reactive> _dependencies = {};
  final List<VoidCallback> _listeners = [];
  bool _disposed = false;

  /// Creates a computed value from the given computation function.
  NeonComputed(this._compute) {
    _recompute();
  }

  /// The current computed value; recomputes if dirty and tracks as a dependency.
  T get value {
    _trackRead();
    if (_dirty) {
      _recompute();
    }
    return _cachedValue as T;
  }

  /// Reads the current computed value without tracking as a dependency.
  T peek() {
    if (_dirty) {
      _recompute();
    }
    return _cachedValue as T;
  }

  /// Adds a listener that is called when the computed value changes.
  void listen(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Removes a previously added listener.
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _recompute() {
    for (final dep in _dependencies) {
      dep._removeDependentComputed(this);
    }
    _dependencies.clear();

    final tracker = _NeonDependencyTracker();
    _NeonDependencyTracker._stack.add(tracker);

    try {
      _cachedValue = _compute();
    } finally {
      _NeonDependencyTracker._stack.removeLast();
    }

    _dependencies.addAll(tracker._trackedReactives);
    for (final dep in _dependencies) {
      dep._addDependentComputed(this);
    }

    _dirty = false;
  }

  void _markDirty() {
    if (_disposed) return;
    _dirty = true;
    final oldValue = _cachedValue;
    _recompute();
    if (!identical(oldValue, _cachedValue)) {
      for (final listener in List<VoidCallback>.from(_listeners)) {
        listener();
      }
      _notifyDependents();
    }
  }

  /// Disposes the computed value, clearing dependencies and listeners.
  void dispose() {
    _disposed = true;
    for (final dep in _dependencies) {
      dep._removeDependentComputed(this);
    }
    _dependencies.clear();
    _listeners.clear();
    _clearDependents();
  }

  /// Whether this computed value has been disposed.
  bool get isDisposed => _disposed;

  @override
  String toString() => 'NeonComputed<$T>(${peek()})';
}

/// A reactive side effect that re-runs when its dependencies change.
class NeonEffect {
  final void Function() _fn;
  final Set<_Reactive> _dependencies = {};
  bool _disposed = false;

  /// Creates an effect that immediately runs the given function and tracks dependencies.
  NeonEffect(this._fn) {
    _run();
  }

  void _run() {
    if (_disposed) return;

    for (final dep in _dependencies) {
      dep._removeDependentEffect(this);
    }
    _dependencies.clear();

    final tracker = _NeonDependencyTracker();
    _NeonDependencyTracker._stack.add(tracker);

    try {
      _fn();
    } finally {
      _NeonDependencyTracker._stack.removeLast();
    }

    _dependencies.addAll(tracker._trackedReactives);
    for (final dep in _dependencies) {
      dep._addDependentEffect(this);
    }
  }

  /// Disposes the effect, stopping future re-runs.
  void dispose() {
    _disposed = true;
    for (final dep in _dependencies) {
      dep._removeDependentEffect(this);
    }
    _dependencies.clear();
  }

  /// Whether this effect has been disposed.
  bool get isDisposed => _disposed;
}

class _NeonDependencyTracker {
  static final List<_NeonDependencyTracker> _stack = [];
  final Set<_Reactive> _trackedReactives = {};

  static _NeonDependencyTracker? get current =>
      _stack.isEmpty ? null : _stack.last;
}

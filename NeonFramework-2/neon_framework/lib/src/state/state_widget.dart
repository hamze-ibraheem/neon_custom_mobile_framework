import 'package:neon_framework/src/state/signal.dart';
import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';

/// Mixin that integrates reactive signals with stateful widgets.
mixin SignalMixin<T extends StatefulWidget> on NeonState<T> {
  final Map<NeonSignal, VoidCallback> _activeSubscriptions = {};
  final Set<NeonSignal> _currentBuildSignals = {};

  /// Subscribes to a signal and returns its current value, triggering rebuilds on change.
  S watch<S>(NeonSignal<S> signal) {
    _currentBuildSignals.add(signal);

    if (!_activeSubscriptions.containsKey(signal)) {
      void listener() {
        if (mounted) {
          setState(() {});
        }
      }
      signal.listen(listener);
      _activeSubscriptions[signal] = listener;
    }

    return signal.value;
  }

  /// Reads a signal's value without subscribing to changes.
  S read<S>(NeonSignal<S> signal) {
    return signal.peek();
  }

  /// Removes subscriptions to signals no longer used in the current build.
  void cleanupStaleSubscriptions() {
    final stale = _activeSubscriptions.keys
        .where((s) => !_currentBuildSignals.contains(s))
        .toList();
    for (final signal in stale) {
      final listener = _activeSubscriptions.remove(signal);
      if (listener != null) {
        signal.removeListener(listener);
      }
    }
    _currentBuildSignals.clear();
  }

  @override
  NeonWidget build(NeonBuildContext context) {
    _currentBuildSignals.clear();
    final result = buildWithSignals(context);
    cleanupStaleSubscriptions();
    return result;
  }

  /// Builds the widget tree with access to watched signals.
  NeonWidget buildWithSignals(NeonBuildContext context);

  @override
  void dispose() {
    for (final entry in _activeSubscriptions.entries) {
      entry.key.removeListener(entry.value);
    }
    _activeSubscriptions.clear();
    _currentBuildSignals.clear();
    super.dispose();
  }
}

/// Provides a signal to descendant widgets via the build context.
class NeonSignalProvider<T> {
  final NeonSignal<T> signal;
  final String? key;

  const NeonSignalProvider({required this.signal, this.key});

  /// Injects this signal into the given build context.
  void provideToContext(NeonBuildContext context) {
    context.provide<NeonSignal<T>>(signal);
  }

  /// Retrieves a signal of the given type from the build context.
  static NeonSignal<T>? of<T>(NeonBuildContext context) {
    return context.findAncestor<NeonSignal<T>>();
  }
}

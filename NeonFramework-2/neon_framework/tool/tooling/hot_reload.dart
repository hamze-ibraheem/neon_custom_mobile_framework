import 'dart:async';
import 'dart:io';
import 'package:watcher/watcher.dart';
import 'package:path/path.dart' as p;

enum HotReloadMode {
  ui,
  statePreserving,
  full;

  static HotReloadMode fromString(String value) {
    switch (value) {
      case 'ui':
        return HotReloadMode.ui;
      case 'state-preserving':
        return HotReloadMode.statePreserving;
      case 'full':
        return HotReloadMode.full;
      default:
        return HotReloadMode.statePreserving;
    }
  }
}

enum HotReloadEventType {
  uiReload,
  statePreservingReload,
  fullReload,
  error,
}

class HotReloadEvent {
  final HotReloadEventType type;
  final String description;
  final List<String> changedFiles;
  final DateTime timestamp;
  final Duration? reloadDuration;

  HotReloadEvent({
    required this.type,
    required this.description,
    this.changedFiles = const [],
    DateTime? timestamp,
    this.reloadDuration,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'HotReloadEvent($type, $description)';
}

class HotReloadEngine {
  final String projectPath;
  final List<String> watchPaths;
  final HotReloadMode mode;
  final void Function(HotReloadEvent)? onReload;

  final List<HotReloadEvent> _history = [];
  final List<DirectoryWatcher> _watchers = [];
  final List<StreamSubscription> _subscriptions = [];
  bool _isRunning = false;
  Timer? _debounceTimer;
  final Set<String> _pendingChanges = {};

  static const _debounceDelay = Duration(milliseconds: 300);

  HotReloadEngine({
    required this.projectPath,
    required this.watchPaths,
    this.mode = HotReloadMode.statePreserving,
    this.onReload,
  });

  bool get isRunning => _isRunning;
  List<HotReloadEvent> get history => List.unmodifiable(_history);

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    for (final watchPath in watchPaths) {
      final fullPath = p.join(projectPath, watchPath);
      final dir = Directory(fullPath);
      if (!dir.existsSync()) continue;

      final watcher = DirectoryWatcher(fullPath);
      _watchers.add(watcher);

      final sub = watcher.events.listen((event) {
        if (_shouldProcess(event.path)) {
          _pendingChanges.add(event.path);
          _scheduleReload();
        }
      });
      _subscriptions.add(sub);
    }
  }

  void stop() {
    _isRunning = false;
    _debounceTimer?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _watchers.clear();
    _pendingChanges.clear();
  }

  void _scheduleReload() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, _processChanges);
  }

  void _processChanges() {
    if (_pendingChanges.isEmpty) return;

    final changedFiles = List<String>.from(_pendingChanges);
    _pendingChanges.clear();

    final stopwatch = Stopwatch()..start();
    final reloadType = _determineReloadType(changedFiles);

    final event = HotReloadEvent(
      type: reloadType,
      description: _describeReload(reloadType, changedFiles),
      changedFiles: changedFiles,
      reloadDuration: stopwatch.elapsed,
    );

    _history.add(event);
    onReload?.call(event);
  }

  HotReloadEventType _determineReloadType(List<String> changedFiles) {
    if (mode == HotReloadMode.full) {
      return HotReloadEventType.fullReload;
    }

    final hasStructuralChange = changedFiles.any(_isStructuralChange);

    if (hasStructuralChange) {
      return HotReloadEventType.fullReload;
    }

    if (mode == HotReloadMode.ui) {
      return HotReloadEventType.uiReload;
    }

    return HotReloadEventType.statePreservingReload;
  }

  bool _isStructuralChange(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return true;

      final content = file.readAsStringSync();

      if (content.contains('class ') && content.contains('extends')) {
        final hasNewClass = RegExp(r'class\s+\w+\s+extends\s+(?:Stateful|Stateless)Widget')
            .hasMatch(content);
        if (hasNewClass) return false;
      }

      if (content.contains('import ') || content.contains('part ')) {
        return true;
      }

      return false;
    } catch (_) {
      return true;
    }
  }

  bool _shouldProcess(String path) {
    if (!path.endsWith('.dart')) return false;
    if (path.contains('.dart_tool')) return false;
    if (path.contains('build/')) return false;
    if (path.endsWith('_test.dart')) return false;
    return true;
  }

  String _describeReload(HotReloadEventType type, List<String> files) {
    final fileCount = files.length;
    final fileDesc = fileCount == 1
        ? p.basename(files.first)
        : '$fileCount files';

    switch (type) {
      case HotReloadEventType.uiReload:
        return 'UI reload: $fileDesc changed';
      case HotReloadEventType.statePreservingReload:
        return 'State-preserving reload: $fileDesc changed';
      case HotReloadEventType.fullReload:
        return 'Full reload: structural changes in $fileDesc';
      case HotReloadEventType.error:
        return 'Reload error in $fileDesc';
    }
  }
}

class HotReloadSession {
  final HotReloadEngine engine;
  final DateTime startedAt;
  int _reloadCount = 0;

  HotReloadSession({required this.engine})
      : startedAt = DateTime.now();

  int get reloadCount => _reloadCount;
  Duration get uptime => DateTime.now().difference(startedAt);

  void recordReload() {
    _reloadCount++;
  }

  Map<String, dynamic> get stats => {
    'uptime_seconds': uptime.inSeconds,
    'reload_count': _reloadCount,
    'mode': engine.mode.name,
    'is_running': engine.isRunning,
  };
}

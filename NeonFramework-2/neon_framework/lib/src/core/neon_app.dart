import 'dart:convert';
import 'dart:io';

import 'environment.dart';
import 'error_handler.dart';
import 'lifecycle.dart';
import 'feature_options.dart';
import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/widget_tree.dart';
import 'package:neon_framework/src/widgets/badge.dart';
import 'package:neon_framework/src/widgets/chip.dart';
import 'package:neon_framework/src/widgets/selection_controls.dart';
import 'package:neon_framework/src/widgets/slider.dart';
import 'package:neon_framework/src/widgets/button.dart';
import 'package:neon_framework/src/widgets/text.dart';
import 'package:neon_framework/src/widgets/container.dart';
import 'package:neon_framework/src/widgets/primitives.dart';
import 'package:neon_framework/src/widgets/navigation.dart';
import 'package:neon_framework/src/widgets/segmented_button.dart';
import 'package:neon_framework/src/widgets/card.dart';
import 'package:neon_framework/src/widgets/dialog.dart';
import 'package:neon_framework/src/widgets/bottom_sheet.dart';
import 'package:neon_framework/src/widgets/search_bar.dart';
import 'package:neon_framework/src/widgets/text_field.dart';
import 'package:neon_framework/src/widgets/menu.dart';
import 'package:neon_framework/src/widgets/list_tile.dart';
import 'package:neon_framework/src/widgets/progress_indicator.dart';
import 'package:neon_framework/src/widgets/tooltip.dart';
import 'package:neon_framework/src/widgets/snack_bar.dart';
import 'package:neon_framework/src/widgets/scroll_view.dart';
import 'package:neon_framework/src/widgets/tree_diff.dart';

class NeonApp {
  static final Map<String, NeonState> globalStateStore = {};
  static NeonApp? _instance;

  static NeonApp get instance {
    if (_instance == null) {
      throw StateError(
          'NeonApp has not been initialized. Call NeonApp.run() first.');
    }
    return _instance!;
  }

  final NeonWidget root;
  final NeonConfig config;
  late final NeonLifecycleManager _lifecycleManager;
  late final NeonErrorHandler _errorHandler;
  late final NeonWidgetTree _widgetTree;
  late final NeonBuildContext _rootContext;
  late final NeonFeatureOptionsManager _featureOptionsManager;
  bool _isRunning = false;
  HttpServer? _server;
  int _currentRevision = 1;
  Map<String, dynamic>? _lastTreeSnapshot;

  /// The feature options manager for runtime feature toggling.
  NeonFeatureOptionsManager get featureOptionsManager => _featureOptionsManager;

  /// The widget tree managed by this application.
  NeonWidgetTree get widgetTree => _widgetTree;

  /// The port the server is bound to.
  int get port => _server?.port ?? 0;

  /// The current UI revision number.
  int get currentRevision => _currentRevision;

  /// The last serialized widget tree snapshot.
  Map<String, dynamic>? get lastTreeSnapshot => _lastTreeSnapshot;

  NeonApp._({
    required this.root,
    required this.config,
  }) {
    _lifecycleManager = NeonLifecycleManager();
    _errorHandler = NeonErrorHandler(environment: config.environment);
    _widgetTree = NeonWidgetTree();
    _rootContext = NeonBuildContext(config: config);
    _featureOptionsManager = NeonFeatureOptionsManager(config.featureOptions);
  }

  static void run(
    NeonWidget rootWidget, {
    NeonConfig config = const NeonConfig(),
  }) {
    if (_instance != null && _instance!._isRunning) {
      throw StateError('NeonApp is already running.');
    }

    _instance = NeonApp._(root: rootWidget, config: config);

    try {
      _instance!._start();
    } catch (e, st) {
      _instance!._errorHandler.handleError(e, st);
    }
  }

  Future<void> _start() async {
    _lifecycleManager.init();
    _isRunning = true;
    _lifecycleManager.markRunning();

    // 1. Build the tree
    _widgetTree.buildTree(root, _rootContext);
    _currentRevision = 1;
    _lastTreeSnapshot = _widgetTree.root?.toJson() ?? {};

    // 2. Print the status banner
    _printBanner();

    // 3. ✅ FORCE PRINT THE TREE TO CONSOLE
    print('\n═══════════════ 🖥️  NEON RENDER FRAME ═══════════════');
    _widgetTree.printTree();
    print('═══════════════════════════════════════════════════════\n');

// ✅ 3. Start UI Server (The Bridge)
    int bindPort =
        int.tryParse(Platform.environment['PORT'] ?? '') ?? config.port;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, bindPort,
          shared: true);
    } catch (e) {
      if (e is SocketException &&
          (e.osError?.errorCode == 48 || e.osError?.errorCode == 98)) {
        // Port already in use, try auto-assign
        print(
            '⚠️  Port $bindPort is busy, auto-assigning an available port...');
        _server =
            await HttpServer.bind(InternetAddress.anyIPv4, 0, shared: true);
        bindPort = _server!.port;
      } else {
        rethrow;
      }
    }
    print('📡 Neon UI Server running on http://0.0.0.0:$bindPort');

    _server!.listen((HttpRequest request) async {
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers
          .add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      request.response.headers
          .add('Access-Control-Allow-Headers', 'Content-Type');
      request.response.headers
          .add('Cache-Control', 'no-cache, no-store, must-revalidate');

      if (request.method == 'OPTIONS') {
        request.response
          ..statusCode = HttpStatus.ok
          ..close();
        return;
      }

      if (request.uri.path == '/favicon.ico') {
        request.response
          ..statusCode = HttpStatus.noContent
          ..close();
        return;
      }

      // ✅ HANDLE ACTIONS (Button Clicks)
      if (request.method == 'POST' && request.uri.path == '/action') {
        final content = await utf8.decoder.bind(request).join();
        final params = jsonDecode(content) as Map<String, dynamic>;

        final targetId = params['id'] ?? params['actionId'];
        final index = params['index'] as int?;
        final value = params['value'];
        final start = params['start'] as double?;
        final end = params['end'] as double?;

        print('\n📥 RECEIVED ACTION 📥');
        print('  Target ID: $targetId');
        print('  Index:     $index');
        print('  Value:     $value');
        print('  Start/End: $start / $end');
        print('  Params:    $params');

        final element = _findElementById(_widgetTree.root, targetId);

        if (element != null) {
          final widget = element.sourceWidget;

          if (widget is Button) {
            print('✅ Button found! Executing tap()...');
            widget.tap();
          } else if (widget is NavigationBar) {
            print('✅ NavigationBar found! Selecting index $index');
            if (index != null) widget.onDestinationSelected?.call(index);
          } else if (widget is TabBar) {
            print('✅ TabBar found! Selecting index $index');
            if (index != null) widget.onTap?.call(index);
          } else if (widget is SegmentedButton) {
            print('✅ SegmentedButton found! Selecting index $index');
            if (index != null) widget.onSelectionChanged?.call(index);
          } else if (widget is NavigationDrawer) {
            print('✅ NavigationDrawer found! Selecting index $index');
            if (index != null) widget.onDestinationSelected?.call(index);
          } else if (widget is NavigationRail) {
            print('✅ NavigationRail found! Selecting index $index');
            if (index != null) widget.onDestinationSelected?.call(index);
          } else if (widget is ActionChip) {
            widget.onPressed?.call();
          } else if (widget is FilterChip) {
            if (value is bool) widget.onSelected?.call(value);
          } else if (widget is ChoiceChip) {
            if (value is bool) widget.onSelected?.call(value);
          } else if (widget is InputChip) {
            if (params['action'] == 'delete') {
              widget.onDeleted?.call();
            } else {
              widget.onPressed?.call();
            }
          } else if (widget is Switch) {
            final newVal =
                value is bool ? value : (value == 'true' || value == 1);
            print('✅ Switch found! New value: $newVal');
            widget.onChanged?.call(newVal);
          } else if (widget is Checkbox) {
            final newVal =
                value is bool? ? value : (value == 'true' || value == 1);
            print('✅ Checkbox found! New value: $newVal');
            widget.onChanged?.call(newVal);
          } else if (widget is Radio) {
            print('✅ Radio found! Value: ${widget.value}');
            widget.selectValue();
          } else if (widget is Slider) {
            final newVal = value is num
                ? value.toDouble()
                : double.tryParse(value.toString()) ?? 0.0;
            print('✅ Slider found! New value: $newVal');
            widget.onChanged?.call(newVal);
          } else if (widget is RangeSlider) {
            if (start != null && end != null) {
              print('✅ RangeSlider found! Range: $start - $end');
              widget.onChanged?.call(NeonRangeValues(start, end));
            }
          } else if (widget is TextField) {
            final text = value?.toString() ?? '';
            final action = params['action']?.toString();
            print('✅ TextField found! Value: $text, Action: $action');
            if (action == 'submit') {
              widget.onSubmitted?.call(text);
            } else {
              widget.onChanged?.call(text);
            }
          } else if (widget is SearchBar) {
            final text = value?.toString() ?? '';
            final action = params['action']?.toString();
            print('✅ SearchBar found! Value: $text, Action: $action');
            if (action == 'submit') {
              widget.onSubmitted?.call(text);
            } else {
              widget.onChanged?.call(text);
            }
          } else if (widget is SearchAnchor) {
            final text = value?.toString() ?? '';
            final action = params['action']?.toString();
            print('✅ SearchAnchor found! Value: $text, Action: $action');
            if (action == 'toggle') {
              widget.onToggle?.call();
            } else {
              widget.onSearch?.call(text);
            }
          } else if (widget is Dialog) {
            print('✅ Dialog found! Action: dismiss');
            widget.onDismiss?.call();
          } else if (widget is BottomSheet) {
            print('✅ BottomSheet found! Action: dismiss');
            widget.onDismiss?.call();
          } else if (widget is Card) {
            print('✅ Card found! Tap');
            widget.onTap?.call();
          } else if (widget is MenuAnchor) {
            final action = params['action']?.toString();
            print('✅ MenuAnchor found! Action: $action, Index: $index');
            if (action == 'open') {
              widget.onOpen?.call();
            } else if (action == 'close') {
              widget.onClose?.call();
            } else if (index != null && index < widget.menuItems.length) {
              widget.menuItems[index].onPressed?.call();
            }
          } else if (widget is MenuBar) {
            print('✅ MenuBar found! Index: $index');
            if (index != null) {
              widget.onItemSelected?.call(index);
              if (index < widget.items.length) {
                widget.items[index].onPressed?.call();
              }
            }
          } else if (widget is ListTile) {
            print('✅ ListTile found! Tap');
            widget.onTap?.call();
          } else if (widget is SnackBar) {
            final action = params['action']?.toString();
            print('✅ SnackBar found! Action: $action');
            if (action == 'action') {
              widget.onAction?.call();
            } else {
              widget.onDismiss?.call();
            }
          } else {
            print('⚠️  Widget type not recognized: ${widget.runtimeType}');
          }

          // ⏳ Wait for setState to complete (microtask queue)
          await Future.delayed(Duration.zero);

          print('🔄 Rebuilding tree after action...');
          _widgetTree.buildTree(root, _rootContext);

          print('\n═════════════ 🔄 NEON REBUILD FRAME ═══════════════');
          _widgetTree.printTree();
          print('═══════════════════════════════════════════════════════\n');
        } else {
          print('❌ Widget not found for ID: $targetId');
        }

        final newJsonTree = _widgetTree.root?.toJson() ?? {};
        final bool diffingEnabled =
            _featureOptionsManager.current.diffing.enabled &&
            config.enableDiffing &&
            !config.featureFlags.isEnabled('disable_diffing');

        final dynamic rawClientRev = params['clientRevision'] ??
            request.headers.value('X-Neon-Client-Revision');
        final int? clientRevision = rawClientRev is int
            ? rawClientRev
            : int.tryParse(rawClientRev?.toString() ?? '');

        final dynamic rawPatchVer = params['patchVersion'] ??
            request.headers.value('X-Neon-Patch-Version');
        final int patchVersion = rawPatchVer is int
            ? rawPatchVer
            : (int.tryParse(rawPatchVer?.toString() ?? '') ?? 1);

        final bool isRecovery = params['recovery'] == true ||
            request.headers.value('X-Neon-Recovery') == 'true';

        _currentRevision++;
        final int newRevision = _currentRevision;
        final int expectedBaseRevision = newRevision - 1;

        bool shouldSendPatch = false;
        WidgetTreePatch? patch;

        if (diffingEnabled &&
            !isRecovery &&
            patchVersion == 1 &&
            clientRevision != null &&
            _lastTreeSnapshot != null) {
          if (clientRevision == expectedBaseRevision) {
            patch = NeonWidgetTreeDiff.diff(
              _lastTreeSnapshot!,
              newJsonTree,
              revision: newRevision,
              baseRevision: clientRevision,
            );
            shouldSendPatch = true;
          } else {
            print(
                '⚠️ Revision mismatch: client=$clientRevision, expected=$expectedBaseRevision. Returning full tree fallback.');
          }
        }

        if (shouldSendPatch && patch != null) {
          _lastTreeSnapshot = newJsonTree;
          final patchPayload = patch.toJson();
          print(
              '⚡ Sending patch update (rev: $newRevision, base: $clientRevision, ops: ${patch.operations.length})');
          request.response
            ..headers.contentType = ContentType.json
            ..headers.add('X-Neon-Revision', '$newRevision')
            ..headers.add('X-Neon-Response-Type', 'patch')
            ..write(jsonEncode(patchPayload))
            ..close();
        } else {
          _lastTreeSnapshot = newJsonTree;
          final fullPayload = {
            'type': 'full',
            'version': 1,
            'revision': newRevision,
            'tree': newJsonTree,
            'root': newJsonTree,
          };
          if (!diffingEnabled) {
            fullPayload['fallbackReason'] = 'diffing_disabled';
          } else if (isRecovery) {
            fullPayload['fallbackReason'] = 'recovery_requested';
          } else if (_lastTreeSnapshot == null) {
            fullPayload['fallbackReason'] = 'no_previous_snapshot';
          } else if (clientRevision != null && clientRevision != expectedBaseRevision) {
            fullPayload['fallbackReason'] = 'revision_mismatch';
          }
          print('🌳 Sending full tree (rev: $newRevision)');
          request.response
            ..headers.contentType = ContentType.json
            ..headers.add('X-Neon-Revision', '$newRevision')
            ..headers.add('X-Neon-Response-Type', 'full')
            ..write(jsonEncode(fullPayload))
            ..close();
        }
        return;
      }

      // ✅ HANDLE REMOTE WIDGET DEMO
      if (request.method == 'GET' && request.uri.path == '/remote-demo') {
        print('🔗 Remote Bridge request for /remote-demo');
        final demoWidget = Container(
          color: NeonColor.green,
          width: 200,
          height: 100,
          child: const Text('I am a Remote View!'),
        );

        // Temporarily build a small tree for this widget
        final remoteTree = NeonWidgetTree();
        remoteTree.buildTree(demoWidget, _rootContext);

        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(remoteTree.root?.toJson() ?? {}))
          ..close();
        return;
      }

      // ✅ FEATURE OPTIONS API: Get or update subsystem options at runtime
      if (request.uri.path == '/api/feature-options') {
        if (request.method == 'GET') {
          request.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(_featureOptionsManager.current.toJson()))
            ..close();
          return;
        } else if (request.method == 'POST') {
          final content = await utf8.decoder.bind(request).join();
          final json = jsonDecode(content) as Map<String, dynamic>;
          _featureOptionsManager.updateFromJson(json);
          request.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'success': true,
              'options': _featureOptionsManager.current.toJson(),
            }))
            ..close();
          return;
        }
      }

      // ✅ JSON API: Send the Tree as JSON
      if (request.method == 'GET' && request.uri.path == '/api/tree') {
        final jsonTree = _widgetTree.root?.toJson() ?? {};
        _lastTreeSnapshot = jsonTree;
        final responsePayload = {
          'type': 'full',
          'version': 1,
          'revision': _currentRevision,
          'tree': jsonTree,
          'root': jsonTree,
        };
        request.response
          ..headers.contentType = ContentType.json
          ..headers.add('X-Neon-Revision', '$_currentRevision')
          ..headers.add('X-Neon-Response-Type', 'full')
          ..write(jsonEncode(responsePayload))
          ..close();
        print('📲 Device requested UI Frame (Root, Revision: $_currentRevision)');
        return;
      }

      // ✅ DEFAULT: Serve HTML Web Renderer
      if (request.method == 'GET' &&
          (request.uri.path == '/' || request.uri.path == '')) {
        request.response
          ..headers.contentType = ContentType.html
          ..write(_getWebRendererHtml())
          ..close();
        print('🌐 Web Renderer served');
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not Found')
          ..close();
      }
    });
  }

  NeonElement? _findElementById(NeonElement? node, String? id) {
    if (node == null || id == null) return null;
    if (node.id == id) return node;
    for (final child in node.children) {
      final found = _findElementById(child, id);
      if (found != null) return found;
    }
    return null;
  }

  /// Whether the application is currently running.
  bool get isRunning => _isRunning;

  /// Pauses the application.
  void pause() {
    _lifecycleManager.pause();
  }

  /// Resumes the application.
  void resume() {
    _lifecycleManager.resume();
  }

  void _printBanner() {
    // ignore: avoid_print
    print('''
╔══════════════════════════════════════╗
║         Neon Framework v0.1.0        ║
║     Mobile-first · Dart-powered      ║
╚══════════════════════════════════════╝
  Environment : ${config.environment.name}
  Build Flavor: ${config.buildFlavor?.name ?? 'default'}
  Root Widget : ${root.runtimeType}
  Widget Tree : ${_widgetTree.nodeCount} nodes
  Status      : Running
''');
  }

  /// Resets the application instance, useful for testing.
  static void reset() {
    _instance?._currentRevision = 1;
    _instance?._lastTreeSnapshot = null;
    _instance?.dispose();
    _instance = null;
    globalStateStore.clear();
  }

  String _getWebRendererHtml() {
    return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Neon Framework</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f0f0f0;display:flex;justify-content:center;align-items:center;min-height:100vh}
#phone{width:390px;height:100vh;background:#fff;display:flex;flex-direction:column;box-shadow:0 0 40px rgba(0,0,0,.15);position:relative}
@media(max-width:420px){#phone{width:100%;box-shadow:none}}
#app-bar{background:#fff;padding:16px 20px;border-bottom:1px solid #e0e0e0;position:sticky;top:0;z-index:10}
#app-bar h1{font-size:28px;font-weight:700;color:#1a1a1a}
#app-bar .actions{position:absolute;right:16px;top:50%;transform:translateY(-50%);display:flex;gap:8px}
#content{flex:1;padding:16px;overflow-y:auto;background:#fafafa}
#nav-bar{display:flex;background:#fff;border-top:1px solid #e0e0e0;padding:8px 0 calc(12px + env(safe-area-inset-bottom,0px));flex-shrink:0;z-index:10;overflow-x:auto;overflow-y:hidden;-webkit-overflow-scrolling:touch;scrollbar-width:none;scroll-behavior:smooth}
#nav-bar::-webkit-scrollbar{display:none}
.nav-item{display:flex;flex-direction:column;align-items:center;gap:4px;cursor:pointer;padding:4px 12px;border-radius:16px;transition:background .2s,color .2s;border:none;background:none;font-family:inherit;min-width:64px;flex:0 0 auto;font-size:11px;-webkit-tap-highlight-color:transparent;touch-action:manipulation;user-select:none;position:relative}
.nav-item:hover{background:#f0f0f0}
.nav-item:active{background:#e0e0e0}
.nav-item.active{color:#6750A4}
.nav-item.active .nav-icon{background:#E8DEF8;border-radius:16px;padding:2px 16px}
.nav-item .nav-icon{font-size:20px;padding:2px 16px;transition:background .2s}
.nav-item .nav-label{font-size:12px;color:#666;white-space:nowrap}
.nav-item.active .nav-label{color:#6750A4;font-weight:600}

.n-text{color:#1a1a1a;line-height:1.4}
.n-column{display:flex;flex-direction:column}
.n-row{display:flex;flex-direction:row;align-items:center}
.n-row.space-evenly{justify-content:space-evenly}
.n-row.space-between{justify-content:space-between}
.n-row.center{justify-content:center}
.n-container{border-radius:12px;overflow:hidden}
.n-spacer{flex:1}
.n-badge{position:relative;display:inline-flex}
.n-badge .badge-label{position:absolute;top:-4px;right:-8px;background:#B3261E;color:#fff;font-size:11px;min-width:18px;height:18px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-weight:600}

.stat-card{border-radius:16px;padding:16px;text-align:center;min-width:90px}
.stat-card .stat-value{font-size:28px;font-weight:700;color:#fff}
.stat-card .stat-label{font-size:13px;color:rgba(255,255,255,.85);margin-top:4px}

.n-btn{border:none;padding:12px 24px;border-radius:20px;font-size:14px;font-weight:600;cursor:pointer;transition:all .15s;font-family:inherit}
.n-btn-filled{background:#6750A4;color:#fff}
.n-btn-filled:hover{background:#7965AF}
.n-btn-elevated{background:#fff;color:#6750A4;box-shadow:0 1px 3px rgba(0,0,0,.15)}
.n-btn-elevated:hover{box-shadow:0 2px 6px rgba(0,0,0,.2)}
.n-btn-outlined{background:transparent;color:#6750A4;border:1px solid #79747E}
.n-btn-outlined:hover{background:#F7F2FA}
.n-btn-text{background:transparent;color:#6750A4}
.n-btn-text:hover{background:#F7F2FA}
.n-btn-tonal{background:#E8DEF8;color:#1D192B}
.n-btn-tonal:hover{background:#D0BCFF}
.n-btn-fab{background:#E8DEF8;color:#21005D;width:56px;height:56px;border-radius:16px;font-size:24px;display:flex;align-items:center;justify-content:center;box-shadow:0 3px 6px rgba(0,0,0,.15)}
.n-btn-icon{background:transparent;border:none;width:40px;height:40px;border-radius:20px;font-size:20px;cursor:pointer;display:flex;align-items:center;justify-content:center}
.n-btn-icon:hover{background:#f0f0f0}

.n-chip{display:inline-flex;align-items:center;padding:6px 16px;border-radius:8px;font-size:14px;cursor:pointer;border:1px solid #79747E;background:transparent;transition:all .15s;font-family:inherit}
.n-chip.selected{background:#E8DEF8;border-color:#6750A4;color:#6750A4}
.n-chip:hover{background:#F7F2FA}

.n-segmented{display:flex;border:1px solid #79747E;border-radius:20px;overflow:hidden}
.n-segmented button{flex:1;padding:10px 16px;border:none;background:transparent;font-size:14px;cursor:pointer;font-weight:500;transition:all .15s;font-family:inherit}
.n-segmented button.active{background:#E8DEF8;color:#6750A4;font-weight:600}

.n-switch{position:relative;width:52px;height:32px;border-radius:16px;cursor:pointer;transition:all .2s;border:2px solid #79747E;background:#E7E0EC}
.n-switch.on{background:#6750A4;border-color:#6750A4}
.n-switch .knob{position:absolute;top:4px;left:4px;width:20px;height:20px;border-radius:50%;background:#79747E;transition:all .2s}
.n-switch.on .knob{left:24px;background:#fff}

.n-checkbox{width:20px;height:20px;border:2px solid #79747E;border-radius:4px;cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:14px;color:#fff;transition:all .15s}
.n-checkbox.checked{background:#6750A4;border-color:#6750A4}

.n-radio{width:20px;height:20px;border:2px solid #79747E;border-radius:50%;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .15s}
.n-radio.selected{border-color:#6750A4}
.n-radio.selected::after{content:'';width:10px;height:10px;border-radius:50%;background:#6750A4}

.n-slider{width:100%;margin:8px 0}
.n-slider input[type=range]{-webkit-appearance:none;width:100%;height:4px;background:#E7E0EC;border-radius:2px;outline:none}
.n-slider input[type=range]::-webkit-slider-thumb{-webkit-appearance:none;width:20px;height:20px;border-radius:50%;background:#6750A4;cursor:pointer}
.n-slider .slider-label{text-align:center;font-size:13px;color:#666;margin-top:4px}

.n-stack{position:relative}
.n-positioned{position:absolute}
.n-center{display:flex;align-items:center;justify-content:center}

.section-title{font-size:18px;font-weight:600;color:#1a1a1a;margin:16px 0 8px}
.activity-card{background:#F5F5F5;border-radius:12px;padding:14px;margin-top:4px}

.n-tabbar{display:flex;border-bottom:2px solid #E7E0EC;margin-bottom:12px}
.n-tabbar button{flex:1;padding:12px;border:none;background:transparent;font-size:14px;cursor:pointer;position:relative;color:#666;font-family:inherit}
.n-tabbar button.active{color:#6750A4;font-weight:600}
.n-tabbar button.active::after{content:'';position:absolute;bottom:-2px;left:25%;right:25%;height:3px;background:#6750A4;border-radius:2px}

#loading{display:flex;flex-direction:column;align-items:center;justify-content:center;height:100%;gap:12px}
#loading .spinner{width:40px;height:40px;border:3px solid #E7E0EC;border-top-color:#6750A4;border-radius:50%;animation:spin 1s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}

.n-card{border-radius:12px;padding:16px;margin-bottom:8px}
.n-card-elevated{background:#fff;box-shadow:0 1px 3px rgba(0,0,0,.12),0 1px 2px rgba(0,0,0,.08)}
.n-card-filled{background:#E7E0EC}
.n-card-outlined{background:#fff;border:1px solid #CAC4D0}

.n-dialog-overlay{position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,.4);display:flex;align-items:center;justify-content:center;z-index:100}
.n-dialog{background:#ECE6F0;border-radius:28px;padding:24px;min-width:280px;max-width:340px;box-shadow:0 8px 32px rgba(0,0,0,.25)}
.n-dialog-title{font-size:24px;font-weight:500;color:#1D1B20;margin-bottom:16px}
.n-dialog-content{font-size:14px;color:#49454F;line-height:1.5;margin-bottom:24px}
.n-dialog-actions{display:flex;justify-content:flex-end;gap:8px}
.n-dialog-fullscreen{position:fixed;top:0;left:0;right:0;bottom:0;background:#fff;z-index:100;display:flex;flex-direction:column}
.n-dialog-fullscreen .n-dialog-header{display:flex;align-items:center;padding:16px;border-bottom:1px solid #e0e0e0}

.n-bottomsheet-overlay{position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,.4);display:flex;align-items:flex-end;justify-content:center;z-index:100}
.n-bottomsheet{background:#ECE6F0;border-radius:28px 28px 0 0;padding:16px 24px 24px;min-height:200px;width:100%;max-width:390px}
.n-bottomsheet .drag-handle{width:32px;height:4px;background:#79747E;border-radius:2px;margin:0 auto 16px}

.n-textfield{margin-bottom:8px;position:relative}
.n-textfield input,.n-textfield textarea{width:100%;padding:16px 12px 8px;font-size:16px;font-family:inherit;border:none;outline:none;background:transparent}
.n-textfield-filled{background:#E7E0EC;border-radius:4px 4px 0 0;border-bottom:2px solid #49454F}
.n-textfield-filled:focus-within{border-bottom-color:#6750A4}
.n-textfield-outlined{background:transparent;border:1px solid #79747E;border-radius:4px}
.n-textfield-outlined:focus-within{border-color:#6750A4;border-width:2px}
.n-textfield label{position:absolute;top:8px;left:12px;font-size:12px;color:#49454F}
.n-textfield .helper{font-size:12px;color:#49454F;margin-top:4px;padding:0 12px}
.n-textfield .error-text{font-size:12px;color:#B3261E;margin-top:4px;padding:0 12px}

.n-searchbar{display:flex;align-items:center;background:#E7E0EC;border-radius:28px;padding:8px 16px;gap:8px}
.n-searchbar input{flex:1;border:none;outline:none;background:transparent;font-size:16px;font-family:inherit;padding:8px 0}
.n-searchbar .search-icon{color:#49454F;font-size:20px}

.n-menu-overlay{position:fixed;top:0;left:0;right:0;bottom:0;z-index:90}
.n-menu{background:#ECE6F0;border-radius:4px;box-shadow:0 2px 8px rgba(0,0,0,.15);min-width:180px;padding:4px 0;z-index:91;position:absolute}
.n-menu-item{padding:12px 16px;font-size:14px;cursor:pointer;display:flex;align-items:center;gap:12px;color:#1D1B20}
.n-menu-item:hover{background:#D0BCFF33}
.n-menu-item.disabled{color:#999;cursor:default}

.n-menubar{display:flex;background:#ECE6F0;border-radius:8px;padding:4px;gap:2px;margin-bottom:8px}
.n-menubar button{padding:8px 16px;border:none;background:transparent;font-size:14px;cursor:pointer;border-radius:4px;font-family:inherit}
.n-menubar button:hover{background:#D0BCFF33}
.n-menubar button.active{background:#E8DEF8;color:#6750A4;font-weight:600}

.n-listtile{display:flex;align-items:center;padding:8px 16px;gap:16px;cursor:pointer;border-radius:12px;transition:background .15s;min-height:56px}
.n-listtile:hover{background:rgba(0,0,0,.04)}
.n-listtile:active{background:rgba(0,0,0,.08)}
.n-listtile.selected{background:#E8DEF8}
.n-listtile.dense{min-height:40px;padding:4px 16px}
.n-listtile .lt-leading{flex-shrink:0;display:flex;align-items:center;justify-content:center;width:40px;height:40px;font-size:20px}
.n-listtile .lt-content{flex:1;min-width:0}
.n-listtile .lt-title{font-size:16px;color:#1D1B20;line-height:1.4}
.n-listtile .lt-subtitle{font-size:14px;color:#49454F;line-height:1.3;margin-top:2px}
.n-listtile .lt-trailing{flex-shrink:0;display:flex;align-items:center;font-size:14px;color:#49454F}

.n-linear-progress{width:100%;border-radius:2px;overflow:hidden;position:relative}
.n-linear-progress .track{width:100%;background:#E7E0EC}
.n-linear-progress .bar{height:100%;background:#6750A4;border-radius:0;transition:width .3s ease}
.n-linear-progress.indeterminate .bar{width:40%;animation:lp-slide 1.5s ease-in-out infinite}
@keyframes lp-slide{0%{transform:translateX(-100%)}50%{transform:translateX(150%)}100%{transform:translateX(-100%)}}

.n-circular-progress{display:inline-flex;align-items:center;justify-content:center;position:relative}
.n-circular-progress svg{transform:rotate(-90deg)}
.n-circular-progress .track-circle{fill:none}
.n-circular-progress .bar-circle{fill:none;stroke-linecap:round;transition:stroke-dashoffset .3s ease}
.n-circular-progress.indeterminate svg{animation:cp-spin 1.4s linear infinite}
@keyframes cp-spin{to{transform:rotate(270deg)}}

.n-tooltip-wrapper{position:relative;display:inline-flex}
.n-tooltip-wrapper .tooltip-text{position:absolute;background:#313033;color:#F4EFF4;padding:6px 12px;border-radius:4px;font-size:12px;white-space:nowrap;pointer-events:none;opacity:0;transition:opacity .15s;z-index:50;left:50%;transform:translateX(-50%)}
.n-tooltip-wrapper .tooltip-text.below{top:calc(100% + 8px)}
.n-tooltip-wrapper .tooltip-text.above{bottom:calc(100% + 8px)}
.n-tooltip-wrapper:hover .tooltip-text{opacity:1}

.n-snackbar{position:fixed;bottom:80px;left:50%;transform:translateX(-50%);background:#313033;color:#F4EFF4;padding:14px 16px;border-radius:4px;display:flex;align-items:center;gap:12px;min-width:280px;max-width:560px;box-shadow:0 3px 5px rgba(0,0,0,.2);z-index:200;animation:snack-in .2s ease-out}
.n-snackbar.floating{border-radius:8px;bottom:96px}
.n-snackbar .snack-content{flex:1;font-size:14px;line-height:1.4}
.n-snackbar .snack-action{color:#D0BCFF;font-weight:600;font-size:14px;background:none;border:none;cursor:pointer;padding:0 4px;font-family:inherit}
.n-snackbar .snack-close{color:#F4EFF4;background:none;border:none;cursor:pointer;font-size:18px;padding:0 4px;opacity:.7}
.n-snackbar .snack-close:hover{opacity:1}
@keyframes snack-in{from{opacity:0;transform:translateX(-50%) translateY(20px)}to{opacity:1;transform:translateX(-50%) translateY(0)}}

.n-scrollview{overflow:auto;-webkit-overflow-scrolling:touch}
.n-scrollview.horizontal{overflow-x:auto;overflow-y:hidden;display:flex}
.n-scrollview.vertical{overflow-y:auto;overflow-x:hidden}
.n-listview{display:flex;flex-direction:column}
.n-listview.horizontal{flex-direction:row;overflow-x:auto}
.n-listview.shrinkwrap{overflow:visible}
</style>
</head>
<body>
<div id="phone">
  <div id="app-bar"><h1>Loading...</h1></div>
  <div id="content"><div id="loading"><div class="spinner"></div><span>Connecting to Neon Engine...</span></div></div>
  <div id="nav-bar"></div>
</div>
<script>
const API=window.location.origin;
let currentRevision=0;
let tree=null;

async function fetchTree(){
  try{
    const r=await fetch(API+'/api/tree');
    const data=await r.json();
    if(data.type==='full'||data.tree||data.root){
      currentRevision=data.revision||1;
      tree=data.tree||data.root||data;
    }else{
      tree=data;
    }
    renderApp(tree);
  }catch(e){
    document.getElementById('content').innerHTML='<div style="color:red;padding:20px">Error: '+e.message+'</div>';
  }
}

let actionLock=false;
async function sendAction(id,params={}){
  if(actionLock)return;
  actionLock=true;
  try{
    const body=JSON.stringify({id,clientRevision:currentRevision,patchVersion:1,...params});
    const r=await fetch(API+'/action',{method:'POST',headers:{'Content-Type':'application/json'},body});
    const data=await r.json();
    if(data.type==='patch'){
      currentRevision=data.revision||(currentRevision+1);
      tree=applyPatchToTree(tree,data.operations||[]);
      renderApp(tree);
    }else if(data.type==='full'||data.tree||data.root){
      currentRevision=data.revision||(currentRevision+1);
      tree=data.tree||data.root||data;
      renderApp(tree);
    }else{
      tree=data;
      renderApp(tree);
    }
  }catch(e){
    console.error('Action error:',e);
    fetchTree();
  }
  finally{actionLock=false;}
}

function applyPatchToTree(root,operations){
  if(!operations||!Array.isArray(operations))return root;
  let targetRoot=root;
  for(const op of operations){
    if(!op.path||op.path==='/'||op.path===''){
      if(op.op==='replace'&&op.value){
        targetRoot=JSON.parse(JSON.stringify(op.value));
      }else if(op.op==='update'&&op.properties){
        for(const [k,v] of Object.entries(op.properties)){
          if(v===null)delete targetRoot[k];
          else targetRoot[k]=v;
        }
      }
      continue;
    }
    const segments=op.path.split('/').filter(s=>s.length>0);
    let current=targetRoot;
    for(let i=0;i<segments.length-1;i++){
      const seg=segments[i];
      if(Array.isArray(current)){
        current=current[parseInt(seg,10)];
      }else if(current&&typeof current==='object'){
        current=current[seg];
      }
    }
    const lastSeg=segments[segments.length-1];
    if(op.op==='update'&&op.properties){
      const target=Array.isArray(current)?current[parseInt(lastSeg,10)]:(current?current[lastSeg]:null);
      if(target&&typeof target==='object'){
        for(const [k,v] of Object.entries(op.properties)){
          if(v===null)delete target[k];
          else target[k]=v;
        }
      }
    }else if(op.op==='replace'&&op.value!==undefined){
      if(Array.isArray(current)){
        current[parseInt(lastSeg,10)]=JSON.parse(JSON.stringify(op.value));
      }else if(current&&typeof current==='object'){
        current[lastSeg]=JSON.parse(JSON.stringify(op.value));
      }
    }else if(op.op==='remove'){
      if(Array.isArray(current)){
        current.splice(parseInt(lastSeg,10),1);
      }else if(current&&typeof current==='object'){
        delete current[lastSeg];
      }
    }else if(op.op==='insert'&&op.value!==undefined){
      if(Array.isArray(current)){
        current.splice(parseInt(lastSeg,10),0,JSON.parse(JSON.stringify(op.value)));
      }
    }
  }
  return targetRoot;
}

function renderApp(node){
  if(!node)return;
  if(node.type==='full'&&(node.tree||node.root)){
    node=node.tree||node.root;
  }
  if(!node||!node.type)return;
  const appBar=document.getElementById('app-bar');
  const content=document.getElementById('content');
  const navBar=document.getElementById('nav-bar');
  
  appBar.innerHTML='';
  content.innerHTML='';
  navBar.innerHTML='';
  
  const children=node.children||[];
  for(const child of children){
    if(child.type==='AppBar'||child.sourceType==='AppBar'){
      renderAppBar(child,appBar);
    }else if(child.type==='NavigationBar'||child.sourceType==='NavigationBar'){
      renderNavBar(child,navBar);
    }else{
      content.appendChild(renderWidget(child));
    }
  }
}

function renderAppBar(node,container){
  let title='';
  const ch=node.children||[];
  if(ch.length>0){
    const first=ch[0];
    if(first.text)title=first.text;
    else if(first.children&&first.children[0]&&first.children[0].text)title=first.children[0].text;
  }
  if(node.title)title=node.title;
  const h1=document.createElement('h1');
  h1.textContent=title;
  container.appendChild(h1);
  
  const actions=node.actions||[];
  if(actions.length>0){
    const actDiv=document.createElement('div');
    actDiv.className='actions';
    for(const a of actions){
      actDiv.appendChild(renderWidget(a));
    }
    container.appendChild(actDiv);
  }
}

function renderNavBar(node,container){
  const dests=node.destinations||[];
  const selected=node.selectedIndex||0;
  const navId=node.id||'';
  dests.forEach((d,i)=>{
    const btn=document.createElement('button');
    btn.className='nav-item'+(i===selected?' active':'');
    btn.setAttribute('type','button');
    const iconSpan=document.createElement('span');
    iconSpan.className='nav-icon';
    const iconChildren=d.icon?.children||[];
    iconSpan.textContent=d.icon?.text||(iconChildren[0]?.text)||'';
    const labelSpan=document.createElement('span');
    labelSpan.className='nav-label';
    labelSpan.textContent=d.label||'';
    btn.appendChild(iconSpan);
    btn.appendChild(labelSpan);
    btn.addEventListener('pointerup',(e)=>{e.preventDefault();e.stopPropagation();sendAction(navId,{index:i});},{passive:false});
    container.appendChild(btn);
    if(i===selected){requestAnimationFrame(()=>btn.scrollIntoView({behavior:'smooth',block:'nearest',inline:'center'}));}
  });
}

function colorToCSS(c){
  if(!c&&c!==0)return null;
  const n=c>>>0;
  const a=((n>>24)&0xFF)/255;
  const r=(n>>16)&0xFF;
  const g=(n>>8)&0xFF;
  const b=n&0xFF;
  return 'rgba('+r+','+g+','+b+','+a.toFixed(2)+')';
}

function renderWidget(node){
  if(!node)return document.createTextNode('');
  const type=node.type||'';
  const src=node.sourceType||'';
  const children=node.children||[];

  if(type==='Text'||src==='Text'){
    const span=document.createElement('span');
    span.className='n-text';
    span.textContent=node.text||'';
    if(node.fontSize)span.style.fontSize=node.fontSize+'px';
    if(node.fontWeight==='bold')span.style.fontWeight='700';
    if(node.color)span.style.color=colorToCSS(node.color);
    return span;
  }

  if(type==='Column'||src==='Column'){
    const div=document.createElement('div');
    div.className='n-column';
    if(node.crossAxisAlignment==='start')div.style.alignItems='flex-start';
    if(node.crossAxisAlignment==='center')div.style.alignItems='center';
    div.style.gap='4px';
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(type==='Row'||src==='Row'){
    const div=document.createElement('div');
    div.className='n-row';
    if(node.mainAxisAlignment==='spaceEvenly')div.classList.add('space-evenly');
    if(node.mainAxisAlignment==='spaceBetween')div.classList.add('space-between');
    if(node.mainAxisAlignment==='center')div.classList.add('center');
    div.style.gap='8px';
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(node.isButton||src==='Button'||type==='Button'){
    const btn=document.createElement('button');
    btn.className='n-btn n-btn-filled';
    if(node.color)btn.style.backgroundColor=colorToCSS(node.color);
    const pt=node.padding_top||0,pb=node.padding_bottom||0,pl=node.padding_left||0,pr=node.padding_right||0;
    if(pt||pb||pl||pr)btn.style.padding=pt+'px '+pr+'px '+pb+'px '+pl+'px';
    btn.textContent=findText(node)||'Button';
    if(node.id)btn.onclick=()=>sendAction(node.id);
    return btn;
  }

  if(type==='Container'||src==='Container'){
    const div=document.createElement('div');
    div.className='n-container';
    if(node.color)div.style.backgroundColor=colorToCSS(node.color);
    if(node.width&&node.width>0)div.style.width=node.width+'px';
    if(node.height&&node.height>0)div.style.height=node.height+'px';
    const pt=node.padding_top||0,pb=node.padding_bottom||0,pl=node.padding_left||0,pr=node.padding_right||0;
    if(pt||pb||pl||pr)div.style.padding=pt+'px '+pr+'px '+pb+'px '+pl+'px';
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(type==='Expanded'||src==='Expanded'){
    const div=document.createElement('div');
    div.style.flex='1';
    div.style.display='flex';
    div.style.flexDirection='column';
    div.style.overflow='auto';
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(type==='SizedBox'||src==='SizedBox'){
    const div=document.createElement('div');
    if(node.width)div.style.width=node.width+'px';
    if(node.height)div.style.height=node.height+'px';
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(type==='Spacer'){
    const div=document.createElement('div');
    div.className='n-spacer';
    return div;
  }

  if(type==='Center'){
    const div=document.createElement('div');
    div.className='n-center';
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(type==='Badge'||src==='Badge'){
    const div=document.createElement('div');
    div.className='n-badge';
    children.forEach(c=>div.appendChild(renderWidget(c)));
    if(node.label){
      const badge=document.createElement('span');
      badge.className='badge-label';
      badge.textContent=node.label||'';
      div.appendChild(badge);
    }
    return div;
  }

  if(src==='FilledButton'||src==='ElevatedButton'||src==='OutlinedButton'||src==='TextButton'||src==='FilledTonalButton'){
    const btn=document.createElement('button');
    const styleMap={'FilledButton':'n-btn n-btn-filled','ElevatedButton':'n-btn n-btn-elevated','OutlinedButton':'n-btn n-btn-outlined','TextButton':'n-btn n-btn-text','FilledTonalButton':'n-btn n-btn-tonal'};
    btn.className=styleMap[src]||'n-btn n-btn-filled';
    const textChild=findText(node);
    btn.textContent=textChild||'Button';
    if(node.id)btn.onclick=()=>sendAction(node.id);
    return btn;
  }

  if(src==='FloatingActionButton'){
    const btn=document.createElement('button');
    btn.className='n-btn n-btn-fab';
    btn.textContent=findText(node)||'+';
    if(node.id)btn.onclick=()=>sendAction(node.id);
    return btn;
  }

  if(src==='IconButton'){
    const btn=document.createElement('button');
    btn.className='n-btn-icon';
    btn.textContent=findText(node)||'';
    if(node.id)btn.onclick=()=>sendAction(node.id);
    return btn;
  }

  if(type==='ActionChip'||src==='ActionChip'){
    const btn=document.createElement('button');
    btn.className='n-chip';
    btn.textContent=findText(node)||'';
    if(node.id)btn.onclick=()=>sendAction(node.id);
    return btn;
  }

  if(type==='FilterChip'||src==='FilterChip'){
    const btn=document.createElement('button');
    btn.className='n-chip'+(node.selected?' selected':'');
    btn.textContent=findText(node)||'';
    if(node.id)btn.onclick=()=>sendAction(node.id,{value:!node.selected});
    return btn;
  }

  if(type==='ChoiceChip'||src==='ChoiceChip'){
    const btn=document.createElement('button');
    btn.className='n-chip'+(node.selected?' selected':'');
    btn.textContent=findText(node)||'';
    if(node.id)btn.onclick=()=>sendAction(node.id,{value:!node.selected});
    return btn;
  }

  if(type==='SegmentedButton'||src==='SegmentedButton'){
    const div=document.createElement('div');
    div.className='n-segmented';
    const segs=node.segments||[];
    segs.forEach((s,i)=>{
      const btn=document.createElement('button');
      btn.textContent=typeof s==='string'?s:(s.text||'');
      if(i===node.selectedIndex)btn.className='active';
      btn.onclick=()=>sendAction(node.id,{index:i});
      div.appendChild(btn);
    });
    return div;
  }

  if(type==='Switch'||src==='Switch'){
    const div=document.createElement('div');
    div.className='n-switch'+(node.value?' on':'');
    const knob=document.createElement('div');
    knob.className='knob';
    div.appendChild(knob);
    div.onclick=()=>sendAction(node.id,{value:!node.value});
    return div;
  }

  if(type==='Checkbox'||src==='Checkbox'){
    const div=document.createElement('div');
    div.className='n-checkbox'+(node.value?' checked':'');
    div.textContent=node.value?'\\u2713':'';
    div.onclick=()=>sendAction(node.id,{value:!node.value});
    return div;
  }

  if(type==='Radio'||src==='Radio'){
    const div=document.createElement('div');
    div.className='n-radio'+(node.selected?' selected':'');
    div.onclick=()=>sendAction(node.id);
    return div;
  }

  if(type==='Slider'||src==='Slider'){
    const div=document.createElement('div');
    div.className='n-slider';
    const input=document.createElement('input');
    input.type='range';
    input.min='0';input.max='1';input.step='0.01';
    input.value=String(node.value||0);
    input.oninput=()=>sendAction(node.id,{value:parseFloat(input.value)});
    div.appendChild(input);
    if(node.label){
      const lbl=document.createElement('div');
      lbl.className='slider-label';
      lbl.textContent=node.label;
      div.appendChild(lbl);
    }
    return div;
  }

  if(type==='RangeSlider'||src==='RangeSlider'){
    const div=document.createElement('div');
    div.className='n-slider';
    div.style.display='flex';div.style.flexDirection='column';div.style.gap='4px';
    const mn=node.min||0,mx=node.max||1;
    const i1=document.createElement('input');
    i1.type='range';i1.min=String(mn);i1.max=String(mx);i1.step='1';i1.value=String(node.start||mn);
    const i2=document.createElement('input');
    i2.type='range';i2.min=String(mn);i2.max=String(mx);i2.step='1';i2.value=String(node.end||mx);
    const update=()=>sendAction(node.id,{start:parseFloat(i1.value),end:parseFloat(i2.value)});
    i1.oninput=update;i2.oninput=update;
    div.appendChild(i1);div.appendChild(i2);
    return div;
  }

  if(type==='TabBar'||src==='TabBar'){
    const div=document.createElement('div');
    div.className='n-tabbar';
    const tabs=node.tabs||[];
    tabs.forEach((t,i)=>{
      const btn=document.createElement('button');
      btn.textContent=t.text||'';
      if(i===node.selectedIndex)btn.className='active';
      btn.onclick=()=>sendAction(node.id,{index:i});
      div.appendChild(btn);
    });
    return div;
  }

  if(type==='Stack'||src==='Stack'){
    const div=document.createElement('div');
    div.className='n-stack';
    div.style.position='relative';
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(type==='Positioned'||src==='Positioned'){
    const div=document.createElement('div');
    div.className='n-positioned';
    if(node.left!=null)div.style.left=node.left+'px';
    if(node.top!=null)div.style.top=node.top+'px';
    if(node.right!=null)div.style.right=node.right+'px';
    if(node.bottom!=null)div.style.bottom=node.bottom+'px';
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(type==='Card'||src==='Card'){
    const div=document.createElement('div');
    const v=node.variant||'elevated';
    div.className='n-card n-card-'+v;
    if(node.borderRadius)div.style.borderRadius=node.borderRadius+'px';
    if(node.color)div.style.backgroundColor=colorToCSS(node.color);
    const pt=node.padding_top||16,pb=node.padding_bottom||16,pl=node.padding_left||16,pr=node.padding_right||16;
    div.style.padding=pt+'px '+pr+'px '+pb+'px '+pl+'px';
    if(node.id&&node.sourceType==='Card')div.style.cursor='pointer';
    if(node.id)div.onclick=()=>sendAction(node.id);
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(type==='Dialog'||src==='Dialog'){
    if(!node.visible)return document.createTextNode('');
    const overlay=document.createElement('div');
    if(node.variant==='fullscreen'){
      overlay.className='n-dialog-fullscreen';
      const header=document.createElement('div');
      header.className='n-dialog-header';
      const closeBtn=document.createElement('button');
      closeBtn.className='n-btn n-btn-text';
      closeBtn.textContent='\\u2715';
      closeBtn.onclick=()=>sendAction(node.id);
      header.appendChild(closeBtn);
      if(node.title){const t=document.createElement('span');t.style.fontSize='22px';t.style.fontWeight='500';t.style.marginLeft='16px';t.textContent=node.title;header.appendChild(t);}
      overlay.appendChild(header);
      const body=document.createElement('div');
      body.style.flex='1';body.style.padding='24px';body.style.overflow='auto';
      if(node.contentText){const p=document.createElement('p');p.textContent=node.contentText;body.appendChild(p);}
      children.forEach(c=>body.appendChild(renderWidget(c)));
      overlay.appendChild(body);
    }else{
      overlay.className='n-dialog-overlay';
      overlay.onclick=(e)=>{if(e.target===overlay)sendAction(node.id);};
      const dlg=document.createElement('div');
      dlg.className='n-dialog';
      if(node.title){const t=document.createElement('div');t.className='n-dialog-title';t.textContent=node.title;dlg.appendChild(t);}
      if(node.contentText){const c=document.createElement('div');c.className='n-dialog-content';c.textContent=node.contentText;dlg.appendChild(c);}
      children.forEach(c=>dlg.appendChild(renderWidget(c)));
      const acts=node.dialogActions||[];
      if(acts.length>0){const actDiv=document.createElement('div');actDiv.className='n-dialog-actions';acts.forEach(a=>{const btn=document.createElement('button');btn.className='n-btn n-btn-text';btn.textContent=a.label||'';btn.onclick=()=>{if(a.key)sendAction(a.key);else sendAction(node.id);};actDiv.appendChild(btn);});dlg.appendChild(actDiv);}
      overlay.appendChild(dlg);
    }
    return overlay;
  }

  if(type==='BottomSheet'||src==='BottomSheet'){
    if(!node.visible)return document.createTextNode('');
    const overlay=document.createElement('div');
    overlay.className='n-bottomsheet-overlay';
    overlay.onclick=(e)=>{if(e.target===overlay)sendAction(node.id);};
    const sheet=document.createElement('div');
    sheet.className='n-bottomsheet';
    if(node.showDragHandle!==false){const handle=document.createElement('div');handle.className='drag-handle';sheet.appendChild(handle);}
    children.forEach(c=>sheet.appendChild(renderWidget(c)));
    overlay.appendChild(sheet);
    return overlay;
  }

  if(type==='TextField'||src==='TextField'){
    const wrapper=document.createElement('div');
    const v=node.variant||'filled';
    wrapper.className='n-textfield n-textfield-'+v;
    if(node.labelText){const lbl=document.createElement('label');lbl.textContent=node.labelText;wrapper.appendChild(lbl);}
    let inp;
    if(node.maxLines>1){inp=document.createElement('textarea');inp.rows=node.maxLines;}
    else{inp=document.createElement('input');inp.type=node.obscureText?'password':'text';}
    inp.value=node.value||'';
    if(node.hintText)inp.placeholder=node.hintText;
    if(!node.enabled)inp.disabled=true;
    let debounceTimer;
    inp.oninput=()=>{clearTimeout(debounceTimer);debounceTimer=setTimeout(()=>sendAction(node.id,{value:inp.value}),300);};
    inp.onkeydown=(e)=>{if(e.key==='Enter'&&node.maxLines<=1)sendAction(node.id,{value:inp.value,action:'submit'});};
    wrapper.appendChild(inp);
    if(node.errorText){const e=document.createElement('div');e.className='error-text';e.textContent=node.errorText;wrapper.appendChild(e);}
    else if(node.helperText){const h=document.createElement('div');h.className='helper';h.textContent=node.helperText;wrapper.appendChild(h);}
    return wrapper;
  }

  if(type==='SearchBar'||src==='SearchBar'){
    const div=document.createElement('div');
    div.className='n-searchbar';
    const icon=document.createElement('span');
    icon.className='search-icon';
    icon.textContent='\\uD83D\\uDD0D';
    div.appendChild(icon);
    const inp=document.createElement('input');
    inp.type='text';
    inp.placeholder=node.hintText||'Search...';
    inp.value=node.value||'';
    if(!node.enabled)inp.disabled=true;
    let debounceTimer;
    inp.oninput=()=>{clearTimeout(debounceTimer);debounceTimer=setTimeout(()=>sendAction(node.id,{value:inp.value}),300);};
    inp.onkeydown=(e)=>{if(e.key==='Enter')sendAction(node.id,{value:inp.value,action:'submit'});};
    div.appendChild(inp);
    return div;
  }

  if(type==='SearchAnchor'||src==='SearchAnchor'){
    const wrapper=document.createElement('div');
    wrapper.style.position='relative';
    const bar=document.createElement('div');
    bar.className='n-searchbar';
    const icon=document.createElement('span');
    icon.className='search-icon';
    icon.textContent='\\uD83D\\uDD0D';
    bar.appendChild(icon);
    const inp=document.createElement('input');
    inp.type='text';
    inp.placeholder=node.hintText||'Search...';
    inp.value=node.value||'';
    let debounceTimer;
    inp.oninput=()=>{clearTimeout(debounceTimer);debounceTimer=setTimeout(()=>sendAction(node.id,{value:inp.value}),300);};
    inp.onfocus=()=>sendAction(node.id,{action:'toggle'});
    bar.appendChild(inp);
    wrapper.appendChild(bar);
    if(node.expanded){
      const suggestions=node.suggestions||[];
      if(suggestions.length>0){
        const list=document.createElement('div');
        list.className='n-menu';
        list.style.position='relative';list.style.marginTop='4px';list.style.width='100%';
        suggestions.forEach(s=>{const item=document.createElement('div');item.className='n-menu-item';item.textContent=s.text||'';item.onclick=()=>sendAction(node.id,{value:s.text||''});list.appendChild(item);});
        wrapper.appendChild(list);
      }
    }
    return wrapper;
  }

  if(type==='MenuAnchor'||src==='MenuAnchor'){
    const wrapper=document.createElement('div');
    wrapper.style.position='relative';wrapper.style.display='inline-block';
    const trigger=document.createElement('div');
    trigger.style.cursor='pointer';
    children.forEach(c=>trigger.appendChild(renderWidget(c)));
    trigger.onclick=()=>sendAction(node.id,{action:node.expanded?'close':'open'});
    wrapper.appendChild(trigger);
    if(node.expanded){
      const menu=document.createElement('div');
      menu.className='n-menu';
      const items=node.menuItems||[];
      items.forEach((item,i)=>{
        const mi=document.createElement('div');
        mi.className='n-menu-item'+(item.enabled===false?' disabled':'');
        mi.textContent=item.label||'';
        if(item.enabled!==false)mi.onclick=(e)=>{e.stopPropagation();sendAction(node.id,{index:i});};
        menu.appendChild(mi);
      });
      wrapper.appendChild(menu);
    }
    return wrapper;
  }

  if(type==='MenuBar'||src==='MenuBar'){
    const div=document.createElement('div');
    div.className='n-menubar';
    const items=node.menuItems||[];
    items.forEach((item,i)=>{
      const btn=document.createElement('button');
      btn.textContent=item.label||'';
      if(i===node.selectedIndex)btn.className='active';
      btn.onclick=()=>sendAction(node.id,{index:i});
      div.appendChild(btn);
    });
    return div;
  }

  if(type==='ListTile'||src==='ListTile'){
    const div=document.createElement('div');
    div.className='n-listtile'+(node.selected?' selected':'')+(node.dense?' dense':'');
    if(node.leading){
      const ld=document.createElement('div');ld.className='lt-leading';
      ld.textContent=node.leading.text||'';div.appendChild(ld);
    }
    const content=document.createElement('div');content.className='lt-content';
    if(node.title){const t=document.createElement('div');t.className='lt-title';t.textContent=node.title;content.appendChild(t);}
    if(node.subtitle){const s=document.createElement('div');s.className='lt-subtitle';s.textContent=node.subtitle;content.appendChild(s);}
    div.appendChild(content);
    if(node.trailing){
      const tr=document.createElement('div');tr.className='lt-trailing';
      tr.textContent=node.trailing.text||'';div.appendChild(tr);
    }
    if(node.id)div.onclick=()=>sendAction(node.id);
    return div;
  }

  if(type==='LinearProgressIndicator'||src==='LinearProgressIndicator'){
    const div=document.createElement('div');
    div.className='n-linear-progress'+(node.indeterminate?' indeterminate':'');
    const h=node.minHeight||4;
    const track=document.createElement('div');track.className='track';track.style.height=h+'px';
    const bar=document.createElement('div');bar.className='bar';
    if(!node.indeterminate&&node.value!=null)bar.style.width=(node.value*100)+'%';
    if(node.color)bar.style.background=colorToCSS(node.color);
    if(node.backgroundColor)track.style.background=colorToCSS(node.backgroundColor);
    track.appendChild(bar);div.appendChild(track);
    return div;
  }

  if(type==='CircularProgressIndicator'||src==='CircularProgressIndicator'){
    const sz=node.size||36;
    const sw=node.strokeWidth||4;
    const r=(sz-sw)/2;
    const circ=2*Math.PI*r;
    const div=document.createElement('div');
    div.className='n-circular-progress'+(node.indeterminate?' indeterminate':'');
    div.style.width=sz+'px';div.style.height=sz+'px';
    const svg=document.createElementNS('http://www.w3.org/2000/svg','svg');
    svg.setAttribute('width',sz);svg.setAttribute('height',sz);svg.setAttribute('viewBox','0 0 '+sz+' '+sz);
    const trackC=document.createElementNS('http://www.w3.org/2000/svg','circle');
    trackC.setAttribute('class','track-circle');trackC.setAttribute('cx',sz/2);trackC.setAttribute('cy',sz/2);
    trackC.setAttribute('r',r);trackC.setAttribute('stroke',node.backgroundColor?colorToCSS(node.backgroundColor):'#E7E0EC');trackC.setAttribute('stroke-width',sw);
    const barC=document.createElementNS('http://www.w3.org/2000/svg','circle');
    barC.setAttribute('class','bar-circle');barC.setAttribute('cx',sz/2);barC.setAttribute('cy',sz/2);
    barC.setAttribute('r',r);barC.setAttribute('stroke',node.color?colorToCSS(node.color):'#6750A4');barC.setAttribute('stroke-width',sw);
    barC.setAttribute('stroke-dasharray',circ);
    if(!node.indeterminate&&node.value!=null){barC.setAttribute('stroke-dashoffset',circ*(1-node.value));}
    else{barC.setAttribute('stroke-dashoffset',circ*0.75);}
    svg.appendChild(trackC);svg.appendChild(barC);div.appendChild(svg);
    return div;
  }

  if(type==='Tooltip'||src==='Tooltip'){
    const div=document.createElement('div');div.className='n-tooltip-wrapper';
    const tip=document.createElement('span');tip.className='tooltip-text '+(node.preferBelow!==false?'below':'above');
    tip.textContent=node.message||'';div.appendChild(tip);
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(type==='SnackBar'||src==='SnackBar'){
    if(!node.visible)return document.createTextNode('');
    const div=document.createElement('div');
    div.className='n-snackbar'+(node.behavior==='floating'?' floating':'');
    const content=document.createElement('span');content.className='snack-content';
    content.textContent=node.contentText||findText(node)||'';div.appendChild(content);
    if(node.actionLabel){
      const btn=document.createElement('button');btn.className='snack-action';btn.textContent=node.actionLabel;
      btn.onclick=()=>sendAction(node.id,{action:'action'});div.appendChild(btn);
    }
    if(node.showCloseIcon){
      const cls=document.createElement('button');cls.className='snack-close';cls.textContent='\\u2715';
      cls.onclick=()=>sendAction(node.id);div.appendChild(cls);
    }
    return div;
  }

  if(type==='SingleChildScrollView'||src==='SingleChildScrollView'){
    const div=document.createElement('div');
    div.className='n-scrollview '+(node.scrollDirection==='horizontal'?'horizontal':'vertical');
    if(node.padding_top>0||node.padding_left>0)div.style.padding=node.padding_top+'px '+node.padding_right+'px '+node.padding_bottom+'px '+node.padding_left+'px';
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(type==='ListView'||src==='ListView'){
    const div=document.createElement('div');
    div.className='n-scrollview n-listview '+(node.scrollDirection==='horizontal'?'horizontal':'vertical')+(node.shrinkWrap?' shrinkwrap':'');
    if(node.padding_top>0||node.padding_left>0)div.style.padding=node.padding_top+'px '+node.padding_right+'px '+node.padding_bottom+'px '+node.padding_left+'px';
    if(node.itemExtent)div.style.setProperty('--item-extent',node.itemExtent+'px');
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(type==='CustomScrollView'||src==='CustomScrollView'){
    const div=document.createElement('div');
    div.className='n-scrollview '+(node.scrollDirection==='horizontal'?'horizontal':'vertical');
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(type==='SliverList'||src==='SliverList'){
    const div=document.createElement('div');
    div.className='n-listview vertical';
    children.forEach(c=>div.appendChild(renderWidget(c)));
    return div;
  }

  if(type==='SliverAppBar'||src==='SliverAppBar'){
    const div=document.createElement('div');
    div.style.cssText='background:#6750A4;color:#fff;padding:16px 20px;border-radius:12px;margin-bottom:8px';
    if(node.expandedHeight)div.style.minHeight=Math.min(node.expandedHeight,120)+'px';
    const h=document.createElement('h2');h.textContent=node.title||'';h.style.margin='0';
    div.appendChild(h);
    return div;
  }

  if(type==='RemoteWidget'||src==='RemoteWidget'){
    const div=document.createElement('div');
    div.textContent='Loading remote...';
    if(node.url){
      const remoteUrl=node.url.replace('localhost:8080',window.location.host);
      fetch(remoteUrl).then(r=>r.json()).then(data=>{
        div.textContent='';
        div.appendChild(renderWidget(data));
      }).catch(()=>{div.textContent='Remote load failed';});
    }
    return div;
  }

  if(type==='AppBar'||src==='AppBar'){
    const bar=document.createElement('div');
    bar.className='n-appbar-inline';
    bar.style.cssText='background:#6750A4;color:#fff;padding:12px 20px;display:flex;align-items:center;justify-content:space-between;border-radius:12px;margin-bottom:8px';
    const h=document.createElement('h2');
    h.style.margin='0';h.style.fontSize='20px';
    h.textContent=node.title||findText(node)||'';
    bar.appendChild(h);
    const actions=node.actions||[];
    if(actions.length>0){
      const actDiv=document.createElement('div');actDiv.style.display='flex';actDiv.style.gap='4px';
      actions.forEach(a=>actDiv.appendChild(renderWidget(a)));
      bar.appendChild(actDiv);
    }
    return bar;
  }

  if(type==='NavigationBar'||src==='NavigationBar'){
    const nav=document.createElement('div');
    nav.className='n-navbar-inline';
    nav.style.cssText='display:flex;justify-content:space-around;background:#f3edf7;padding:8px 0;border-radius:12px;margin-top:8px;position:sticky;bottom:0';
    const dests=node.destinations||[];
    const selected=node.selectedIndex||0;
    const navId=node.id||'';
    dests.forEach((d,i)=>{
      const btn=document.createElement('button');
      btn.style.cssText='flex:1;display:flex;flex-direction:column;align-items:center;gap:4px;border:none;background:'+(i===selected?'#e8def8':'transparent')+';padding:8px 4px;border-radius:16px;cursor:pointer;font-size:12px';
      const iconSpan=document.createElement('span');
      iconSpan.style.fontSize='20px';
      const iconChildren=d.icon?.children||[];
      iconSpan.textContent=d.icon?.text||(iconChildren[0]?.text)||'';
      const labelSpan=document.createElement('span');
      labelSpan.style.cssText='font-size:11px;font-weight:'+(i===selected?'600':'400');
      labelSpan.textContent=d.label||'';
      btn.appendChild(iconSpan);
      btn.appendChild(labelSpan);
      btn.addEventListener('pointerup',(e)=>{e.preventDefault();e.stopPropagation();sendAction(navId,{index:i});},{passive:false});
      nav.appendChild(btn);
    });
    return nav;
  }

  // Fallback: render children
  const div=document.createElement('div');
  children.forEach(c=>div.appendChild(renderWidget(c)));
  return div;
}

function findText(node){
  if(!node)return '';
  if(node.text)return node.text;
  const ch=node.children||[];
  for(const c of ch){
    const t=findText(c);
    if(t)return t;
  }
  return '';
}

fetchTree();
</script>
</body>
</html>''';
  }

  /// Disposes the application and releases all resources.
  void dispose() {
    _lifecycleManager.dispose();
    _server?.close(force: true);
    _isRunning = false;
    _instance = null;
  }
}

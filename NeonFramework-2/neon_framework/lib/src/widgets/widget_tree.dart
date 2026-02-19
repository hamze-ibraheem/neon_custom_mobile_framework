import 'package:neon_framework/src/core/neon_app.dart';
import 'package:neon_framework/src/widgets/container.dart';
import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/text.dart';
import 'package:neon_framework/src/widgets/navigation.dart';
import 'package:neon_framework/src/widgets/app_bar.dart';
import 'package:neon_framework/src/widgets/button.dart';
import 'package:neon_framework/src/widgets/remote_widget.dart';
import 'package:neon_framework/src/widgets/primitives.dart';
import 'package:neon_framework/src/widgets/segmented_button.dart';
import 'package:neon_framework/src/widgets/layout.dart';
import 'package:neon_framework/src/widgets/badge.dart';
import 'package:neon_framework/src/widgets/chip.dart';
import 'package:neon_framework/src/widgets/selection_controls.dart';
import 'package:neon_framework/src/widgets/slider.dart';
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

/// Represents a single node in the widget tree.
class NeonElement {
  final String id;
  final NeonWidget widget; // The effective widget (e.g., Column)
  final NeonWidget sourceWidget; // The creator widget (e.g., MyApp)
  final NeonBuildContext context;
  final List<NeonElement> children;
  NeonElement? parent;

  NeonElement({
    required this.id,
    required this.widget,
    required this.sourceWidget,
    required this.context,
    List<NeonElement>? children,
    this.parent,
  }) : children = children ?? [];

  /// The depth of this element in the tree (0 for root).
  int get depth => parent == null ? 0 : parent!.depth + 1;

  /// Recursively prints the tree structure string
  String toTreeString({int indent = 0}) {
    final buffer = StringBuffer();
    final prefix = '│   ' * indent;
    final icon = indent == 0 ? '📦 ' : '├── ';

    // Clean up the output to be readable
    String label = '${sourceWidget.runtimeType} [id: $id]';

    if (sourceWidget is Text) {
      label += ': "${(sourceWidget as Text).data}"';
    }

    buffer.writeln('$prefix$icon$label');
    for (final child in children) {
      buffer.write(child.toTreeString(indent: indent + 1));
    }
    return buffer.toString();
  }

  List<Map<String, dynamic>> _serializeMenuItems(List<MenuItem> items) {
    return items.map((item) {
      final map = <String, dynamic>{
        'label': item.label,
        'enabled': item.enabled,
      };
      if (item.subMenu != null && item.subMenu!.isNotEmpty) {
        map['subMenu'] = _serializeMenuItems(item.subMenu!);
      }
      return map;
    }).toList();
  }

  dynamic _sanitizeDouble(double? value) {
    if (value == null) return null;
    if (value.isInfinite || value.isNaN) {
      return -1.0; // Standard sentinel for infinity/match_parent in this framework's bridge
    }
    return value;
  }

  /// Converts the element tree to a JSON map for the Android renderer.
  /// Converts the element tree to a JSON map for the Android renderer.
  Map<String, dynamic> toJson() {
    // Use the effective primitive widget type (e.g. Column) instead of the component type (e.g. MyApp)
    String type = widget is LeafWidget
        ? (widget as LeafWidget).type
        : widget.runtimeType.toString();
    Map<String, dynamic> data = {
      'id': id,
      'type': type,
      'sourceType': sourceWidget.runtimeType.toString(),
    };

    // Export properties (primitive handling)
    if (widget is Text) {
      data['text'] = (widget as Text).data;
    }

    // Export layout properties
    if (widget is Column) {
      data['axis'] = 'vertical';
    }
    if (widget is Row) {
      data['axis'] = 'horizontal';
    }

    if (widget is Container) {
      final container = widget as Container;
      if (container.width != null)
        data['width'] = _sanitizeDouble(container.width);
      if (container.height != null)
        data['height'] = _sanitizeDouble(container.height);
      if (container.color != null) data['color'] = container.color!.value;
      if (container.padding != NeonEdgeInsets.zero) {
        data['padding_top'] = container.padding.top;
        data['padding_bottom'] = container.padding.bottom;
        data['padding_left'] = container.padding.left;
        data['padding_right'] = container.padding.right;
      }
    }

    if (sourceWidget is RemoteWidget) {
      data['url'] = (sourceWidget as RemoteWidget).url;
    }

    if (sourceWidget is NavigationBar) {
      final nav = sourceWidget as NavigationBar;
      data['selectedIndex'] = nav.selectedIndex;
      data['destinations'] = nav.destinations.map((d) {
        String iconText = '';
        if (d.icon is Text) iconText = (d.icon as Text).data;
        return {'label': d.label, 'icon': {'text': iconText}};
      }).toList();
    }

    if (sourceWidget is AppBar) {
      final appBar = sourceWidget as AppBar;
      data['variant'] = appBar.variant.name;
      if (appBar.title is Text) {
        data['title'] = (appBar.title as Text).data;
      }
      if (appBar.actions != null) {
        data['actions'] = appBar.actions!.map((a) {
          if (a is Badge) {
            String labelText = '';
            if (a.label is Text) labelText = (a.label as Text).data;
            return {'type': 'Badge', 'label': labelText};
          }
          return {'type': a.runtimeType.toString()};
        }).toList();
      }
    }

    if (sourceWidget is TabBar) {
      final tabBar = sourceWidget as TabBar;
      data['selectedIndex'] = tabBar.selectedIndex;
      data['tabs'] = tabBar.tabs.map((t) => {'text': t.text}).toList();
    }

    if (sourceWidget is SegmentedButton) {
      final seg = sourceWidget as SegmentedButton;
      data['selectedIndex'] = seg.selectedIndex;
      data['segments'] = seg.segments
          .map((s) => s is Text ? s.data : s.runtimeType.toString())
          .toList();
    }

    if (sourceWidget is NavigationDrawer) {
      final drawer = sourceWidget as NavigationDrawer;
      data['selectedIndex'] = drawer.selectedIndex;
      data['children'] = drawer.children
          .map((c) => {
                'label': c.label is Text
                    ? (c.label as Text).data
                    : c.label.toString()
              })
          .toList();
    }

    if (sourceWidget is NavigationRail) {
      final rail = sourceWidget as NavigationRail;
      data['selectedIndex'] = rail.selectedIndex;
      data['destinations'] = rail.destinations
          .map((d) => {
                'label': d.label is Text
                    ? (d.label as Text).data
                    : d.label.toString()
              })
          .toList();
    }

    if (sourceWidget is Badge) {
      final badge = sourceWidget as Badge;
      data['backgroundColor'] = badge.backgroundColor.value;
      data['labelColor'] = badge.labelColor.value;
    }

    if (sourceWidget is ActionChip) {
      final chip = sourceWidget as ActionChip;
      data['enabled'] = chip.enabled;
    }

    if (sourceWidget is FilterChip) {
      final chip = sourceWidget as FilterChip;
      data['selected'] = chip.selected;
    }

    if (sourceWidget is ChoiceChip) {
      final chip = sourceWidget as ChoiceChip;
      data['selected'] = chip.selected;
    }

    if (sourceWidget is InputChip) {
      final chip = sourceWidget as InputChip;
      data['selected'] = chip.selected;
    }

    if (sourceWidget is Switch) {
      final sw = sourceWidget as Switch;
      data['value'] = sw.value;
      data['enabled'] = sw.enabled;
    }

    if (sourceWidget is Checkbox) {
      final cb = sourceWidget as Checkbox;
      data['value'] = cb.value;
      data['enabled'] = cb.enabled;
      data['tristate'] = cb.tristate;
    }

    if (sourceWidget is Radio) {
      final rb = sourceWidget as Radio;
      data['selected'] = rb.value == rb.groupValue;
      data['enabled'] = rb.enabled;
    }

    if (sourceWidget is Slider) {
      final s = sourceWidget as Slider;
      data['value'] = _sanitizeDouble(s.value);
      data['min'] = _sanitizeDouble(s.min);
      data['max'] = _sanitizeDouble(s.max);
      data['divisions'] = s.divisions;
      data['label'] = s.label;
      data['enabled'] = s.enabled;
    }

    if (sourceWidget is RangeSlider) {
      final rs = sourceWidget as RangeSlider;
      data['start'] = _sanitizeDouble(rs.values.start);
      data['end'] = _sanitizeDouble(rs.values.end);
      data['min'] = _sanitizeDouble(rs.min);
      data['max'] = _sanitizeDouble(rs.max);
      data['divisions'] = rs.divisions;
      data['enabled'] = rs.enabled;
    }

    if (sourceWidget is Button) {
      data['isButton'] = true;
      if ((sourceWidget as Button).color != null) {
        data['color'] = (sourceWidget as Button).color!.value;
      }
    }

    if (sourceWidget is Card) {
      final card = sourceWidget as Card;
      data['variant'] = card.variant.name;
      data['borderRadius'] = card.borderRadius;
      if (card.color != null) data['color'] = card.color!.value;
      data['padding_top'] = card.padding.top;
      data['padding_bottom'] = card.padding.bottom;
      data['padding_left'] = card.padding.left;
      data['padding_right'] = card.padding.right;
    }

    if (sourceWidget is Dialog) {
      final dlg = sourceWidget as Dialog;
      data['variant'] = dlg.variant.name;
      data['visible'] = dlg.visible;
      data['borderRadius'] = dlg.borderRadius;
      if (dlg.title is Text) data['title'] = (dlg.title as Text).data;
      if (dlg.content is Text) data['contentText'] = (dlg.content as Text).data;
      if (dlg.actions != null) {
        data['dialogActions'] = dlg.actions!.map((a) {
          if (a is Button) {
            final child = a.child;
            return {'type': 'Button', 'label': child is Text ? child.data : '', 'key': a.key};
          }
          return {'type': a.runtimeType.toString()};
        }).toList();
      }
    }

    if (sourceWidget is BottomSheet) {
      final bs = sourceWidget as BottomSheet;
      data['visible'] = bs.visible;
      data['showDragHandle'] = bs.showDragHandle;
      data['borderRadius'] = bs.borderRadius;
      if (bs.backgroundColor != null) data['backgroundColor'] = bs.backgroundColor!.value;
    }

    if (sourceWidget is SearchBar) {
      final sb = sourceWidget as SearchBar;
      data['hintText'] = sb.hintText;
      data['value'] = sb.value;
      data['enabled'] = sb.enabled;
    }

    if (sourceWidget is SearchAnchor) {
      final sa = sourceWidget as SearchAnchor;
      data['expanded'] = sa.expanded;
      data['isFullScreen'] = sa.isFullScreen;
      data['hintText'] = sa.searchBar.hintText;
      data['value'] = sa.searchBar.value;
      data['suggestions'] = sa.suggestions.map((s) {
        if (s is Text) return {'type': 'Text', 'text': s.data};
        return {'type': s.runtimeType.toString()};
      }).toList();
    }

    if (sourceWidget is TextField) {
      final tf = sourceWidget as TextField;
      data['value'] = tf.value;
      data['variant'] = tf.variant.name;
      data['enabled'] = tf.enabled;
      data['obscureText'] = tf.obscureText;
      data['maxLines'] = tf.maxLines;
      data['borderRadius'] = tf.borderRadius;
      if (tf.labelText != null) data['labelText'] = tf.labelText;
      if (tf.hintText != null) data['hintText'] = tf.hintText;
      if (tf.helperText != null) data['helperText'] = tf.helperText;
      if (tf.errorText != null) data['errorText'] = tf.errorText;
    }

    if (sourceWidget is MenuAnchor) {
      final ma = sourceWidget as MenuAnchor;
      data['expanded'] = ma.expanded;
      data['menuItems'] = _serializeMenuItems(ma.menuItems);
    }

    if (sourceWidget is MenuBar) {
      final mb = sourceWidget as MenuBar;
      data['selectedIndex'] = mb.selectedIndex;
      data['menuItems'] = _serializeMenuItems(mb.items);
    }

    if (sourceWidget is ListTile) {
      final lt = sourceWidget as ListTile;
      data['enabled'] = lt.enabled;
      data['selected'] = lt.selected;
      data['dense'] = lt.dense;
      data['padding_top'] = lt.contentPadding.top;
      data['padding_bottom'] = lt.contentPadding.bottom;
      data['padding_left'] = lt.contentPadding.left;
      data['padding_right'] = lt.contentPadding.right;
      if (lt.leading != null) {
        data['leading'] = lt.leading is Text ? {'type': 'Text', 'text': (lt.leading as Text).data} : {'type': lt.leading.runtimeType.toString()};
      }
      if (lt.title != null) {
        data['title'] = lt.title is Text ? (lt.title as Text).data : '';
      }
      if (lt.subtitle != null) {
        data['subtitle'] = lt.subtitle is Text ? (lt.subtitle as Text).data : '';
      }
      if (lt.trailing != null) {
        data['trailing'] = lt.trailing is Text ? {'type': 'Text', 'text': (lt.trailing as Text).data} : {'type': lt.trailing.runtimeType.toString()};
      }
    }

    if (sourceWidget is LinearProgressIndicator) {
      final lp = sourceWidget as LinearProgressIndicator;
      data['indeterminate'] = lp.isIndeterminate;
      if (lp.value != null) data['value'] = lp.value;
      if (lp.color != null) data['color'] = lp.color!.value;
      if (lp.backgroundColor != null) data['backgroundColor'] = lp.backgroundColor!.value;
      data['minHeight'] = lp.minHeight;
      data['borderRadius'] = lp.borderRadius;
    }

    if (sourceWidget is CircularProgressIndicator) {
      final cp = sourceWidget as CircularProgressIndicator;
      data['indeterminate'] = cp.isIndeterminate;
      if (cp.value != null) data['value'] = cp.value;
      if (cp.color != null) data['color'] = cp.color!.value;
      if (cp.backgroundColor != null) data['backgroundColor'] = cp.backgroundColor!.value;
      data['strokeWidth'] = cp.strokeWidth;
      data['size'] = cp.size;
    }

    if (sourceWidget is Tooltip) {
      final tt = sourceWidget as Tooltip;
      data['message'] = tt.message;
      data['preferBelow'] = tt.preferBelow;
    }

    if (sourceWidget is SnackBar) {
      final sb = sourceWidget as SnackBar;
      data['visible'] = sb.visible;
      data['behavior'] = sb.behavior.name;
      data['showCloseIcon'] = sb.showCloseIcon;
      if (sb.actionLabel != null) data['actionLabel'] = sb.actionLabel;
      if (sb.content is Text) data['contentText'] = (sb.content as Text).data;
    }

    if (sourceWidget is SingleChildScrollView) {
      final sv = sourceWidget as SingleChildScrollView;
      data['scrollDirection'] = sv.scrollDirection.name;
      data['reverse'] = sv.reverse;
      data['padding_top'] = sv.padding.top;
      data['padding_bottom'] = sv.padding.bottom;
      data['padding_left'] = sv.padding.left;
      data['padding_right'] = sv.padding.right;
    }

    if (sourceWidget is ListView) {
      final lv = sourceWidget as ListView;
      data['scrollDirection'] = lv.scrollDirection.name;
      data['reverse'] = lv.reverse;
      data['shrinkWrap'] = lv.shrinkWrap;
      if (lv.itemExtent != null) data['itemExtent'] = lv.itemExtent;
      data['padding_top'] = lv.padding.top;
      data['padding_bottom'] = lv.padding.bottom;
      data['padding_left'] = lv.padding.left;
      data['padding_right'] = lv.padding.right;
    }

    if (sourceWidget is CustomScrollView) {
      final csv = sourceWidget as CustomScrollView;
      data['scrollDirection'] = csv.scrollDirection.name;
      data['reverse'] = csv.reverse;
    }

    if (sourceWidget is SliverList) {
      data['sliverType'] = 'list';
    }

    if (sourceWidget is SliverAppBar) {
      final sa = sourceWidget as SliverAppBar;
      data['floating'] = sa.floating;
      data['pinned'] = sa.pinned;
      data['expandedHeight'] = sa.expandedHeight;
      if (sa.title is Text) data['title'] = (sa.title as Text).data;
    }

    if (widget is Expanded) {
      data['flex'] = (widget as Expanded).flex;
    }
    if (widget is Spacer) {
      data['flex'] = (widget as Spacer).flex;
    }
    if (widget is SizedBox) {
      final sb = widget as SizedBox;
      if (sb.width != null) data['width'] = _sanitizeDouble(sb.width);
      if (sb.height != null) data['height'] = _sanitizeDouble(sb.height);
    }

    if (widget is Positioned) {
      final pos = widget as Positioned;
      if (pos.left != null) data['left'] = _sanitizeDouble(pos.left);
      if (pos.top != null) data['top'] = _sanitizeDouble(pos.top);
      if (pos.right != null) data['right'] = _sanitizeDouble(pos.right);
      if (pos.bottom != null) data['bottom'] = _sanitizeDouble(pos.bottom);
    }

    // Recursively export children
    data['children'] = children.map((c) => c.toJson()).toList();

    return data;
  }
}

class NeonWidgetTree {
  NeonElement? _root;
  int _nodeCount = 0;

  NeonElement? get root => _root;
  int get nodeCount => _nodeCount;

  /// Returns the global state store as the state registry.
  Map<String, NeonState> get stateRegistry => NeonApp.globalStateStore;

  /// Disposes and clears all states in the registry.
  void disposeStates() {
    for (final state in stateRegistry.values) {
      state.dispose();
    }
    stateRegistry.clear();
  }

  /// Builds the tree starting from the root widget.
  void buildTree(NeonWidget rootWidget, NeonBuildContext context) {
    _nodeCount = 0;
    _root = _buildElement(rootWidget, context, null, 0);
  }

  /// Prints the built tree to the console.
  void printTree() {
    if (_root != null) {
      // ignore: avoid_print
      print(_root!.toTreeString());
    } else {
      print('  (Empty Tree)');
    }
  }

  NeonElement _buildElement(
    NeonWidget widget,
    NeonBuildContext context,
    NeonElement? parent,
    int index,
  ) {
    _nodeCount++;

    // 1. Initial ID for this hierarchy branch
    String currentId =
        widget.key ?? (parent == null ? 'root' : '${parent.id}.$index');
    NeonBuildContext currentContext = context.spawn(widget, currentId);
    NeonWidget currentWidget = widget;

    // Keep track of the most specific interactable widget (like Button)
    NeonWidget interactableWidget = widget;

    // 2. LOOP: Recursively build components until we reach a primitive (Column, Text, etc)
    while (true) {
      final builtResult = currentWidget.build(currentContext);

      // If build returns null or itself, it's a primitive -> Stop
      if (builtResult == null || builtResult == currentWidget) break;

      // UNWRAP: Update context and ID for the built child
      // Only append '.u' if the built widget doesn't have its own key
      // or if it's a different conceptual layer.
      if (builtResult.key == null || builtResult.key == currentWidget.key) {
        // Keep ID but update context for the new widget type
        currentContext = currentContext.spawn(builtResult, currentId);
      } else {
        currentId = "${currentContext.id!}.${builtResult.key}";
        currentContext = currentContext.spawn(builtResult, currentId);
      }
      currentWidget = builtResult;

      if (currentWidget is Button ||
          currentWidget is Card ||
          currentWidget is Dialog ||
          currentWidget is BottomSheet ||
          currentWidget is TextField ||
          currentWidget is SearchBar ||
          currentWidget is SearchAnchor ||
          currentWidget is MenuAnchor ||
          currentWidget is MenuBar ||
          currentWidget is ListTile ||
          currentWidget is LinearProgressIndicator ||
          currentWidget is CircularProgressIndicator ||
          currentWidget is Tooltip ||
          currentWidget is SnackBar ||
          currentWidget is SingleChildScrollView ||
          currentWidget is ListView ||
          currentWidget is CustomScrollView ||
          currentWidget is SliverList ||
          currentWidget is SliverAppBar ||
          currentWidget is NavigationBar ||
          currentWidget is TabBar ||
          currentWidget is AppBar) {
        interactableWidget = currentWidget;
      }
    }

    // 3. Extract children from the FINAL primitive widget
    var childWidgets = _extractChildren(currentWidget);
    if (childWidgets.isEmpty && interactableWidget != currentWidget) {
      childWidgets = _extractChildren(interactableWidget);
    }

    // 4. Create the NeonElement using the FINAL primitive state but the source widget link
    final element = NeonElement(
      id: currentId,
      widget: currentWidget,
      sourceWidget: interactableWidget,
      context: currentContext,
      parent: parent,
    );

    // 5. Recursively build children
    for (int i = 0; i < childWidgets.length; i++) {
      element.children
          .add(_buildElement(childWidgets[i], currentContext, element, i));
    }

    return element;
  }

  /// Helper to get children from known Layout widgets
  List<NeonWidget> _extractChildren(NeonWidget widget) {
    if (widget is MultiChildWidget) {
      return widget.children;
    }
    // FIX: Support Single-child widgets
    if (widget is Container && widget.child != null) {
      return [widget.child!];
    }
    if (widget is Expanded) {
      return [(widget as Expanded).child];
    }
    if (widget is Center) {
      return [(widget as Center).child];
    }
    if (widget is SizedBox && (widget as SizedBox).child != null) {
      return [(widget as SizedBox).child!];
    }
    if (widget is Positioned) {
      return [(widget as Positioned).child];
    }
    if (widget is Card) {
      return [(widget as Card).child];
    }
    if (widget is Dialog) {
      final dlg = widget as Dialog;
      final result = <NeonWidget>[];
      if (dlg.content != null && dlg.content is! Text) result.add(dlg.content!);
      if (dlg.actions != null) result.addAll(dlg.actions!);
      return result;
    }
    if (widget is BottomSheet) {
      return [(widget as BottomSheet).child];
    }
    if (widget is MenuAnchor) {
      return [(widget as MenuAnchor).child];
    }
    if (widget is ListTile) {
      final lt = widget as ListTile;
      final result = <NeonWidget>[];
      if (lt.leading != null) result.add(lt.leading!);
      if (lt.title != null) result.add(lt.title!);
      if (lt.subtitle != null) result.add(lt.subtitle!);
      if (lt.trailing != null) result.add(lt.trailing!);
      return result;
    }
    if (widget is Tooltip) {
      return [(widget as Tooltip).child];
    }
    if (widget is SnackBar) {
      final sb = widget as SnackBar;
      final result = <NeonWidget>[sb.content];
      if (sb.action != null) result.add(sb.action!);
      return result;
    }
    if (widget is SingleChildScrollView) {
      return [(widget as SingleChildScrollView).child];
    }
    if (widget is ListView) {
      return (widget as ListView).children;
    }
    if (widget is CustomScrollView) {
      return (widget as CustomScrollView).slivers;
    }
    if (widget is SliverList) {
      return (widget as SliverList).children;
    }
    return [];
  }
}

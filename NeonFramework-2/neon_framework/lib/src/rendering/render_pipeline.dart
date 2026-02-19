import 'package:neon_framework/src/rendering/render_object.dart';
import 'package:neon_framework/src/rendering/constraints.dart';
import 'package:neon_framework/src/rendering/canvas.dart';
import 'package:neon_framework/src/rendering/render_widgets.dart';
import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/text.dart' as w;
import 'package:neon_framework/src/widgets/container.dart' as w;
import 'package:neon_framework/src/widgets/button.dart' as w;
import 'package:neon_framework/src/widgets/layout.dart' as w;
import 'package:neon_framework/src/widgets/widget_tree.dart';

/// Manages the layout and paint pipeline for the Neon render tree.
class NeonRenderPipeline {
  NeonRenderObject? _rootRenderObject;

  /// Device information used for rendering calculations.
  final NeonDeviceInfo deviceInfo;
  NeonCanvas? _canvas;

  NeonRenderPipeline({
    this.deviceInfo = const NeonDeviceInfo(),
  });

  /// The root render object of the current render tree.
  NeonRenderObject? get rootRenderObject => _rootRenderObject;

  /// The canvas produced by the most recent paint pass.
  NeonCanvas? get canvas => _canvas;

  /// Builds a render tree from the given element tree.
  NeonRenderObject buildRenderTree(NeonElement element) {
    final renderObject = _createRenderObject(element);

    for (final child in element.children) {
      final childRender = buildRenderTree(child);
      renderObject.addChild(childRender);
    }

    _rootRenderObject = renderObject;
    return renderObject;
  }

  NeonRenderObject _createRenderObject(NeonElement element) {
    final widget = element.widget;

    if (widget is w.Text) {
      return RenderText(
        text: widget.data,
        style: widget.style,
        maxLines: widget.maxLines,
      );
    }

    if (widget is w.Container) {
      return RenderContainer(
        fixedWidth: widget.width,
        fixedHeight: widget.height,
        color: widget.color,
        padding: widget.padding,
        margin: widget.margin,
      );
    }

    if (widget is w.Column) {
      return RenderColumn(
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
      );
    }

    if (widget is w.Row) {
      return RenderRow(
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
      );
    }

    if (widget is w.Stack) {
      return RenderStack(fit: widget.fit);
    }

    return _FallbackRenderObject();
  }

  /// Runs the layout pass on the render tree with the given constraints.
  void layout(NeonConstraints constraints) {
    if (_rootRenderObject == null) return;
    _rootRenderObject!.layout(constraints);
  }

  /// Runs the paint pass and returns the resulting canvas.
  NeonCanvas paint() {
    _canvas = NeonCanvas(deviceInfo: deviceInfo);
    if (_rootRenderObject != null) {
      _rootRenderObject!.paint(_canvas!);
    }
    return _canvas!;
  }

  /// Runs the full layout and paint pipeline, returning the canvas.
  NeonCanvas runPipeline(NeonConstraints constraints) {
    layout(constraints);
    return paint();
  }

  /// Returns a debug string representation of the render tree.
  String debugDump() {
    if (_rootRenderObject == null) return '<empty render tree>';
    return _rootRenderObject!.toDebugString();
  }
}

class _FallbackRenderObject extends NeonRenderObject {
  @override
  NeonSize performLayout(NeonConstraints constraints) {
    return constraints.smallest;
  }

  @override
  void performPaint(NeonCanvas canvas) {}
}

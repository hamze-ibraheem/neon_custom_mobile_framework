import 'package:neon_framework/src/rendering/constraints.dart';
import 'package:neon_framework/src/rendering/canvas.dart';

/// Base class for all render objects in the Neon rendering tree.
abstract class NeonRenderObject {
  /// The parent render object in the tree.
  NeonRenderObject? parent;

  /// The child render objects.
  final List<NeonRenderObject> children = [];

  NeonSize _size = NeonSize.zero;
  NeonOffset _relativeOffset = NeonOffset.zero;
  bool _needsLayout = true;
  bool _needsPaint = true;

  /// Whether this render object needs layout.
  bool get needsLayout => _needsLayout;

  /// Whether this render object needs paint.
  bool get needsPaint => _needsPaint;

  /// The size determined during layout.
  NeonSize get size => _size;

  /// The offset relative to this object's parent.
  NeonOffset get relativeOffset => _relativeOffset;

  /// Sets the offset relative to this object's parent.
  set relativeOffset(NeonOffset value) {
    _relativeOffset = value;
  }

  /// The absolute offset from the root of the render tree.
  NeonOffset get absoluteOffset {
    if (parent == null) return _relativeOffset;
    return parent!.absoluteOffset + _relativeOffset;
  }

  /// The bounding rectangle in absolute coordinates.
  NeonRect get bounds => NeonRect.fromOffset(absoluteOffset, _size);

  /// Adds a child render object and marks layout as dirty.
  void addChild(NeonRenderObject child) {
    child.parent = this;
    children.add(child);
    markNeedsLayout();
  }

  /// Removes a child render object and marks layout as dirty.
  void removeChild(NeonRenderObject child) {
    children.remove(child);
    child.parent = null;
    markNeedsLayout();
  }

  /// Marks this object as needing layout and paint.
  void markNeedsLayout() {
    _needsLayout = true;
    _needsPaint = true;
  }

  /// Marks this object as needing paint.
  void markNeedsPaint() {
    _needsPaint = true;
  }

  /// Lays out this object within the given constraints.
  void layout(NeonConstraints constraints) {
    if (!_needsLayout) return;
    _size = performLayout(constraints);
    _needsLayout = false;
    _needsPaint = true;
  }

  /// Subclass hook to compute size given constraints.
  NeonSize performLayout(NeonConstraints constraints);

  /// Paints this object and its children onto the canvas.
  void paint(NeonCanvas canvas) {
    canvas.save();
    canvas.translate(absoluteOffset.dx, absoluteOffset.dy);
    performPaint(canvas);
    canvas.restore();
    _needsPaint = false;
  }

  /// Subclass hook to perform custom painting.
  void performPaint(NeonCanvas canvas);

  /// Tests whether the given point hits this object or any child.
  bool hitTest(NeonOffset point) {
    if (!bounds.contains(point)) return false;

    for (var i = children.length - 1; i >= 0; i--) {
      if (children[i].hitTest(point)) return true;
    }
    return true;
  }

  /// The depth of this object in the render tree (0 for root).
  int get depth {
    var d = 0;
    var current = parent;
    while (current != null) {
      d++;
      current = current.parent;
    }
    return d;
  }

  /// Returns a debug string representation of this object and its subtree.
  String toDebugString({int indent = 0}) {
    final buffer = StringBuffer();
    final prefix = '  ' * indent;
    buffer.writeln(
        '$prefix$runtimeType(size: $_size, rel: $_relativeOffset, abs: $absoluteOffset)');
    for (final child in children) {
      buffer.write(child.toDebugString(indent: indent + 1));
    }
    return buffer.toString();
  }

  @override
  String toString() => '$runtimeType(size: $_size, offset: $_relativeOffset)';
}

/// Represents a 2D size with width and height.
class NeonSize {
  final double width;
  final double height;

  const NeonSize(this.width, this.height);

  /// A size with zero width and height.
  static const NeonSize zero = NeonSize(0, 0);

  /// A size with infinite width and height.
  static const NeonSize infinite = NeonSize(double.infinity, double.infinity);

  /// Whether either dimension is zero or negative.
  bool get isEmpty => width <= 0 || height <= 0;

  /// Whether both dimensions are finite.
  bool get isFinite => width.isFinite && height.isFinite;

  /// Returns a new size clamped to the given constraints.
  NeonSize constrain(NeonConstraints constraints) {
    return NeonSize(
      width.clamp(constraints.minWidth, constraints.maxWidth),
      height.clamp(constraints.minHeight, constraints.maxHeight),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeonSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'NeonSize($width, $height)';
}

/// Represents a 2D offset (displacement) with dx and dy components.
class NeonOffset {
  final double dx;
  final double dy;

  const NeonOffset(this.dx, this.dy);

  /// An offset with zero displacement.
  static const NeonOffset zero = NeonOffset(0, 0);

  /// Adds two offsets together.
  NeonOffset operator +(NeonOffset other) =>
      NeonOffset(dx + other.dx, dy + other.dy);

  /// Subtracts another offset from this offset.
  NeonOffset operator -(NeonOffset other) =>
      NeonOffset(dx - other.dx, dy - other.dy);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeonOffset && other.dx == dx && other.dy == dy;

  @override
  int get hashCode => Object.hash(dx, dy);

  @override
  String toString() => 'NeonOffset($dx, $dy)';
}

/// Represents an axis-aligned rectangle defined by position and size.
class NeonRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const NeonRect(this.left, this.top, this.width, this.height);

  /// A zero-sized rectangle at the origin.
  static const NeonRect zero = NeonRect(0, 0, 0, 0);

  /// Creates a rectangle from an offset and size.
  NeonRect.fromOffset(NeonOffset offset, NeonSize size)
      : left = offset.dx,
        top = offset.dy,
        width = size.width,
        height = size.height;

  /// The right edge of the rectangle.
  double get right => left + width;

  /// The bottom edge of the rectangle.
  double get bottom => top + height;

  /// The top-left corner as an offset.
  NeonOffset get topLeft => NeonOffset(left, top);

  /// The size of the rectangle.
  NeonSize get size => NeonSize(width, height);

  /// Whether the given point lies within this rectangle.
  bool contains(NeonOffset point) =>
      point.dx >= left &&
      point.dx <= right &&
      point.dy >= top &&
      point.dy <= bottom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeonRect &&
          other.left == left &&
          other.top == top &&
          other.width == width &&
          other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'NeonRect($left, $top, $width, $height)';
}

/// Immutable layout constraints with min/max width and height bounds.
class NeonConstraints {
  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  const NeonConstraints({
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    this.minHeight = 0,
    this.maxHeight = double.infinity,
  });

  /// Creates tight constraints that force an exact size.
  NeonConstraints.tight(NeonSize size)
      : minWidth = size.width,
        maxWidth = size.width,
        minHeight = size.height,
        maxHeight = size.height;

  /// Creates loose constraints with zero minimums and the given size as maximums.
  NeonConstraints.loose(NeonSize size)
      : minWidth = 0,
        maxWidth = size.width,
        minHeight = 0,
        maxHeight = size.height;

  /// Creates constraints that expand to fill, optionally with fixed dimensions.
  const NeonConstraints.expand({
    double? width,
    double? height,
  })  : minWidth = width ?? double.infinity,
        maxWidth = width ?? double.infinity,
        minHeight = height ?? double.infinity,
        maxHeight = height ?? double.infinity;

  /// Whether these constraints allow only a single size.
  bool get isTight => minWidth == maxWidth && minHeight == maxHeight;

  /// Whether the maximum width is finite.
  bool get hasBoundedWidth => maxWidth < double.infinity;

  /// Whether the maximum height is finite.
  bool get hasBoundedHeight => maxHeight < double.infinity;

  /// Returns a copy with optionally overridden constraint values.
  NeonConstraints copyWith({
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) {
    return NeonConstraints(
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
    );
  }

  /// Returns new constraints with zero minimums, preserving maximums.
  NeonConstraints loosen() {
    return NeonConstraints(
      minWidth: 0,
      maxWidth: maxWidth,
      minHeight: 0,
      maxHeight: maxHeight,
    );
  }

  /// Returns new constraints tightened to the given width and/or height.
  NeonConstraints tighten({double? width, double? height}) {
    return NeonConstraints(
      minWidth: width ?? minWidth,
      maxWidth: width ?? maxWidth,
      minHeight: height ?? minHeight,
      maxHeight: height ?? maxHeight,
    );
  }

  /// Constrains the given size to fit within these constraints.
  NeonSize constrain(NeonSize size) => size.constrain(this);

  /// The smallest size that satisfies these constraints.
  NeonSize get smallest => NeonSize(minWidth, minHeight);

  /// The largest size that satisfies these constraints.
  NeonSize get biggest => NeonSize(maxWidth, maxHeight);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeonConstraints &&
          other.minWidth == minWidth &&
          other.maxWidth == maxWidth &&
          other.minHeight == minHeight &&
          other.maxHeight == maxHeight;

  @override
  int get hashCode => Object.hash(minWidth, maxWidth, minHeight, maxHeight);

  @override
  String toString() =>
      'NeonConstraints($minWidth<=w<=$maxWidth, $minHeight<=h<=$maxHeight)';
}

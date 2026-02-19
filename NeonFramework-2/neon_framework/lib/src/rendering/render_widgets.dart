import 'package:neon_framework/src/rendering/render_object.dart';
import 'package:neon_framework/src/rendering/constraints.dart';
import 'package:neon_framework/src/rendering/canvas.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

/// Render object that lays out and paints text content.
class RenderText extends NeonRenderObject {
  final String text;
  final NeonTextStyle style;
  final int? maxLines;

  /// Creates a text render object with the given text and style.
  RenderText({
    required this.text,
    this.style = const NeonTextStyle(),
    this.maxLines,
  });

  @override
  NeonSize performLayout(NeonConstraints constraints) {
    final charWidth = style.fontSize * 0.6;
    final lineHeight = style.fontSize * 1.2;
    final textWidth = text.length * charWidth;
    final maxWidth =
        constraints.hasBoundedWidth ? constraints.maxWidth : textWidth;
    final lines = (textWidth / maxWidth).ceil().clamp(1, maxLines ?? 999);
    final width = textWidth.clamp(constraints.minWidth, maxWidth);
    final height =
        (lines * lineHeight).clamp(constraints.minHeight, constraints.maxHeight);
    return NeonSize(width, height);
  }

  @override
  void performPaint(NeonCanvas canvas) {
    canvas.drawText(text, NeonOffset.zero, style: style);
  }
}

/// Render object for a box container with optional color, padding, and margin.
class RenderContainer extends NeonRenderObject {
  final double? fixedWidth;
  final double? fixedHeight;
  final NeonColor? color;
  final NeonEdgeInsets padding;
  final NeonEdgeInsets margin;

  /// Creates a container render object with optional fixed dimensions and styling.
  RenderContainer({
    this.fixedWidth,
    this.fixedHeight,
    this.color,
    this.padding = NeonEdgeInsets.zero,
    this.margin = NeonEdgeInsets.zero,
  });

  @override
  NeonSize performLayout(NeonConstraints constraints) {
    final horizontalPadding = padding.left + padding.right;
    final verticalPadding = padding.top + padding.bottom;
    final horizontalMargin = margin.left + margin.right;
    final verticalMargin = margin.top + margin.bottom;

    final innerMaxWidth =
        (fixedWidth ?? constraints.maxWidth) - horizontalPadding - horizontalMargin;
    final innerMaxHeight =
        (fixedHeight ?? constraints.maxHeight) - verticalPadding - verticalMargin;

    final childConstraints = NeonConstraints(
      minWidth: 0,
      maxWidth: innerMaxWidth > 0 ? innerMaxWidth : 0,
      minHeight: 0,
      maxHeight: innerMaxHeight > 0 ? innerMaxHeight : 0,
    );

    double contentWidth = 0;
    double contentHeight = 0;

    for (final child in children) {
      child.layout(childConstraints);
      child.relativeOffset = NeonOffset(
        margin.left + padding.left,
        margin.top + padding.top + contentHeight,
      );
      contentWidth =
          contentWidth > child.size.width ? contentWidth : child.size.width;
      contentHeight += child.size.height;
    }

    final width = fixedWidth ??
        (contentWidth + horizontalPadding + horizontalMargin)
            .clamp(constraints.minWidth, constraints.maxWidth);
    final height = fixedHeight ??
        (contentHeight + verticalPadding + verticalMargin)
            .clamp(constraints.minHeight, constraints.maxHeight);

    return NeonSize(width, height);
  }

  @override
  void performPaint(NeonCanvas canvas) {
    if (color != null) {
      canvas.drawRect(
        NeonRect(
          margin.left,
          margin.top,
          size.width - margin.left - margin.right,
          size.height - margin.top - margin.bottom,
        ),
        color: color!,
      );
    }
    for (final child in children) {
      child.paint(canvas);
    }
  }
}

/// Render object that arranges children vertically in a column.
class RenderColumn extends NeonRenderObject {
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  /// Creates a column render object with the given alignment settings.
  RenderColumn({
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  NeonSize performLayout(NeonConstraints constraints) {
    final childConstraints = constraints.loosen();

    double totalHeight = 0;
    double maxWidth = 0;

    for (final child in children) {
      if (crossAxisAlignment == CrossAxisAlignment.stretch &&
          constraints.hasBoundedWidth) {
        child.layout(childConstraints.copyWith(
          minWidth: constraints.maxWidth,
          maxWidth: constraints.maxWidth,
        ));
      } else {
        child.layout(childConstraints);
      }
      maxWidth = maxWidth > child.size.width ? maxWidth : child.size.width;
      totalHeight += child.size.height;
    }

    final width = maxWidth.clamp(constraints.minWidth, constraints.maxWidth);
    final height =
        totalHeight.clamp(constraints.minHeight, constraints.maxHeight);

    _positionChildren(width, height, totalHeight);

    return NeonSize(width, height);
  }

  void _positionChildren(
      double containerWidth, double containerHeight, double totalHeight) {
    double currentY = 0;

    switch (mainAxisAlignment) {
      case MainAxisAlignment.start:
        currentY = 0;
        break;
      case MainAxisAlignment.end:
        currentY = containerHeight - totalHeight;
        break;
      case MainAxisAlignment.center:
        currentY = (containerHeight - totalHeight) / 2;
        break;
      case MainAxisAlignment.spaceBetween:
      case MainAxisAlignment.spaceAround:
      case MainAxisAlignment.spaceEvenly:
        currentY = 0;
        break;
    }

    final spacing =
        _calculateSpacing(containerHeight, totalHeight, children.length);

    if (mainAxisAlignment == MainAxisAlignment.spaceEvenly) {
      currentY += spacing;
    } else if (mainAxisAlignment == MainAxisAlignment.spaceAround) {
      currentY += spacing / 2;
    }

    for (final child in children) {
      double childX;
      switch (crossAxisAlignment) {
        case CrossAxisAlignment.start:
          childX = 0;
          break;
        case CrossAxisAlignment.end:
          childX = containerWidth - child.size.width;
          break;
        case CrossAxisAlignment.center:
          childX = (containerWidth - child.size.width) / 2;
          break;
        case CrossAxisAlignment.stretch:
          childX = 0;
          break;
      }
      child.relativeOffset = NeonOffset(childX, currentY);
      currentY += child.size.height;

      if (mainAxisAlignment == MainAxisAlignment.spaceBetween ||
          mainAxisAlignment == MainAxisAlignment.spaceAround ||
          mainAxisAlignment == MainAxisAlignment.spaceEvenly) {
        currentY += spacing;
      }
    }
  }

  double _calculateSpacing(
      double containerHeight, double totalHeight, int childCount) {
    if (childCount <= 1) return 0;
    final freeSpace = containerHeight - totalHeight;
    if (freeSpace <= 0) return 0;

    switch (mainAxisAlignment) {
      case MainAxisAlignment.spaceBetween:
        return freeSpace / (childCount - 1);
      case MainAxisAlignment.spaceAround:
        return freeSpace / childCount;
      case MainAxisAlignment.spaceEvenly:
        return freeSpace / (childCount + 1);
      default:
        return 0;
    }
  }

  @override
  void performPaint(NeonCanvas canvas) {
    for (final child in children) {
      child.paint(canvas);
    }
  }
}

/// Render object that arranges children horizontally in a row.
class RenderRow extends NeonRenderObject {
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  /// Creates a row render object with the given alignment settings.
  RenderRow({
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  NeonSize performLayout(NeonConstraints constraints) {
    final childConstraints = constraints.loosen();

    double totalWidth = 0;
    double maxHeight = 0;

    for (final child in children) {
      if (crossAxisAlignment == CrossAxisAlignment.stretch &&
          constraints.hasBoundedHeight) {
        child.layout(childConstraints.copyWith(
          minHeight: constraints.maxHeight,
          maxHeight: constraints.maxHeight,
        ));
      } else {
        child.layout(childConstraints);
      }
      maxHeight =
          maxHeight > child.size.height ? maxHeight : child.size.height;
      totalWidth += child.size.width;
    }

    final width = totalWidth.clamp(constraints.minWidth, constraints.maxWidth);
    final height =
        maxHeight.clamp(constraints.minHeight, constraints.maxHeight);

    _positionChildren(width, height, totalWidth);

    return NeonSize(width, height);
  }

  void _positionChildren(
      double containerWidth, double containerHeight, double totalWidth) {
    double currentX = 0;

    switch (mainAxisAlignment) {
      case MainAxisAlignment.start:
        currentX = 0;
        break;
      case MainAxisAlignment.end:
        currentX = containerWidth - totalWidth;
        break;
      case MainAxisAlignment.center:
        currentX = (containerWidth - totalWidth) / 2;
        break;
      case MainAxisAlignment.spaceBetween:
      case MainAxisAlignment.spaceAround:
      case MainAxisAlignment.spaceEvenly:
        currentX = 0;
        break;
    }

    final spacing =
        _calculateSpacing(containerWidth, totalWidth, children.length);

    if (mainAxisAlignment == MainAxisAlignment.spaceEvenly) {
      currentX += spacing;
    } else if (mainAxisAlignment == MainAxisAlignment.spaceAround) {
      currentX += spacing / 2;
    }

    for (final child in children) {
      double childY;
      switch (crossAxisAlignment) {
        case CrossAxisAlignment.start:
          childY = 0;
          break;
        case CrossAxisAlignment.end:
          childY = containerHeight - child.size.height;
          break;
        case CrossAxisAlignment.center:
          childY = (containerHeight - child.size.height) / 2;
          break;
        case CrossAxisAlignment.stretch:
          childY = 0;
          break;
      }
      child.relativeOffset = NeonOffset(currentX, childY);
      currentX += child.size.width;

      if (mainAxisAlignment == MainAxisAlignment.spaceBetween ||
          mainAxisAlignment == MainAxisAlignment.spaceAround ||
          mainAxisAlignment == MainAxisAlignment.spaceEvenly) {
        currentX += spacing;
      }
    }
  }

  double _calculateSpacing(
      double containerWidth, double totalWidth, int childCount) {
    if (childCount <= 1) return 0;
    final freeSpace = containerWidth - totalWidth;
    if (freeSpace <= 0) return 0;

    switch (mainAxisAlignment) {
      case MainAxisAlignment.spaceBetween:
        return freeSpace / (childCount - 1);
      case MainAxisAlignment.spaceAround:
        return freeSpace / childCount;
      case MainAxisAlignment.spaceEvenly:
        return freeSpace / (childCount + 1);
      default:
        return 0;
    }
  }

  @override
  void performPaint(NeonCanvas canvas) {
    for (final child in children) {
      child.paint(canvas);
    }
  }
}

/// Render object that layers children on top of each other.
class RenderStack extends NeonRenderObject {
  final StackFit fit;

  /// Creates a stack render object with the given fit behavior.
  RenderStack({this.fit = StackFit.loose});

  @override
  NeonSize performLayout(NeonConstraints constraints) {
    double maxWidth = 0;
    double maxHeight = 0;

    final childConstraints = fit == StackFit.expand
        ? NeonConstraints.tight(constraints.biggest)
        : constraints.loosen();

    for (final child in children) {
      child.layout(childConstraints);
      child.relativeOffset = NeonOffset.zero;
      maxWidth = maxWidth > child.size.width ? maxWidth : child.size.width;
      maxHeight =
          maxHeight > child.size.height ? maxHeight : child.size.height;
    }

    return NeonSize(
      maxWidth.clamp(constraints.minWidth, constraints.maxWidth),
      maxHeight.clamp(constraints.minHeight, constraints.maxHeight),
    );
  }

  @override
  void performPaint(NeonCanvas canvas) {
    for (final child in children) {
      child.paint(canvas);
    }
  }
}

import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/button.dart';
import 'package:neon_framework/src/widgets/primitives.dart';
import 'package:neon_framework/src/widgets/text.dart';

/// A Material 3 Filled Button.
class FilledButton extends NeonWidget {
  final NeonWidget child;
  final NeonVoidCallback? onPressed;
  final NeonColor? color;

  const FilledButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    NeonWidget effectiveChild = child;
    if (child is Text) {
      final t = child as Text;
      if (t.style.color == NeonColor.black) {
        effectiveChild = Text(
          t.data,
          style: NeonTextStyle(
            fontSize: t.style.fontSize,
            color: NeonColor.white,
            fontWeight: t.style.fontWeight == NeonFontWeight.normal
                ? NeonFontWeight.bold
                : t.style.fontWeight,
          ),
        );
      }
    }
    return Button(
      key: key,
      onPressed: onPressed,
      color: color ?? NeonColor.primary,
      child: effectiveChild,
    );
  }
}

/// A Material 3 Filled Tonal Button.
class FilledTonalButton extends NeonWidget {
  final NeonWidget child;
  final NeonVoidCallback? onPressed;

  const FilledTonalButton({
    super.key,
    required this.child,
    this.onPressed,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return Button(
      key: key,
      onPressed: onPressed,
      color: const NeonColor(0xFFEADDFF), // Tonal secondary container
      child: child,
    );
  }
}

/// A Material 3 Elevated Button.
class ElevatedButton extends NeonWidget {
  final NeonWidget child;
  final NeonVoidCallback? onPressed;

  const ElevatedButton({
    super.key,
    required this.child,
    this.onPressed,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return Button(
      key: key,
      onPressed: onPressed,
      color: NeonColor.white,
      child: child,
    );
  }
}

/// A Material 3 Outlined Button.
class OutlinedButton extends NeonWidget {
  final NeonWidget child;
  final NeonVoidCallback? onPressed;

  const OutlinedButton({
    super.key,
    required this.child,
    this.onPressed,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return Button(
      onPressed: onPressed,
      color: NeonColor.transparent,
      child: child,
    );
  }
}

/// A Material 3 Text Button.
class TextButton extends NeonWidget {
  final NeonWidget child;
  final NeonVoidCallback? onPressed;

  const TextButton({
    super.key,
    required this.child,
    this.onPressed,
  });

  @override
  NeonWidget build(NeonBuildContext context) {
    return Button(
      onPressed: onPressed,
      color: NeonColor.transparent,
      child: child,
    );
  }
}

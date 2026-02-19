import 'package:neon_framework/src/widgets/widget.dart';
import 'package:neon_framework/src/widgets/build_context.dart';
import 'package:neon_framework/src/widgets/button.dart';
import 'package:neon_framework/src/widgets/primitives.dart';

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
    return Button(
      key: key,
      onPressed: onPressed,
      color: color ?? NeonColor.blue,
      child: child,
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

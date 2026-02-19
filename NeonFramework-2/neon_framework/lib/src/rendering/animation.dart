/// Represents the current status of an animation.
enum NeonAnimationStatus {
  idle,
  running,
  completed,
  dismissed,
}

/// Abstract controller for managing animation playback.
abstract class NeonAnimationController {
  /// The current status of the animation.
  NeonAnimationStatus get status;

  /// The current value of the animation, typically between 0.0 and 1.0.
  double get value;

  /// Starts playing the animation forward.
  void forward();

  /// Starts playing the animation in reverse.
  void reverse();

  /// Stops the animation at its current value.
  void stop();

  /// Resets the animation to its initial state.
  void reset();

  /// Releases resources used by the controller.
  void dispose();
}

/// Holds the begin/end values and current progress of an animation.
class NeonAnimationValue<T> {
  final T begin;
  final T end;
  final double progress;

  const NeonAnimationValue({
    required this.begin,
    required this.end,
    this.progress = 0.0,
  });

  /// Returns a new animation value with the given progress, clamped to [0.0, 1.0].
  NeonAnimationValue<T> withProgress(double newProgress) {
    return NeonAnimationValue<T>(
      begin: begin,
      end: end,
      progress: newProgress.clamp(0.0, 1.0),
    );
  }

  /// Whether the animation has reached its end.
  bool get isComplete => progress >= 1.0;

  /// Whether the animation is at its starting point.
  bool get isAtStart => progress <= 0.0;

  @override
  String toString() =>
      'NeonAnimationValue($begin -> $end, progress: $progress)';
}

/// Represents a duration of time in milliseconds.
class NeonDuration {
  final int milliseconds;

  const NeonDuration({this.milliseconds = 300});

  /// Creates a duration from a millisecond value.
  const NeonDuration.ms(this.milliseconds);

  /// Zero duration.
  static const NeonDuration zero = NeonDuration(milliseconds: 0);

  /// A fast 150ms duration.
  static const NeonDuration fast = NeonDuration(milliseconds: 150);

  /// A normal 300ms duration.
  static const NeonDuration normal = NeonDuration(milliseconds: 300);

  /// A slow 500ms duration.
  static const NeonDuration slow = NeonDuration(milliseconds: 500);

  @override
  String toString() => 'NeonDuration(${milliseconds}ms)';
}

/// An animation curve that maps input time [0.0, 1.0] to output progress.
abstract class NeonCurve {
  /// Transforms a linear time value to a curved progress value.
  double transform(double t);
}

/// A linear curve with no easing.
class NeonLinearCurve implements NeonCurve {
  const NeonLinearCurve();

  @override
  double transform(double t) => t;
}

/// A curve that starts slowly and accelerates.
class NeonEaseInCurve implements NeonCurve {
  const NeonEaseInCurve();

  @override
  double transform(double t) => t * t;
}

/// A curve that starts fast and decelerates.
class NeonEaseOutCurve implements NeonCurve {
  const NeonEaseOutCurve();

  @override
  double transform(double t) => 1 - (1 - t) * (1 - t);
}

/// A curve that eases in and out with smooth acceleration and deceleration.
class NeonEaseInOutCurve implements NeonCurve {
  const NeonEaseInOutCurve();

  @override
  double transform(double t) =>
      t < 0.5 ? 2 * t * t : 1 - (-2 * t + 2) * (-2 * t + 2) / 2;
}

/// Provides predefined animation curve constants.
class NeonCurves {
  /// Linear interpolation with no easing.
  static const NeonCurve linear = NeonLinearCurve();

  /// Ease-in curve (slow start).
  static const NeonCurve easeIn = NeonEaseInCurve();

  /// Ease-out curve (slow end).
  static const NeonCurve easeOut = NeonEaseOutCurve();

  /// Ease-in-out curve (slow start and end).
  static const NeonCurve easeInOut = NeonEaseInOutCurve();
}

/// Simulates spring physics for animations.
class NeonSpringSimulation {
  final double stiffness;
  final double damping;
  final double mass;

  const NeonSpringSimulation({
    this.stiffness = 100.0,
    this.damping = 10.0,
    this.mass = 1.0,
  });

  @override
  String toString() =>
      'NeonSpringSimulation(stiffness: $stiffness, damping: $damping, mass: $mass)';
}

import 'dart:math' as math;

/// Industrial Math Utilities for Scroll-Driven Animation
/// Maps raw scroll offsets to normalized animation values.
class ScrollUtils {
  /// Linearly interpolates a value from [inputRange] to [outputRange].
  /// Clamps the result by default to ensure values stay within expected bounds.
  static double interpolate(
    double value, {
    required List<double> inputRange,
    required List<double> outputRange,
    bool clamp = true,
  }) {
    if (inputRange.length != outputRange.length || inputRange.length < 2) {
      return outputRange.first;
    }

    // Find the current segment
    int i = 0;
    while (i < inputRange.length - 2 && value > inputRange[i + 1]) {
      i++;
    }

    final double x0 = inputRange[i];
    final double x1 = inputRange[i + 1];
    final double y0 = outputRange[i];
    final double y1 = outputRange[i + 1];

    if (x0 == x1) return y0;

    double result = y0 + (value - x0) * (y1 - y0) / (x1 - x0);

    if (clamp) {
      final double minOutput = math.min(y0, y1);
      final double maxOutput = math.max(y0, y1);
      result = result.clamp(minOutput, maxOutput);
    }

    return result;
  }

  /// Specialized opacity mapper for scroll storytelling.
  /// Transitions from [startOpacity] to [endOpacity] over [startOffset] to [endOffset].
  static double getOpacity(double offset, double startOffset, double endOffset, {double startOpacity = 1.0, double endOpacity = 0.0}) {
    return interpolate(
      offset,
      inputRange: [startOffset, endOffset],
      outputRange: [startOpacity, endOpacity],
    );
  }

  /// Calculates a parallax translation value.
  /// [speed] > 1 moves faster than scroll, [speed] < 1 moves slower (standard parallax).
  static double getTranslateY(double offset, double speed) {
    return offset * (1 - speed);
  }

  /// Maps scroll progress to a scale factor.
  static double getScale(double offset, double startOffset, double endOffset, {double startScale = 1.0, double endScale = 0.8}) {
    return interpolate(
      offset,
      inputRange: [startOffset, endOffset],
      outputRange: [startScale, endScale],
    );
  }
}

import 'package:flutter/animation.dart';

class GritAnimations {
  GritAnimations._();

  /// Snappy, high-velocity deceleration for industrial feel.
  static const Curve mechanicalCurve = Curves.easeOutExpo;

  /// Standard duration for micro-interactions and page transitions.
  static const Duration mechanicalDuration = Duration(milliseconds: 250);
}

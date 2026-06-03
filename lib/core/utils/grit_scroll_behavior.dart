import 'package:flutter/material.dart';
import '../utils/haptics.dart';

/// Custom scroll behavior for GRIT.
///
/// Disables the default Android stretch/glow effect and enforces
/// a consistent feel with a subdued bounce and haptic feedback.
class GritScrollBehavior extends ScrollBehavior {
  const GritScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // Disable the visual stretch effect entirely for a cleaner look.
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Use a custom dampened bounce for a "just right" premium feel.
    return const GritMutedBouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics());
  }
}

/// A highly dampened bouncing physics for a "premium" feel.
/// It allows a small amount of movement at the boundaries without
/// the floaty displacement of standard BouncingScrollPhysics.
class GritMutedBouncingScrollPhysics extends BouncingScrollPhysics {
  const GritMutedBouncingScrollPhysics({super.parent});

  @override
  GritMutedBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return GritMutedBouncingScrollPhysics(parent: buildParent(ancestor));
  }

  // Silk-smooth critically damped spring ($ \zeta \approx 1.0 $).
  // Snaps back immediately without oscillation.
  @override
  SpringDescription get spring => const SpringDescription(
        mass: 1.0,
        stiffness: 600.0,
        damping: 50.0,
      );

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (!position.outOfRange) return offset;

    final double overscroll = (position.pixels < position.minScrollExtent
            ? position.minScrollExtent - position.pixels
            : position.pixels - position.maxScrollExtent)
        .abs();

    // Asymptotic friction curve: resistance increases proportionally
    // to distance, but never hits an absolute "wall".
    // This eliminates the mechanical jitter seen with capped curves.
    double friction = 0.15 / (1.0 + (overscroll / 20.0));
    return offset * friction;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) => 0.0;
}

/// An optimized wrapper for haptics at scroll boundaries.
/// Uses a latch-based trigger to avoid native bridge overhead.
class HapticScrollWrapper extends StatefulWidget {
  final Widget child;
  const HapticScrollWrapper({super.key, required this.child});

  @override
  State<HapticScrollWrapper> createState() => _HapticScrollWrapperState();
}

class _HapticScrollWrapperState extends State<HapticScrollWrapper> {
  bool _hasHitEdge = false;
  DateTime? _lastHaptic;

  void _triggerHaptic() {
    final now = DateTime.now();
    // Maximum frequency of haptics (once per 500ms) to preserve UI thread performance.
    if (_lastHaptic == null ||
        now.difference(_lastHaptic!) > const Duration(milliseconds: 500)) {
      _lastHaptic = now;
      GritHaptics.scrollLimit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is OverscrollNotification) {
          // Latch the edge hit to fire haptics exactly once per overscroll event.
          if (!_hasHitEdge) {
            _hasHitEdge = true;
            _triggerHaptic();
          }
        } else if (notification is ScrollEndNotification ||
            (notification is ScrollUpdateNotification &&
                !notification.metrics.outOfRange)) {
          // Reset latch when back in range or scroll ends.
          _hasHitEdge = false;
        }
        return false;
      },
      child: widget.child,
    );
  }
}

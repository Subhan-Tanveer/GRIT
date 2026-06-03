import 'package:flutter/material.dart';
import '../../core/utils/scroll_utils.dart';

/// Reusable wrapper that maps scroll progress to opacity and scale.
/// Ideal for "Hero" sections that fade out as they leave the top of the screen.
class FadeOnScroll extends StatelessWidget {
  final ScrollController scrollController;
  final double zeroOpacityOffset;
  final double fullOpacityOffset;
  final Widget child;

  const FadeOnScroll({
    super.key,
    required this.scrollController,
    required this.child,
    this.zeroOpacityOffset = 150,
    this.fullOpacityOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final double offset = scrollController.hasClients ? scrollController.offset : 0;
        final double opacity = ScrollUtils.getOpacity(
          offset,
          fullOpacityOffset,
          zeroOpacityOffset,
        );
        final double scale = ScrollUtils.getScale(
          offset,
          fullOpacityOffset,
          zeroOpacityOffset,
          startScale: 1.0,
          endScale: 0.9,
        );

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Applies a vertical parallax translation based on scroll offset.
class ParallaxWidget extends StatelessWidget {
  final ScrollController scrollController;
  final double speed;
  final Widget child;

  const ParallaxWidget({
    super.key,
    required this.scrollController,
    required this.child,
    this.speed = 0.5, // 0.5 means it moves at half the scroll speed
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final double offset = scrollController.hasClients ? scrollController.offset : 0;
        final double translation = ScrollUtils.getTranslateY(offset, speed);

        return Transform.translate(
          offset: Offset(0, translation),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// A high-density industrial wrapper for viewport-triggered entry animations.
/// It detects when a widget enters the viewport and fires a smooth transition.
class ScrollAnimatedWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double triggerOffset; // Distance from bottom of viewport to trigger

  const ScrollAnimatedWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.triggerOffset = 100,
  });

  @override
  State<ScrollAnimatedWidget> createState() => _ScrollAnimatedWidgetState();
}

class _ScrollAnimatedWidgetState extends State<ScrollAnimatedWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _slide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility() {
    if (_hasTriggered) return;
    
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return;

    final double widgetTop = renderObject.localToGlobal(Offset.zero).dy;
    final double viewportHeight = MediaQuery.of(context).size.height;

    if (widgetTop < viewportHeight - widget.triggerOffset) {
      _hasTriggered = true;
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use a NotificationListener or simple layout triggers for this.
    // For simplicity and 60fps, we'll use a post-frame callback logic.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: FractionalTranslation(
            translation: _slide.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A generic delegate for SliverPersistentHeader to create sticky headers.
class SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  SliverHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant SliverHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

import 'package:flutter/material.dart';

class GritSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const GritSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 24.0,
    this.borderRadius = 0,
  });

  @override
  State<GritSkeleton> createState() => _GritSkeletonState();
}

class _GritSkeletonState extends State<GritSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .dividerColor
                .withAlpha((_animation.value * 255).toInt()),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

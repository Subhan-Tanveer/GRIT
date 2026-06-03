import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../core/utils/haptics.dart';

class SlideToDiscard extends StatefulWidget {
  final Future<void> Function() onDiscard;
  const SlideToDiscard({super.key, required this.onDiscard});

  @override
  State<SlideToDiscard> createState() => _SlideToDiscardState();
}

class _SlideToDiscardState extends State<SlideToDiscard> with SingleTickerProviderStateMixin {
  double _dragValue = 0.0;
  static const double _maxDragThreshold = 0.9;
  bool _isTriggered = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resetAnimation = _resetController.drive(CurveTween(curve: Curves.easeOutQuint));
    _resetController.addListener(() {
      setState(() {
        _dragValue = _resetAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _reset() {
    if (!mounted) return;
    _resetController.value = _dragValue;
    _resetController.reverse();
    setState(() {
      _isTriggered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final handleWidth = 64.0;
      final trackWidth = width - handleWidth;

      final grit = Theme.of(context).grit;

      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: grit.surface2,
          border: Border.all(
            color: grit.border,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Satisfying Progress Fill with Soft Glow
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: (_dragValue * trackWidth) + (handleWidth / 2),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      grit.accent.withValues(alpha: 0.25 * _dragValue),
                      grit.accent.withValues(alpha: 0.1 * _dragValue),
                    ],
                  ),
                ),
              ),
            ),

            // Instruction Text (Removed text overlay to achieve a cleaner, self-explanatory aesthetic)

            // Sliding Handle
            Positioned(
              left: _dragValue * trackWidth,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (_isTriggered || _resetController.isAnimating) return;
                  setState(() {
                    _dragValue = (_dragValue + details.delta.dx / trackWidth).clamp(0.0, 1.0);
                  });
                  
                  if (_dragValue > 0.85 && _dragValue < 0.95) {
                    GritHaptics.selectionTick();
                  }
                },
                onHorizontalDragEnd: (details) async {
                  if (_isTriggered || _resetController.isAnimating) return;

                  if (_dragValue >= _maxDragThreshold) {
                    setState(() {
                      _dragValue = 1.0;
                      _isTriggered = true;
                    });
                    await GritHaptics.heavyImpact();
                    
                    await widget.onDiscard();
                    
                    if (mounted) {
                      _reset();
                    }
                  } else {
                    _reset();
                  }
                },
                child: AnimatedScale(
                  scale: _dragValue > 0 && !_isTriggered && !_resetController.isAnimating ? 1.03 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: handleWidth,
                    color: grit.accent,
                    child: Center(
                      child: Icon(
                        PhosphorIcons.trash(PhosphorIconsStyle.bold),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

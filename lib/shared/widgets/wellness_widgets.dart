import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/grit_theme.dart';
import '../../utils/wellness.dart';

class ReadinessGauge extends StatefulWidget {
  final int score;
  final double size;

  const ReadinessGauge({super.key, required this.score, this.size = 220});

  @override
  State<ReadinessGauge> createState() => _ReadinessGaugeState();
}

class _ReadinessGaugeState extends State<ReadinessGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _animation = Tween<double>(begin: 0, end: widget.score.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(ReadinessGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: oldWidget.score.toDouble(), end: widget.score.toDouble())
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _colorForScore(int score, GritThemeData grit) {
    if (score >= 80) return grit.success;
    if (score >= 60) return grit.accent;
    if (score >= 40) return grit.warning;
    return grit.failureSet;
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        final color = _colorForScore(value.round(), grit);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _GaugePainter(
              value: value,
              trackColor: grit.surface2,
              progressColor: color,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.round().toString(),
                    style: GritTextStyles.displayMedium().copyWith(color: grit.textPrimary),
                  ),
                  Text(
                    WellnessCalc.readinessLabel(value.round()),
                    style: GritTextStyles.labelMicro().copyWith(color: color, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0-100
  final Color trackColor;
  final Color progressColor;

  _GaugePainter({required this.value, required this.trackColor, required this.progressColor});

  static const double _startAngle = math.pi * 0.75;
  static const double _sweepAngle = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepAngle,
      false,
      trackPaint,
    );

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepAngle * (value / 100).clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.progressColor != progressColor;
}

enum _BreathPhase { inhale, hold, exhale }

class BreathingExercise extends StatefulWidget {
  const BreathingExercise({super.key});

  @override
  State<BreathingExercise> createState() => _BreathingExerciseState();
}

class _BreathingExerciseState extends State<BreathingExercise> with SingleTickerProviderStateMixin {
  static const _inhaleSeconds = 4;
  static const _holdSeconds = 7;
  static const _exhaleSeconds = 8;

  late AnimationController _scaleController;
  _BreathPhase _phase = _BreathPhase.inhale;
  int _secondsLeft = _inhaleSeconds;
  bool _running = false;
  Object? _cycleToken;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(vsync: this, duration: const Duration(seconds: _inhaleSeconds));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    final token = Object();
    _cycleToken = token;
    _runPhase(_BreathPhase.inhale, token);
  }

  void _stop() {
    setState(() {
      _running = false;
      _phase = _BreathPhase.inhale;
      _secondsLeft = _inhaleSeconds;
    });
    _cycleToken = null;
    _scaleController.stop();
    _scaleController.value = 0;
  }

  Future<void> _runPhase(_BreathPhase phase, Object token) async {
    if (!mounted || _cycleToken != token) return;

    final duration = switch (phase) {
      _BreathPhase.inhale => _inhaleSeconds,
      _BreathPhase.hold => _holdSeconds,
      _BreathPhase.exhale => _exhaleSeconds,
    };

    setState(() {
      _phase = phase;
      _secondsLeft = duration;
    });

    if (phase == _BreathPhase.inhale) {
      _scaleController.duration = Duration(seconds: duration);
      _scaleController.forward(from: 0);
    } else if (phase == _BreathPhase.exhale) {
      _scaleController.duration = Duration(seconds: duration);
      _scaleController.reverse(from: 1);
    }

    for (int i = duration - 1; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || _cycleToken != token) return;
      setState(() => _secondsLeft = i);
    }

    if (!mounted || _cycleToken != token) return;

    final next = switch (phase) {
      _BreathPhase.inhale => _BreathPhase.hold,
      _BreathPhase.hold => _BreathPhase.exhale,
      _BreathPhase.exhale => _BreathPhase.inhale,
    };
    _runPhase(next, token);
  }

  String get _phaseLabel => switch (_phase) {
        _BreathPhase.inhale => 'INHALE',
        _BreathPhase.hold => 'HOLD',
        _BreathPhase.exhale => 'EXHALE',
      };

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;

    return Column(
      children: [
        GestureDetector(
          onTap: _running ? _stop : _start,
          child: AnimatedBuilder(
            animation: _scaleController,
            builder: (context, child) {
              final scale = 0.55 + (_scaleController.value * 0.45);
              return SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              grit.accent.withValues(alpha: 0.35),
                              grit.accent.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: grit.accent.withValues(alpha: 0.15),
                          border: Border.all(color: grit.accent, width: 2),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _running ? _phaseLabel : 'TAP TO START',
                          style: GritTextStyles.label(13, weight: FontWeight.w800, color: grit.textPrimary, letterSpacing: 2),
                        ),
                        if (_running) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$_secondsLeft',
                            style: GritTextStyles.displayMedium().copyWith(color: grit.textPrimary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '4-7-8 BREATHING',
          style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 2),
        ),
      ],
    );
  }
}

class MoodSelector extends StatelessWidget {
  final int selectedMood; // 1-5
  final ValueChanged<int> onSelected;

  const MoodSelector({super.key, required this.selectedMood, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final moodValue = index + 1;
        final isSelected = moodValue == selectedMood;
        return GestureDetector(
          onTap: () => onSelected(moodValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? grit.accent.withValues(alpha: 0.12) : Colors.transparent,
              border: Border.all(color: isSelected ? grit.accent : grit.border, width: isSelected ? 1.5 : 1),
            ),
            child: Column(
              children: [
                Text(moodEmojis[index], style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 4),
                Text(
                  moodLabels[index],
                  style: GritTextStyles.labelMicro().copyWith(
                    fontSize: 8,
                    color: isSelected ? grit.accent : grit.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

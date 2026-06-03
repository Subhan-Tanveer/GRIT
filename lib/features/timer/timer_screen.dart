import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../providers/workout_timer_provider.dart';
import '../../services/notification_service.dart';

class StandardTimerScreen extends ConsumerWidget {
  const StandardTimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(workoutTimerProvider);
    final timerNotifier = ref.read(workoutTimerProvider.notifier);
    final grit = Theme.of(context).grit;

    return Scaffold(
      backgroundColor: grit.background,
      appBar: AppBar(
        backgroundColor: grit.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), size: 20, color: grit.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text('TIMER',
            style: GritTextStyles.metric(
              22,
              weight: FontWeight.w800,
              color: grit.textPrimary,
              letterSpacing: 0.0,
            )),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: grit.border),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Mode Selector
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _ModeSelector(
                          currentMode: timerState.chronoMode,
                          onChanged: (mode) {
                            GritHaptics.buttonTap();
                            timerNotifier.setChronoMode(mode);
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      // The Main Display
                      _ChronoMainDisplay(state: timerState, notifier: timerNotifier),
                      const SizedBox(height: 28),
                      // Dynamic Bottom Section
                      Expanded(
                        child: timerState.chronoMode == ChronoMode.timer
                            ? _TimerControls(state: timerState, notifier: timerNotifier)
                            : _StopwatchControls(state: timerState, notifier: timerNotifier),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  MAIN GAUGE
// ──────────────────────────────────────────────────────────────────────────────

class _ChronoMainDisplay extends StatelessWidget {
  final WorkoutTimerState state;
  final WorkoutTimerNotifier notifier;

  const _ChronoMainDisplay({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final bool isRunning = state.chronoMode == ChronoMode.timer
        ? state.isChronoRunning
        : state.isStopwatchRunning;

    final String timeLabel = state.chronoMode == ChronoMode.timer
        ? state.formatTime(state.chronoSecondsRemaining)
        : _formatStopwatch(state.stopwatchSeconds);

    final double progress = state.chronoMode == ChronoMode.timer
        ? state.timerProgress
        : 0.0;

    final grit = Theme.of(context).grit;

    return Center(
      child: GestureDetector(
        onTap: () async {
          GritHaptics.buttonTap();
          if (state.chronoMode == ChronoMode.timer) {
            if (!state.isChronoRunning) {
              NotificationService().requestPermissions().ignore();
            }
            notifier.toggleChronoTimer();
          } else {
            if (!state.isStopwatchRunning) {
              NotificationService().requestPermissions().ignore();
            }
            notifier.toggleStopwatch();
          }
        },
        child: SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(240, 240),
                painter: _MinimalCirclePainter(
                  progress: progress,
                  trackColor: grit.border,
                  progressColor: grit.accent,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    state.chronoMode == ChronoMode.timer ? 'TIMER' : 'STOPWATCH',
                    style: GritTextStyles.mono(10,
                      weight: FontWeight.w800,
                      color: grit.muted,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeLabel,
                    style: GritTextStyles.mono(
                      40,
                      weight: FontWeight.w900,
                      color: isRunning ? grit.accent : grit.textPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        color: isRunning ? grit.accent : grit.border,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRunning ? 'RUNNING' : 'PAUSED',
                        style: GritTextStyles.mono(9,
                          weight: FontWeight.w800,
                          color: isRunning ? grit.accent : grit.muted,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRunning
                        ? 'TAP TO PAUSE'
                        : (state.chronoSecondsRemaining == state.chronoInitialSeconds && state.chronoMode == ChronoMode.timer
                            ? 'TAP TO START'
                            : 'TAP TO RESUME'),
                    style: GritTextStyles.mono(8,
                      color: grit.muted.withValues(alpha: 0.6),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStopwatch(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _MinimalCirclePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _MinimalCirclePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.square;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.141592653589793 / 2,
        2 * 3.141592653589793 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MinimalCirclePainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}

// ──────────────────────────────────────────────────────────────────────────────
//  MODE SELECTOR
// ──────────────────────────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  final ChronoMode currentMode;
  final Function(ChronoMode) onChanged;

  const _ModeSelector({required this.currentMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: grit.surface,
        border: Border.all(color: grit.border, width: 1),
      ),
      child: Row(
        children: [
          _TabItem(
            label: "TIMER",
            icon: PhosphorIcons.timer(),
            isSelected: currentMode == ChronoMode.timer,
            onTap: () => onChanged(ChronoMode.timer),
          ),
          Container(width: 1, color: grit.border),
          _TabItem(
            label: "STOPWATCH",
            icon: PhosphorIcons.clock(),
            isSelected: currentMode == ChronoMode.stopwatch,
            onTap: () => onChanged(ChronoMode.stopwatch),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? grit.accent.withValues(alpha: 0.12) : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? grit.accent : grit.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GritTextStyles.metric(12,
                  weight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? grit.accent : grit.muted,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  STANDARD BUTTON
// ──────────────────────────────────────────────────────────────────────────────

class _StandardButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  final IconData? icon;

  const _StandardButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final bgColor = isPrimary
        ? grit.accent
        : grit.surface2;
    final fgColor = isPrimary
        ? Colors.white
        : grit.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: isPrimary
                ? grit.accent
                : grit.border,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GritTextStyles.metric(13,
                weight: FontWeight.w900,
                color: fgColor,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  TIMER CONTROLS
// ──────────────────────────────────────────────────────────────────────────────

class _TimerControls extends StatelessWidget {
  final WorkoutTimerState state;
  final WorkoutTimerNotifier notifier;

  const _TimerControls({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final bool isRunning = state.isChronoRunning;
    final grit = Theme.of(context).grit;

    return Column(
      children: [
        // Quick presets row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _PresetChip(label: '1M', seconds: 60, notifier: notifier, state: state),
              const SizedBox(width: 8),
              _PresetChip(label: '3M', seconds: 180, notifier: notifier, state: state),
              const SizedBox(width: 8),
              _PresetChip(label: '5M', seconds: 300, notifier: notifier, state: state),
              const SizedBox(width: 8),
              _PresetChip(label: '10M', seconds: 600, notifier: notifier, state: state),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Label
        Text('SET DURATION',
          style: GritTextStyles.labelMicro().copyWith(color: grit.muted, letterSpacing: 2)),
        const SizedBox(height: 12),
        // Spinner
        SizedBox(
          height: 160,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _TimerSpinner(
              currentSeconds: state.chronoInitialSeconds,
              onChanged: (val) {
                GritHaptics.selectionTick();
                notifier.setChronoTimer(val);
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Row(
            children: [
              Expanded(
                child: _StandardButton(
                  label: 'RESET',
                  icon: PhosphorIcons.arrowCounterClockwise(),
                  onTap: () {
                    GritHaptics.selectionTick();
                    notifier.resetChronoTimer();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StandardButton(
                  label: isRunning ? 'PAUSE' : (state.chronoSecondsRemaining < state.chronoInitialSeconds ? 'RESUME' : 'START'),
                  isPrimary: true,
                  icon: isRunning ? PhosphorIcons.pause() : PhosphorIcons.play(),
                  onTap: () async {
                    GritHaptics.buttonTap();
                    if (!isRunning) {
                      await NotificationService().requestPermissions();
                    }
                    notifier.toggleChronoTimer();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  PRESET CHIP
// ──────────────────────────────────────────────────────────────────────────────

class _PresetChip extends StatelessWidget {
  final String label;
  final int seconds;
  final WorkoutTimerNotifier notifier;
  final WorkoutTimerState state;

  const _PresetChip({
    required this.label,
    required this.seconds,
    required this.notifier,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final isActive = state.chronoInitialSeconds == seconds;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          GritHaptics.selectionTick();
          notifier.setChronoTimer(seconds);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? grit.accent.withValues(alpha: 0.12) : grit.surface,
            border: Border.all(
              color: isActive ? grit.accent : grit.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: GritTextStyles.metric(11,
              weight: FontWeight.w900,
              color: isActive ? grit.accent : grit.muted,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  STOPWATCH CONTROLS
// ──────────────────────────────────────────────────────────────────────────────

class _StopwatchControls extends StatelessWidget {
  final WorkoutTimerState state;
  final WorkoutTimerNotifier notifier;

  const _StopwatchControls({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final bool isRunning = state.isStopwatchRunning;
    final grit = Theme.of(context).grit;

    return Column(
      children: [
        // Lap list
        Expanded(
          child: state.laps.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.flag(), size: 28, color: grit.border),
                      const SizedBox(height: 12),
                      Text('NO LAPS YET',
                        style: GritTextStyles.mono(10,
                          color: grit.muted,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  itemCount: state.laps.length,
                  separatorBuilder: (_, __) => Divider(color: grit.border, height: 1),
                  itemBuilder: (context, index) {
                    final lapTime = state.laps[index];
                    final lapNumber = state.laps.length - index;
                    final isLatest = index == 0;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      color: isLatest ? grit.accent.withValues(alpha: 0.04) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isLatest ? grit.accent.withValues(alpha: 0.15) : grit.surface2,
                              border: Border.all(
                                color: isLatest ? grit.accent : grit.border,
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$lapNumber',
                              style: GritTextStyles.metric(10,
                                color: isLatest ? grit.accent : grit.muted,
                                weight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'LAP $lapNumber',
                            style: GritTextStyles.label(12).copyWith(
                              color: isLatest ? grit.textPrimary : grit.textSecondary,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            state.formatTime(lapTime),
                            style: GritTextStyles.mono(18,
                              color: isLatest ? grit.accent : grit.textPrimary,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Action row
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Row(
            children: [
              Expanded(
                child: _StandardButton(
                  label: 'RESET',
                  icon: PhosphorIcons.arrowCounterClockwise(),
                  onTap: () {
                    GritHaptics.selectionTick();
                    notifier.resetStopwatch();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StandardButton(
                  label: 'LAP',
                  icon: PhosphorIcons.flag(),
                  onTap: () {
                    GritHaptics.selectionTick();
                    notifier.recordLap();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StandardButton(
                  label: isRunning ? 'PAUSE' : 'START',
                  isPrimary: true,
                  icon: isRunning ? PhosphorIcons.pause() : PhosphorIcons.play(),
                  onTap: () async {
                    GritHaptics.buttonTap();
                    if (!isRunning) {
                      await NotificationService().requestPermissions();
                    }
                    notifier.toggleStopwatch();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  TIMER SPINNER (H/M/S wheel picker)
// ──────────────────────────────────────────────────────────────────────────────

class _TimerSpinner extends StatefulWidget {
  final int currentSeconds;
  final ValueChanged<int> onChanged;

  const _TimerSpinner({required this.currentSeconds, required this.onChanged});

  @override
  State<_TimerSpinner> createState() => _TimerSpinnerState();
}

class _TimerSpinnerState extends State<_TimerSpinner> {
  late FixedExtentScrollController _hController;
  late FixedExtentScrollController _mController;
  late FixedExtentScrollController _sController;

  @override
  void initState() {
    super.initState();
    final h = widget.currentSeconds ~/ 3600;
    final m = (widget.currentSeconds % 3600) ~/ 60;
    final s = widget.currentSeconds % 60;
    _hController = FixedExtentScrollController(initialItem: h);
    _mController = FixedExtentScrollController(initialItem: m);
    _sController = FixedExtentScrollController(initialItem: s);
  }

  @override
  void didUpdateWidget(_TimerSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentSeconds != oldWidget.currentSeconds) {
      final h = widget.currentSeconds ~/ 3600;
      final m = (widget.currentSeconds % 3600) ~/ 60;
      final s = widget.currentSeconds % 60;
      _syncSelection(h, m, s);
    }
  }

  void _syncSelection(int h, int m, int s) {
    if (_hController.hasClients && _hController.selectedItem != h) {
      _hController.jumpToItem(h);
    }
    if (_mController.hasClients && _mController.selectedItem != m) {
      _mController.jumpToItem(m);
    }
    if (_sController.hasClients && _sController.selectedItem != s) {
      _sController.jumpToItem(s);
    }
  }

  @override
  void dispose() {
    _hController.dispose();
    _mController.dispose();
    _sController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final h = _hController.selectedItem;
    final m = _mController.selectedItem;
    final s = _sController.selectedItem;
    final total = h * 3600 + m * 60 + s;
    if (total != widget.currentSeconds) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(total);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      decoration: BoxDecoration(
        color: grit.surface,
        border: Border.all(color: grit.border, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection highlight band
          Positioned(
            top: 56,
            left: 0,
            right: 0,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: grit.accent.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          // The wheels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWheel(grit, _hController, 24, 'H'),
              _buildSeparator(grit.muted),
              _buildWheel(grit, _mController, 60, 'M'),
              _buildSeparator(grit.muted),
              _buildWheel(grit, _sController, 60, 'S'),
            ],
          ),
          // Gradient fades
          IgnorePointer(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [grit.surface, grit.surface.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 44),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [grit.surface, grit.surface.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel(GritThemeData grit, FixedExtentScrollController controller,
      int count, String unit) {
    return SizedBox(
      width: 60,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 44,
        diameterRatio: 1.4,
        perspective: 0.005,
        useMagnifier: true,
        magnification: 1.1,
        overAndUnderCenterOpacity: 0.25,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (_) => _onChanged(),
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (context, index) {
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    index.toString().padLeft(2, '0'),
                    style: GritTextStyles.mono(22,
                      weight: FontWeight.w900,
                      color: grit.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit.toLowerCase(),
                    style: GritTextStyles.labelMicro().copyWith(
                      color: grit.muted,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSeparator(Color mutedColor) {
    return Text(':', style: GritTextStyles.mono(18, color: mutedColor));
  }
}

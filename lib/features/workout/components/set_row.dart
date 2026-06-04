import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/workout_utils.dart';
import '../../../data/models/set_entry.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/workout_focus_registry.dart';

class DurationInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final regExp = RegExp(r'^[0-9:]*$');
    if (!regExp.hasMatch(text)) {
      return oldValue;
    }

    if (newValue.text.length == 2 && oldValue.text.length == 1) {
      final formatted = '${newValue.text}:';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    return newValue;
  }
}

class SetRow extends ConsumerStatefulWidget {
  final int exerciseIndex;
  final int sessionExerciseId;
  final int setIndex;
  final bool isLb;
  final bool showBottomBorder;

  const SetRow({
    super.key,
    required this.exerciseIndex,
    required this.sessionExerciseId,
    required this.setIndex,
    required this.isLb,
    this.showBottomBorder = true,
  });

  @override
  ConsumerState<SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<SetRow> {
  late TextEditingController _weightCtrl, _repsCtrl, _durationCtrl;
  late FocusNode _weightFocus, _repsFocus, _durationFocus;
  late WorkoutFocusRegistry _registry;

  String _formatDuration(int? totalSeconds) {
    if (totalSeconds == null || totalSeconds <= 0) return '';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  int? _parseDuration(String input) {
    final clean = input.trim();
    if (clean.isEmpty) return null;
    final parts = clean.split(':');
    if (parts.length == 1) {
      final secs = int.tryParse(clean);
      return secs;
    } else if (parts.length == 2) {
      final mins = int.tryParse(parts[0]) ?? 0;
      final secs = int.tryParse(parts[1]) ?? 0;
      return mins * 60 + secs;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    _weightFocus = FocusNode();
    _repsFocus = FocusNode();
    _durationFocus = FocusNode();

    _weightFocus.addListener(_onFocusChange);
    _repsFocus.addListener(_onFocusChange);
    _durationFocus.addListener(_onFocusChange);

    _registry = ref.read(workoutFocusRegistryProvider);
    _registry.register(widget.sessionExerciseId, widget.setIndex, 'weight', _weightFocus);
    _registry.register(widget.sessionExerciseId, widget.setIndex, 'reps', _repsFocus);
    _registry.register(widget.sessionExerciseId, widget.setIndex, 'duration', _durationFocus);

    final setEntry = ref
        .read(activeWorkoutProvider)
        .sets[widget.sessionExerciseId]![widget.setIndex];
    final weight = widget.isLb
        ? WorkoutUtils.kgToLb(setEntry.weightKg)
        : setEntry.weightKg;

    _weightCtrl = TextEditingController(
        text: weight == 0 && !setEntry.isCompleted && setEntry.weightKg == 0
            ? ''
            : WorkoutUtils.formatDecimal(weight));
    _repsCtrl = TextEditingController(
        text: setEntry.reps == null ? '' : setEntry.reps.toString());
    _durationCtrl = TextEditingController(
        text: setEntry.durationSeconds == null || setEntry.durationSeconds == 0
            ? ''
            : _formatDuration(setEntry.durationSeconds));
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(SetRow old) {
    super.didUpdateWidget(old);
    if (old.sessionExerciseId != widget.sessionExerciseId ||
        old.setIndex != widget.setIndex) {
      _registry.unregister(old.sessionExerciseId, old.setIndex, 'weight');
      _registry.unregister(old.sessionExerciseId, old.setIndex, 'reps');
      _registry.unregister(old.sessionExerciseId, old.setIndex, 'duration');

      _registry.register(widget.sessionExerciseId, widget.setIndex, 'weight', _weightFocus);
      _registry.register(widget.sessionExerciseId, widget.setIndex, 'reps', _repsFocus);
      _registry.register(widget.sessionExerciseId, widget.setIndex, 'duration', _durationFocus);
    }
  }

  @override
  void dispose() {
    _registry.unregister(widget.sessionExerciseId, widget.setIndex, 'weight');
    _registry.unregister(widget.sessionExerciseId, widget.setIndex, 'reps');
    _registry.unregister(widget.sessionExerciseId, widget.setIndex, 'duration');

    _weightFocus.removeListener(_onFocusChange);
    _repsFocus.removeListener(_onFocusChange);
    _durationFocus.removeListener(_onFocusChange);

    _weightFocus.dispose();
    _repsFocus.dispose();
    _durationFocus.dispose();

    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _showWarningSnackbar(BuildContext context, String msg, GritThemeData grit) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: grit.surface,
            border: Border.all(color: grit.accent, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
                  color: grit.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(msg,
                    style: GritTextStyles.mono(12,
                        weight: FontWeight.w800,
                        color: grit.textPrimary,
                        letterSpacing: 1.0)),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // GRANULAR WATCH: Only rebuild this row if its specific set changes
    final s = ref.watch(activeWorkoutProvider.select(
        (state) => state.sets[widget.sessionExerciseId]![widget.setIndex]));

    // Sync controllers if not focused and data changed externally
    if (!_weightFocus.hasFocus) {
      final weight = widget.isLb ? WorkoutUtils.kgToLb(s.weightKg) : s.weightKg;
      final formatted = weight == 0 && !s.isCompleted
          ? ''
          : WorkoutUtils.formatDecimal(weight);
      if (_weightCtrl.text != formatted) {
        _weightCtrl.text = formatted;
      }
    }

    if (!_repsFocus.hasFocus) {
      final repsFormatted = s.reps == null ? '' : s.reps.toString();
      if (_repsCtrl.text != repsFormatted) {
        _repsCtrl.text = repsFormatted;
      }
    }

    if (!_durationFocus.hasFocus) {
      final formatted = s.durationSeconds == null || s.durationSeconds == 0
          ? ''
          : _formatDuration(s.durationSeconds);
      if (_durationCtrl.text != formatted) {
        _durationCtrl.text = formatted;
      }
    }

    final grit = Theme.of(context).grit;
    final rowBg = s.isCompleted
        ? grit.accent.withValues(alpha: 0.12)
        : Colors.transparent;
    final isPreview = ref.watch(activeWorkoutProvider.select((state) => state.isPreview));

    final activeState = ref.watch(activeWorkoutProvider);
    final se = activeState.exercises[widget.exerciseIndex];
    final ex = activeState.exerciseDetails[se.exerciseId];
    final isCardioOrTimed = ex?.type == 'cardio' || ex?.type == 'timed';

    final isLocked = activeState.lockedExerciseIds.contains(widget.sessionExerciseId);

    final prevSets = activeState.previousSets[se.exerciseId] ?? [];
    final prevSet = (widget.setIndex < prevSets.length) ? prevSets[widget.setIndex] : null;

    return Dismissible(
      key: Key('set_row_${widget.sessionExerciseId}_${s.id ?? widget.setIndex}'),
      direction: (isPreview || isLocked) ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        color: grit.accent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(PhosphorIcons.trash(PhosphorIconsStyle.bold), color: Colors.white, size: 20),
      ),
      confirmDismiss: (direction) async {
        await GritHaptics.mediumImpact();
        if (!context.mounted) return false;
        final confirmDelete = await showDialog<bool>(
          context: context,
          builder: (dCtx) => AlertDialog(
            title: Text('DELETE SET?', style: GritTextStyles.metric(22, color: grit.textPrimary, weight: FontWeight.w900)),
            content: Text(
                'REALLY DELETE SET ${widget.setIndex + 1}?',
                style: GritTextStyles.label(15, weight: FontWeight.w600, color: grit.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dCtx, false),
                  child: Text('CANCEL',
                      style: GritTextStyles.metric(16, weight: FontWeight.w900, color: grit.textPrimary))),
              TextButton(
                  onPressed: () => Navigator.pop(dCtx, true),
                  child: Text('DELETE',
                      style: GritTextStyles.metric(16, weight: FontWeight.w900, color: grit.accent))),
            ],
          ),
        );
        return confirmDelete == true;
      },
      onDismissed: (direction) async {
        await ref
            .read(activeWorkoutProvider.notifier)
            .deleteSet(widget.exerciseIndex, widget.setIndex);
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: rowBg,
          border: s.isCompleted
              ? Border.all(color: grit.accent, width: 1)
              : (widget.showBottomBorder
                  ? Border(
                      bottom:
                          BorderSide(color: grit.border, width: 1))
                  : null),
        ),
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    if (isLocked) return;
                    if (!isPreview) {
                      await GritHaptics.mediumImpact();
                      if (!context.mounted) return;
                      _showSetTypeSelector(context, ref, s);
                    }
                  },
                  onLongPress: () async {
                    if (isLocked) return;
                    if (!isPreview) {
                      await GritHaptics.mediumImpact();
                      if (!context.mounted) return;
                      _showSetTypeSelector(context, ref, s);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 32,
                    child: Center(
                      child: _buildSetIndicator(s),
                    ),
                  ),
                ),
                if (isCardioOrTimed) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 152,
                    child: _buildInput(
                      controller: _durationCtrl,
                      focusNode: _durationFocus,
                      keyboard: TextInputType.text,
                      inputFormatters: [DurationInputFormatter()],
                      hintText: prevSet != null && prevSet.durationSeconds != null && prevSet.durationSeconds! > 0
                          ? _formatDuration(prevSet.durationSeconds)
                          : '00:00',
                      textInputAction: TextInputAction.next,
                      readOnly: isLocked,
                      onEditingComplete: () {
                        final setsList = ref.read(activeWorkoutProvider).sets[widget.sessionExerciseId] ?? [];
                        if (widget.setIndex + 1 < setsList.length) {
                          _registry.focus(widget.sessionExerciseId, widget.setIndex + 1, 'duration');
                        } else {
                          _durationFocus.unfocus();
                        }
                      },
                      onChanged: (v) {
                        final secs = _parseDuration(v) ?? 0;
                        ref.read(activeWorkoutProvider.notifier).updateSet(s.copyWith(durationSeconds: secs));
                      },
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: _buildInput(
                      controller: _weightCtrl,
                      focusNode: _weightFocus,
                      keyboard:
                          const TextInputType.numberWithOptions(decimal: true),
                      hintText: prevSet != null
                          ? WorkoutUtils.formatDecimal(widget.isLb ? WorkoutUtils.kgToLb(prevSet.weightKg) : prevSet.weightKg)
                          : '0',
                      textInputAction: TextInputAction.next,
                      readOnly: isLocked,
                      onEditingComplete: () {
                        _registry.focus(widget.sessionExerciseId, widget.setIndex, 'reps');
                      },
                      onChanged: (v) => ref
                          .read(activeWorkoutProvider.notifier)
                          .updateSetField(widget.exerciseIndex, widget.setIndex,
                              weight: double.tryParse(v) ?? 0,
                              isLb: widget.isLb),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: _buildInput(
                      controller: _repsCtrl,
                      focusNode: _repsFocus,
                      keyboard: TextInputType.number,
                      hintText: prevSet != null && prevSet.reps != null
                          ? prevSet.reps.toString()
                          : '0',
                      textInputAction: TextInputAction.next,
                      readOnly: isLocked,
                      onEditingComplete: () {
                        final setsList = ref.read(activeWorkoutProvider).sets[widget.sessionExerciseId] ?? [];
                        if (widget.setIndex + 1 < setsList.length) {
                          _registry.focus(widget.sessionExerciseId, widget.setIndex + 1, 'weight');
                        } else {
                          _repsFocus.unfocus();
                        }
                      },
                      onChanged: (v) => ref
                          .read(activeWorkoutProvider.notifier)
                          .updateSetField(
                              widget.exerciseIndex, widget.setIndex,
                              reps: int.tryParse(v) ?? 0),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                SizedBox(
                  width: 32,
                  child: (s.isPr && s.isCompleted)
                      ? _buildPrBadge()
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: _buildCheckmark(s, isCardioOrTimed, prevSet, isLocked)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrBadge() {
    final grit = Theme.of(context).grit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: grit.surface2,
        border: Border.all(color: grit.accent, width: 1.5),
      ),
      child: Text(
        'PR',
        textAlign: TextAlign.center,
        style: GritTextStyles.labelMicro().copyWith(
          color: grit.accent,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required TextInputType keyboard,
    required ValueChanged<String> onChanged,
    List<TextInputFormatter>? inputFormatters,
    String? hintText,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
    bool readOnly = false,
  }) {
    final grit = Theme.of(context).grit;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      cursorColor: grit.accent,
      readOnly: readOnly,
      style: GritTextStyles.mono(15,
          weight: FontWeight.w700,
          color: focusNode.hasFocus
              ? grit.accent
              : (readOnly ? grit.muted : grit.textPrimary)),
      decoration: InputDecoration(
        isDense: true,
        filled: focusNode.hasFocus,
        fillColor:
            focusNode.hasFocus ? grit.surface2 : Colors.transparent,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8.5), // Precision centering
        hintText: hintText,
        hintStyle: GritTextStyles.mono(15,
            weight: FontWeight.w700,
            color: grit.textSecondary.withValues(alpha: 0.4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: focusNode.hasFocus
                ? grit.accent
                : grit.border,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
              color: readOnly
                  ? grit.border.withValues(alpha: 0.5)
                  : grit.border,
              width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: grit.accent, width: 1),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildCheckmark(SetEntry s, bool isCardioOrTimed, SetEntry? prevSet, bool isLocked) {
    final grit = Theme.of(context).grit;
    return GestureDetector(
      onTap: () {
        if (isLocked) return;
        FocusScope.of(context).unfocus();
        if (!s.isCompleted) {
          if (isCardioOrTimed) {
            final durationStr = _durationCtrl.text.trim();
            if (durationStr.isEmpty) {
              if (prevSet != null && prevSet.durationSeconds != null && prevSet.durationSeconds! > 0) {
                final secs = prevSet.durationSeconds!;
                _durationCtrl.text = _formatDuration(secs);
                ref.read(activeWorkoutProvider.notifier).updateSet(s.copyWith(durationSeconds: secs));
              } else {
                GritHaptics.error();
                _showWarningSnackbar(context, 'ENTER DURATION', grit);
                return;
              }
            }
          } else {
            final weightStr = _weightCtrl.text.trim();
            final repsStr = _repsCtrl.text.trim();

            double? targetWeightKg;
            int? targetReps;

            if (weightStr.isEmpty) {
              if (prevSet != null) {
                targetWeightKg = prevSet.weightKg;
                final weightLb = WorkoutUtils.kgToLb(targetWeightKg);
                _weightCtrl.text = WorkoutUtils.formatDecimal(widget.isLb ? weightLb : targetWeightKg);
              }
            } else {
              final parsed = double.tryParse(weightStr) ?? 0;
              targetWeightKg = widget.isLb ? parsed * 0.45359237 : parsed;
              targetWeightKg = double.parse(targetWeightKg.toStringAsFixed(2));
              targetWeightKg = targetWeightKg.clamp(0, 999.5);
            }

            if (repsStr.isEmpty) {
              if (prevSet != null && prevSet.reps != null) {
                targetReps = prevSet.reps;
                _repsCtrl.text = targetReps.toString();
              }
            } else {
              targetReps = int.tryParse(repsStr)?.clamp(0, 100);
            }

            if (targetWeightKg == null || targetReps == null) {
              GritHaptics.error();
              String msg = '';
              if (targetWeightKg == null && targetReps == null) {
                msg = 'ENTER WEIGHT & REPS';
              } else if (targetWeightKg == null) {
                msg = 'ENTER WEIGHT';
              } else {
                msg = 'ENTER REPS';
              }
              _showWarningSnackbar(context, msg, grit);
              return;
            }

            ref.read(activeWorkoutProvider.notifier).updateSet(s.copyWith(
              weightKg: targetWeightKg,
              reps: targetReps,
            ));
          }
        }
        ref
            .read(activeWorkoutProvider.notifier)
            .completeSet(widget.exerciseIndex, widget.setIndex);
      },
      child: Container(
        width: 44,
        height: 44,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: s.isCompleted
                ? (isLocked ? grit.accent.withValues(alpha: 0.5) : grit.accent)
                : Colors.transparent,
            border: Border.all(
              color: s.isCompleted
                  ? (isLocked ? grit.accent.withValues(alpha: 0.5) : grit.accent)
                  : (isLocked ? grit.border.withValues(alpha: 0.5) : grit.border),
              width: 2,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: s.isCompleted
                ? Icon(PhosphorIcons.check(PhosphorIconsStyle.bold),
                    color: isLocked ? Colors.white.withValues(alpha: 0.6) : Colors.white, size: 16)
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildSetIndicator(SetEntry s) {
    final grit = Theme.of(context).grit;
    String label = '${widget.setIndex + 1}';
    Color color = grit.muted;

    switch (s.setType) {
      case SetEntryType.warmup:
        label = 'W';
        color = grit.warmupSet;
        break;
      case SetEntryType.dropSet:
        label = 'D';
        color = grit.dropSet;
        break;
      case SetEntryType.failure:
        label = 'F';
        color = grit.failureSet;
        break;
      case SetEntryType.normal:
        break;
    }

    return Text(label,
        style: GritTextStyles.mono(13, weight: FontWeight.w700, color: color));
  }

  void _showSetTypeSelector(BuildContext context, WidgetRef ref, SetEntry s) async {
    final grit = Theme.of(context).grit;
    final result = await showDialog<SetEntryType>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('SELECT SET TYPE', style: GritTextStyles.metric(22, color: grit.textPrimary, weight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeOption(ctx, 'NORMAL SET', SetEntryType.normal, s.setType == SetEntryType.normal),
            _buildTypeOption(ctx, 'WARMUP SET', SetEntryType.warmup, s.setType == SetEntryType.warmup, color: grit.warmupSet),
            _buildTypeOption(ctx, 'DROP SET', SetEntryType.dropSet, s.setType == SetEntryType.dropSet, color: grit.dropSet),
            _buildTypeOption(ctx, 'FAILURE SET', SetEntryType.failure, s.setType == SetEntryType.failure, color: grit.failureSet),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      await ref
          .read(activeWorkoutProvider.notifier)
          .changeSetType(widget.exerciseIndex, widget.setIndex, result);
    }
  }

  Widget _buildTypeOption(BuildContext context, String title, SetEntryType type, bool isSelected, {Color? color}) {
    final grit = Theme.of(context).grit;
    String shortcut = '';
    switch (type) {
      case SetEntryType.normal: shortcut = '${widget.setIndex + 1}'; break;
      case SetEntryType.warmup: shortcut = 'W'; break;
      case SetEntryType.dropSet: shortcut = 'D'; break;
      case SetEntryType.failure: shortcut = 'F'; break;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: SizedBox(
        width: 32,
        child: Center(
          child: Text(shortcut, style: GritTextStyles.mono(16, weight: FontWeight.w700, color: color ?? grit.muted)),
        ),
      ),
      title: Text(title, style: GritTextStyles.metric(16, weight: FontWeight.w900, color: isSelected ? (color ?? grit.accent) : grit.textPrimary, letterSpacing: 0.5)),
      trailing: isSelected ? Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), color: color ?? grit.accent, size: 18) : const SizedBox(width: 18),
      onTap: () => Navigator.pop(context, type),
    );
  }
}

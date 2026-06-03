import 'package:flutter/material.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';

class GritRestTimerPicker extends StatefulWidget {
  final int initialSeconds;
  final ValueChanged<int> onTimerChanged;

  const GritRestTimerPicker({
    super.key,
    required this.initialSeconds,
    required this.onTimerChanged,
  });

  @override
  State<GritRestTimerPicker> createState() => _GritRestTimerPickerState();
}

class _GritRestTimerPickerState extends State<GritRestTimerPicker> {
  late int _selectedMinutes;
  late int _selectedSeconds;

  late FixedExtentScrollController _minController;
  late FixedExtentScrollController _secController;

  // Use a large multiplier for infinite looping effect
  static const int _secLoopFactor = 1000;
  static const int _secCount = 60;

  @override
  void initState() {
    super.initState();
    _selectedMinutes = (widget.initialSeconds ~/ 60).clamp(0, 30);
    _selectedSeconds = (widget.initialSeconds % 60).clamp(0, 59);

    _minController = FixedExtentScrollController(initialItem: _selectedMinutes);
    // Position the controller in the middle of the loop range for seamless scrolling
    _secController = FixedExtentScrollController(
      initialItem: (_secCount * (_secLoopFactor ~/ 2)) + _selectedSeconds,
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _secController.dispose();
    super.dispose();
  }

  void _updateTimer() {
    widget.onTimerChanged((_selectedMinutes * 60) + _selectedSeconds);
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: grit.surface,
        border: Border(top: BorderSide(color: grit.border, width: 1)),
      ),
      child: Stack(
        children: [
          // Selection Highlight (Machined Slot)
          Center(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: grit.accent.withValues(alpha: 0.05),
                border: Border.symmetric(
                  horizontal: BorderSide(color: grit.accent, width: 1),
                ),
              ),
            ),
          ),
          Row(
            children: [
              // Minutes (0-30)
              Expanded(
                child: _buildPicker(
                  controller: _minController,
                  itemCount: 31,
                  onSelectedItemChanged: (index) {
                    GritHaptics.selectionTick();
                    setState(() {
                      _selectedMinutes = index;
                      _updateTimer();
                    });
                  },
                  itemBuilder: (context, index) => _buildItem(context, '$index', 'MIN'),
                ),
              ),
              // Seconds (0-59, Looping)
              Expanded(
                child: _buildPicker(
                  controller: _secController,
                  itemCount: _secCount * _secLoopFactor,
                  onSelectedItemChanged: (index) {
                    GritHaptics.selectionTick();
                    setState(() {
                      _selectedSeconds = index % _secCount;
                      _updateTimer();
                    });
                  },
                  itemBuilder: (context, index) {
                    final displayValue = index % _secCount;
                    return _buildItem(context, displayValue.toString().padLeft(2, '0'), 'SEC');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPicker({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onSelectedItemChanged,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 48,
      perspective: 0.004, // Slightly flatter for better readability with more items
      diameterRatio: 1.4,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: itemBuilder,
      ),
    );
  }

  Widget _buildItem(BuildContext context, String value, String label) {
    final grit = Theme.of(context).grit;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: GritTextStyles.mono(28, weight: FontWeight.w900),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GritTextStyles.metric(10, color: grit.textSecondary, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

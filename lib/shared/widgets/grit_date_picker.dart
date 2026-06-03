import 'package:flutter/material.dart';
import '../../core/theme/grit_theme.dart';

class GritDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;

  const GritDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
  });

  @override
  State<GritDatePicker> createState() => _GritDatePickerState();
}

class _GritDatePickerState extends State<GritDatePicker> {
  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDate.day;
    _selectedMonth = widget.initialDate.month;
    _selectedYear = widget.initialDate.year;

    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
    _monthController = FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _yearController = FixedExtentScrollController(initialItem: _selectedYear - widget.firstDate.year);
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _updateDate() {
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay > daysInMonth) {
      _selectedDay = daysInMonth;
      _dayController.jumpToItem(_selectedDay - 1);
    }
    widget.onDateChanged(DateTime(_selectedYear, _selectedMonth, _selectedDay));
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: grit.surface,
        border: Border.all(color: grit.border, width: 1),
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
              // Day
              Expanded(
                child: _buildPicker(
                  controller: _dayController,
                  itemCount: DateUtils.getDaysInMonth(_selectedYear, _selectedMonth),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedDay = index + 1;
                      _updateDate();
                    });
                  },
                  itemBuilder: (context, index) => _buildItem((index + 1).toString().padLeft(2, '0')),
                ),
              ),
              _buildDivider(context),
              // Month
              Expanded(
                child: _buildPicker(
                  controller: _monthController,
                  itemCount: 12,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedMonth = index + 1;
                      _updateDate();
                    });
                  },
                  itemBuilder: (context, index) => _buildItem(
                    ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][index],
                  ),
                ),
              ),
              _buildDivider(context),
              // Year
              Expanded(
                child: _buildPicker(
                  controller: _yearController,
                  itemCount: widget.lastDate.year - widget.firstDate.year + 1,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedYear = widget.firstDate.year + index;
                      _updateDate();
                    });
                  },
                  itemBuilder: (context, index) => _buildItem((widget.firstDate.year + index).toString()),
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
      perspective: 0.005,
      diameterRatio: 1.5,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: itemBuilder,
      ),
    );
  }

  Widget _buildItem(String label) {
    return Center(
      child: Text(
        label,
        style: GritTextStyles.metric(24, weight: FontWeight.w900),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).grit.border,
    );
  }
}

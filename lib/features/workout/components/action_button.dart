import 'package:flutter/material.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../core/utils/haptics.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const ActionButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return GestureDetector(
      onTap: () async {
        await GritHaptics.selectionTick();
        onTap();
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: grit.borderHighlight,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: GritTextStyles.labelMicro().copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: grit.textSecondary,
                letterSpacing: 2)),
      ),
    );
  }
}

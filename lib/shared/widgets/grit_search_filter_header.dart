import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';

class GritSearchFilterHeader extends StatelessWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String? selectedMuscle;
  final ValueChanged<String> onMuscleSelected;
  final String? selectedEquipment;
  final ValueChanged<String> onEquipmentSelected;

  static const List<String> muscles = [
    'ALL', 'CHEST', 'BACK', 'SHOULDERS', 'BICEPS', 'TRICEPS', 'FOREARMS', 'LEGS', 'CORE', 'CUSTOM'
  ];

  static const List<String> equipmentList = [
    'ALL', 'BARBELL', 'DUMBBELL', 'SMITH MACHINE', 'CABLE', 'MACHINE', 'KETTLEBELL', 'BODY WEIGHT', 'BAND', 'MEDICINE BALL', 'STABILITY BALL', 'EZ BARBELL'
  ];

  const GritSearchFilterHeader({
    super.key,
    this.searchController,
    this.onSearchChanged,
    required this.selectedMuscle,
    required this.onMuscleSelected,
    required this.selectedEquipment,
    required this.onEquipmentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      decoration: BoxDecoration(
        color: grit.background,
        border: Border(bottom: BorderSide(color: grit.border, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(GritSpacing.horizontalMargin, 8, GritSpacing.horizontalMargin, 12),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: GritTextStyles.titleSmall(),
              decoration: InputDecoration(
                hintText: 'SEARCH EXERCISES...',
                hintStyle: GritTextStyles.titleSmall().copyWith(color: grit.muted),
                prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), color: grit.textSecondary, size: 20),
                filled: true,
                fillColor: grit.surface2,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.zero),
              ),
            ),
          ),
          // Equipment Filter
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin - 4),
              itemCount: equipmentList.length,
              itemBuilder: (context, index) {
                final equip = equipmentList[index];
                final isSelected = selectedEquipment == equip || (selectedEquipment == null && equip == 'ALL');
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () async {
                      await GritHaptics.selectionTick();
                      onEquipmentSelected(equip);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? grit.accent : Colors.transparent,
                        border: Border.all(color: isSelected ? grit.accent : grit.border, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(equip,
                          style: GritTextStyles.labelMicro().copyWith(
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : grit.textSecondary)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Muscle Group Filter
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin - 4),
              itemCount: muscles.length,
              itemBuilder: (context, index) {
                final muscle = muscles[index];
                final isSelected = selectedMuscle == muscle || (selectedMuscle == null && muscle == 'ALL');
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () async {
                      await GritHaptics.selectionTick();
                      onMuscleSelected(muscle);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? grit.accent : Colors.transparent,
                        border: Border.all(color: isSelected ? grit.accent : grit.border, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(muscle,
                          style: GritTextStyles.labelMicro().copyWith(
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : grit.textSecondary)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

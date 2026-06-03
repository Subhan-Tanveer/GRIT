import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/grit_theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/models/exercise.dart';
import '../../providers/dao_providers.dart';
import '../../providers/routine_provider.dart';

class ExerciseCreateSheet extends ConsumerStatefulWidget {
  const ExerciseCreateSheet({super.key});

  @override
  ConsumerState<ExerciseCreateSheet> createState() =>
      _ExerciseCreateSheetState();
}

class _ExerciseCreateSheetState extends ConsumerState<ExerciseCreateSheet> {
  final _nameController = TextEditingController();
  final _customMuscleController = TextEditingController();
  String _selectedMuscle = 'CHEST';
  bool _hasError = false;

  final List<String> _muscleGroups = [
    'CHEST',
    'BACK',
    'BICEPS',
    'SHOULDER',
    'TRICEPS',
    'LEGS',
    'CORE',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _customMuscleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _hasError = true);
      return;
    }
    setState(() => _hasError = false);

    String finalMuscle = _selectedMuscle.toLowerCase();
    // Map category labels to a canonical SVG group ID
    switch (_selectedMuscle.toUpperCase()) {
      case 'CHEST': finalMuscle = 'chest'; break;
      case 'BACK': finalMuscle = 'lats'; break;
      case 'BICEPS': finalMuscle = 'biceps'; break;
      case 'SHOULDER': finalMuscle = 'front-shoulders'; break;
      case 'TRICEPS': finalMuscle = 'triceps'; break;
      case 'LEGS': finalMuscle = 'quads'; break;
      case 'CORE': finalMuscle = 'abdominals'; break;
      default: finalMuscle = _selectedMuscle.toLowerCase();
    }

    final exercise = Exercise(
      name: name,
      muscleGroup: finalMuscle,
      equipment: 'none',
      type: 'weighted',
      isCustom: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    final dao = ref.read(exercisesDaoProvider);
    final id = await dao.insert(exercise);

    // Invalidate exercises list to reflect new entry
    ref.invalidate(exercisesProvider);

    if (mounted) {
      Navigator.pop(context, exercise.copyWith(id: id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      color: grit.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Divider(color: grit.border, height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EXERCISE NAME',
                    style: GritTextStyles.label(10,
                        color: grit.textSecondary,
                        weight: FontWeight.w800,
                        letterSpacing: 2)),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  onChanged: (v) {
                    if (_hasError && v.trim().isNotEmpty) {
                      setState(() => _hasError = false);
                    }
                  },
                  style: GritTextStyles.metric(32,
                      color: grit.textPrimary,
                      weight: FontWeight.w900, height: 1),
                  decoration: InputDecoration(
                    hintText: 'ENTER NAME...',
                    hintStyle: GritTextStyles.metric(32,
                        color: grit.muted,
                        weight: FontWeight.w900, height: 1),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                if (_hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('EXERCISE NAME CANNOT BE EMPTY',
                        style: GritTextStyles.label(12,
                            color: Colors.red, weight: FontWeight.w700)),
                  ),
                const SizedBox(height: 32),
                Text('MUSCLE GROUP',
                    style: GritTextStyles.label(10,
                        color: grit.textSecondary,
                        weight: FontWeight.w800,
                        letterSpacing: 2)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _muscleGroups.map((m) => _buildChip(m)).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final grit = Theme.of(context).grit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('ADD NEW EXERCISE',
              style: GritTextStyles.metric(18,
                  color: grit.textPrimary,
                  weight: FontWeight.w900, letterSpacing: 1)),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(PhosphorIcons.x(),
                color: grit.textSecondary, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    final grit = Theme.of(context).grit;
    final isSelected = _selectedMuscle == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedMuscle = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? grit.accent : Colors.transparent,
          border: Border.all(
            color: isSelected ? grit.accent : grit.border,
            width: 2,
          ),
        ),
        child: Text(label,
            style: GritTextStyles.label(10,
                color: isSelected ? Colors.white : grit.textSecondary,
                weight: FontWeight.w900,
                letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildSaveButton() {
    final grit = Theme.of(context).grit;
    return GestureDetector(
      onTap: _save,
      child: Container(
        height: 72,
        color: grit.accent,
        alignment: Alignment.center,
        child: Text('CREATE EXERCISE',
            style: GritTextStyles.metric(20,
                color: Colors.white,
                weight: FontWeight.w900,
                letterSpacing: 2)),
      ),
    );
  }
}

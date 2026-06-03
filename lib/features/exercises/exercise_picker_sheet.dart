import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/grit_theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/models/exercise.dart';
import '../../providers/routine_provider.dart';
import '../../providers/dao_providers.dart';
import '../../shared/widgets/grit_error_state.dart';

class ExercisePickerSheet extends ConsumerStatefulWidget {
  const ExercisePickerSheet({super.key});

  @override
  ConsumerState<ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final exercisesAsync = ref.watch(exercisesProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: grit.background,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBox(),
          Divider(color: grit.border, height: 1, thickness: 1),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                final filtered = exercises
                    .where((e) => e.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                      color: grit.border, height: 1, thickness: 1),
                  itemBuilder: (context, index) {
                    final ex = filtered[index];
                    return ListTile(
                      title: Text(ex.name.toUpperCase(),
                          style: GritTextStyles.metric(16,
                              weight: FontWeight.w700, color: grit.textPrimary)),
                      subtitle: Text(
                          '${ex.muscleGroup.toUpperCase()} · ${ex.equipment.toUpperCase()}',
                          style: GritTextStyles.label(10,
                              color: grit.textSecondary,
                              letterSpacing: 1)),
                      onTap: () => Navigator.pop(context, ex),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => GritErrorState(error: e),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final grit = Theme.of(context).grit;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('SELECT EXERCISE',
              style: GritTextStyles.metric(18, weight: FontWeight.w800, color: grit.textPrimary)),
          IconButton(
            icon: Icon(PhosphorIcons.x(), color: grit.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    final grit = Theme.of(context).grit;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: TextField(
        controller: _searchController,
        style: GritTextStyles.label(14, color: grit.textPrimary),
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'SEARCH EXERCISES...',
          hintStyle: GritTextStyles.label(14, color: grit.muted),
          fillColor: grit.surface2,
          filled: true,
          prefixIcon: Icon(PhosphorIcons.magnifyingGlass(),
              color: grit.textSecondary),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero, borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final grit = Theme.of(context).grit;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('EXERCISE NOT FOUND.',
              style:
                  GritTextStyles.metric(20, color: grit.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: grit.accent,
              foregroundColor: Colors.white,
              shape:
                  const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            onPressed: _addCustomExercise,
            child: Text('CREATE "${_searchQuery.toUpperCase()}"',
                style: GritTextStyles.metric(14, weight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _addCustomExercise() async {
    final name = _searchQuery.trim();
    if (name.isNotEmpty) {
      final customEx = Exercise(
        name: name,
        muscleGroup: 'Custom',
        equipment: 'Custom',
        type: 'weighted',
        isCustom: true,
        createdAt: DateTime.now().toIso8601String(),
      );
      final dao = ref.read(exercisesDaoProvider);
      final id = await dao.insert(customEx);
      if (mounted) {
        Navigator.pop(context, customEx.copyWith(id: id));
      }
    }
  }
}

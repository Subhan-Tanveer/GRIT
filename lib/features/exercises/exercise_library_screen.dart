import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../shared/widgets/grit_error_state.dart';
import '../../shared/widgets/grit_empty_state.dart';
import '../../shared/widgets/grit_search_filter_header.dart';
import '../../providers/routine_provider.dart';
import '../../data/models/exercise.dart';
import 'exercise_create_sheet.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/muscle_mapper.dart';
import '../../providers/dao_providers.dart';
import '../../app/routes.dart';
import '../../shared/widgets/grit_button.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  final bool selectMode;
  final bool multipleSelection;
  final bool isCreatingRoutine = false;

  const ExerciseLibraryScreen({
    super.key,
    this.selectMode = true,
    this.multipleSelection = true,
  });

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _searchQuery = '';
  String? _selectedMuscle;
  final Set<Exercise> _selectedExercises = {};
  String? _selectedEquipment;

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    final grit = Theme.of(context).grit;

    return Scaffold(
      backgroundColor: grit.background,
      appBar: AppBar(
        backgroundColor: grit.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'EXERCISE LIBRARY',
          style: GritTextStyles.metric(24,
            weight: FontWeight.w900,
            color: Theme.of(context).grit.textPrimary,
          ),
        ),
        leading: IconButton(
          key: const ValueKey('library_back_button'),
          icon: Icon(PhosphorIcons.arrowLeft()),
          onPressed: () => context.canPop() ? context.pop() : context.go(GritRoutes.workout),
        ),
        actions: [
          if (widget.selectMode && _selectedExercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    await GritHaptics.buttonTap();
                    if (context.mounted) {
                      context.pop(_selectedExercises.toList());
                    }
                  },
                  child: Text(
                    'ADD (${_selectedExercises.length})',
                    style: GritTextStyles.labelCaps().copyWith(
                        color: grit.accent),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          GritSearchFilterHeader(
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            selectedMuscle: _selectedMuscle,
            onMuscleSelected: (m) => setState(() => _selectedMuscle = m),
            selectedEquipment: _selectedEquipment,
            onEquipmentSelected: (e) => setState(() => _selectedEquipment = e),
          ),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                var filtered = exercises.where((e) {
                  final query = _searchQuery.toLowerCase();
                  final displayMuscle =
                      MuscleMapper.toDisplayLabel(e.muscleGroup).toLowerCase();

                  final matchName = e.name.toLowerCase().contains(query) ||
                      e.muscleGroup.toLowerCase().contains(query) ||
                      displayMuscle.contains(query);

                  bool matchMuscle =
                      _selectedMuscle == null || _selectedMuscle == 'ALL';

                  if (!matchMuscle) {
                    if (_selectedMuscle == 'CUSTOM') {
                      matchMuscle = e.isCustom;
                    } else {
                      // Use centralized mapping for filter categories
                      final svgIds =
                          MuscleMapper.getSvgIdsForCategory(_selectedMuscle!);
                      matchMuscle =
                          svgIds.contains(e.muscleGroup.toLowerCase());
                    }
                  }

                  bool matchEquipment =
                      _selectedEquipment == null || _selectedEquipment == 'ALL';
                  if (!matchEquipment) {
                    matchEquipment = e.equipment.toLowerCase() ==
                        _selectedEquipment!.toLowerCase();
                  }

                  return matchName && matchMuscle && matchEquipment;
                }).toList();

                if (filtered.isEmpty) {
                  return GritEmptyState(
                    icon: PhosphorIcons.magnifyingGlass(),
                    title: 'NO EXERCISES FOUND',
                    description: "CAN'T FIND WHAT YOU'RE LOOKING FOR?\nCREATE A CUSTOM ONE INSTEAD.",
                    actionLabel: 'CREATE CUSTOM',
                    onAction: () async {
                      final newEx = await showModalBottomSheet<Exercise>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const ExerciseCreateSheet(),
                      );
                      if (newEx != null && mounted) {
                        ref.invalidate(exercisesProvider);
                        if (widget.selectMode) {
                          setState(() => _selectedExercises.add(newEx));
                        }
                      }
                    },
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ex = filtered[index];
                    final isSelected =
                        _selectedExercises.any((e) => e.id == ex.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () async {
                          await GritHaptics.selectionTick();
                          if (!mounted) return;
                          if (widget.selectMode) {
                            if (widget.multipleSelection) {
                              setState(() {
                                if (isSelected) {
                                  _selectedExercises
                                      .removeWhere((e) => e.id == ex.id);
                                } else {
                                  _selectedExercises.add(ex);
                                }
                              });
                            } else {
                              // Single selection mode - pop immediately
                              if (context.mounted) {
                                context.pop([ex]);
                              }
                            }
                          } else {
                            if (context.mounted) {
                              context.push(GritRoutes.exerciseAnalysis(ex.id!));
                            }
                          }
                        },
                        onLongPress: () async {
                          if (ex.isCustom) {
                            await GritHaptics.mediumImpact();
                            if (context.mounted) {
                              _showDeleteDialog(context, ex);
                            }
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? grit.accent.withValues(alpha: 0.1)
                                : grit.surface2,
                            border: Border.all(
                                color: isSelected
                                    ? grit.accent
                                    : grit.border,
                                width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ex.name.toUpperCase(),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: GritTextStyles.titleSmall().copyWith(
                                            height: 1.15,
                                            color: isSelected
                                                ? grit.accent
                                                : grit.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text(ex.equipment.toUpperCase(),
                                        style: GritTextStyles.labelMicro()
                                            .copyWith(
                                                color: grit.textSecondary,
                                                fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              // Show icon in select mode: checkCircle if selected, plus if not selected
                              if (widget.selectMode)
                                Icon(
                                  isSelected
                                      ? PhosphorIcons.checkCircle(
                                          PhosphorIconsStyle.fill)
                                      : PhosphorIcons.plus(),
                                  color: isSelected
                                      ? grit.accent
                                      : grit.textSecondary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(
                            delay: (index.clamp(0, 15) * 15).ms,
                            duration: 400.ms)
                        .slideX(begin: 0.05, curve: Curves.easeOutBack);
                  },
                );
              },
              loading: () => ListView.builder(
                  itemCount: 6,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (c, i) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: GritSkeleton(height: 80))),
              error: (e, _) => GritErrorState(error: e),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }


  Widget _buildBottomAction() {
    final grit = Theme.of(context).grit;
    if (widget.selectMode && _selectedExercises.isNotEmpty) {
      return Container(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: grit.background,
          border: Border(top: BorderSide(color: grit.border, width: 1)),
        ),
        child: GritPrimaryButton(
          label: 'CONFIRM SELECTION (${_selectedExercises.length})',
          icon: null,
          onPressed: () {
            context.pop(_selectedExercises.toList());
          },
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: grit.background,
        border: Border(top: BorderSide(color: grit.border, width: 1)),
      ),
      child: GritSecondaryButton(
        label: 'NEW CUSTOM EXERCISE',
        icon: PhosphorIcons.plus(),
        onPressed: () async {
          final newEx = await showModalBottomSheet<Exercise>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const ExerciseCreateSheet(),
          );
          if (newEx != null && mounted) {
            ref.invalidate(exercisesProvider);
            if (widget.selectMode) {
              setState(() => _selectedExercises.add(newEx));
            }
          }
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Exercise ex) {
    final grit = Theme.of(context).grit;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('DELETE EXERCISE?', style: GritTextStyles.titleLarge()),
        content: Text(
          'ARE YOU SURE YOU WANT TO DELETE "${ex.name.toUpperCase()}"? THIS CANNOT BE UNDONE.',
          style: GritTextStyles.labelMicro()
              .copyWith(color: grit.textSecondary, letterSpacing: 1),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: GritTextStyles.labelCaps()
                    .copyWith(color: grit.textPrimary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(exercisesDaoProvider).softDelete(ex.id!);
              ref.invalidate(exercisesProvider);
              await GritHaptics.mediumImpact();
            },
            child: Text('DELETE',
                style: GritTextStyles.labelCaps()
                    .copyWith(color: grit.accent)),
          ),
        ],
      ),
    );
  }
}

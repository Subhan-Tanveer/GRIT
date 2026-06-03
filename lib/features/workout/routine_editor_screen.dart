import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../providers/routine_provider.dart';
import '../../providers/dao_providers.dart';
import '../../app/routes.dart';
import '../../data/models/routine.dart';
import '../../data/models/exercise.dart';
import '../../shared/widgets/grit_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/hero_tags.dart';
import '../../core/utils/muscle_mapper.dart';
import '../../shared/widgets/grit_search_filter_header.dart';
import '../../shared/widgets/grit_empty_state.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  final int? routineId;
  final List<Exercise>? initialExercises;

  const RoutineEditorScreen({super.key, this.routineId, this.initialExercises});

  @override
  ConsumerState<RoutineEditorScreen> createState() =>
      _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  List<RoutineExercise> _exercises = [];
  bool _initialized = false;
  String _searchQuery = '';
  String? _selectedMuscle;
  String? _selectedEquipment;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      if (widget.routineId != null) {
        _loadRoutine();
      } else if (widget.initialExercises != null) {
        _exercises = widget.initialExercises!.asMap().entries.map((e) => RoutineExercise(
          routineId: 0,
          exerciseId: e.value.id!,
          orderIndex: e.key,
          exercise: e.value,
        )).toList();
      }
      _initialized = true;
    }
  }

  Future<void> _loadRoutine() async {
    final dao = ref.read(routinesDaoProvider);
    final routine = await dao.getById(widget.routineId!);
    if (routine != null) {
      setState(() {
        _nameController.text = routine.name;
        _exercises = List.from(routine.exercises ?? []);
      });
    }
  }

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
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: grit.textPrimary, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go(GritRoutes.workout),
        ),
        title: Text(
          widget.routineId == null ? 'CREATE ROUTINE' : 'EDIT ROUTINE',
          style: GritTextStyles.titleLarge(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GritGhostButton(
              label: "SAVE",
              isAccent: true,
              onTap: _save,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Routine Name Input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Hero(
                tag: widget.routineId != null ? HeroTags.routineName(widget.routineId!) : 'new_routine_hero',
                child: Material(
                  type: MaterialType.transparency,
                  child: TextField(
                    key: const ValueKey('routine_name_field'),
                    controller: _nameController,
                    autofocus: widget.routineId == null,
                    style: GritTextStyles.headlineMedium(),
                    cursorColor: grit.accent,
                    decoration: InputDecoration(
                      hintText: 'ROUTINE NAME',
                      hintStyle: GritTextStyles.headlineMedium().copyWith(color: grit.muted),
                      filled: true,
                      fillColor: grit.surface2,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: grit.border, width: 1),
                        borderRadius: BorderRadius.zero,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: grit.border, width: 1),
                        borderRadius: BorderRadius.zero,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: grit.accent, width: 1),
                        borderRadius: BorderRadius.zero,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 16),
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Exercise Library Section
                  SliverToBoxAdapter(
                    child: GritSearchFilterHeader(
                      searchController: _searchController,
                      selectedMuscle: _selectedMuscle,
                      onMuscleSelected: (m) => setState(() => _selectedMuscle = m),
                      selectedEquipment: _selectedEquipment,
                      onEquipmentSelected: (e) => setState(() => _selectedEquipment = e),
                    ),
                  ),

                  exercisesAsync.when(
                    data: (exercises) {
                      final filtered = exercises.where((e) {
                        final query = _searchQuery.toLowerCase();
                        final displayMuscle = MuscleMapper.toDisplayLabel(e.muscleGroup).toLowerCase();
                        
                        final matchSearch = e.name.toLowerCase().contains(query) || displayMuscle.contains(query);
                        
                        bool matchMuscle = _selectedMuscle == null || _selectedMuscle == 'ALL';
                        if (!matchMuscle) {
                          if (_selectedMuscle == 'CUSTOM') {
                            matchMuscle = e.isCustom;
                          } else {
                            final svgIds = MuscleMapper.getSvgIdsForCategory(_selectedMuscle!);
                            matchMuscle = svgIds.contains(e.muscleGroup.toLowerCase());
                          }
                        }

                        bool matchEquipment = _selectedEquipment == null || _selectedEquipment == 'ALL';
                        if (!matchEquipment) {
                          matchEquipment = e.equipment.toLowerCase() == _selectedEquipment!.toLowerCase();
                        }

                        return matchSearch && matchMuscle && matchEquipment;
                      }).toList();

                      if (filtered.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: GritEmptyState(
                              icon: PhosphorIcons.magnifyingGlass(),
                              title: 'NO EXERCISES FOUND',
                              description: "CAN'T FIND WHAT YOU'RE LOOKING FOR?\nCREATE A CUSTOM EXERCISE IN THE LIBRARY.",
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          key: const ValueKey('exercise_library_list'),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final ex = filtered[index];
                              return _buildLibraryExerciseRow(ex, index);
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      );
                    },
                    loading: () => SliverToBoxAdapter(
                      child: Center(child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: grit.accent),
                      )),
                    ),
                    error: (err, _) => SliverToBoxAdapter(
                      child: Center(child: Text('ERROR LOADING EXERCISES', style: GritTextStyles.label(12, color: grit.textPrimary))),
                    ),
                  ),
                  
                  // Bottom Padding
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLibraryExerciseRow(Exercise ex, int index) {
    // Check if already in routine
    final isSelected = _exercises.any((re) => re.exerciseId == ex.id);

    final grit = Theme.of(context).grit;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? grit.accent.withValues(alpha: 0.1) 
            : grit.surface2,
        border: Border.all(
          color: isSelected ? grit.accent : grit.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await GritHaptics.selectionTick();
            setState(() {
              if (isSelected) {
                // UNTICK: Remove exercise from selection
                _exercises.removeWhere((re) => re.exerciseId == ex.id);
              } else {
                // TICK: Add exercise to selection
                _exercises.add(RoutineExercise(
                  routineId: widget.routineId ?? 0,
                  exerciseId: ex.id!,
                  orderIndex: _exercises.length,
                  exercise: ex,
                ));
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.name.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: GritTextStyles.titleSmall().copyWith(
                          height: 1.15,
                          color: isSelected ? grit.accent : grit.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ex.equipment.toUpperCase(),
                        style: GritTextStyles.labelMicro().copyWith(
                          color: grit.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                      : PhosphorIcons.plus(),
                  color: isSelected ? grit.accent : grit.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index.clamp(0, 15) * 15).ms);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final grit = Theme.of(context).grit;
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PLEASE ENTER A ROUTINE NAME',
              style: GritTextStyles.label(12,
                  color: Colors.white, weight: FontWeight.w800)),
          backgroundColor: grit.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ADD AT LEAST ONE EXERCISE',
              style: GritTextStyles.label(12,
                  color: Colors.white, weight: FontWeight.w800)),
          backgroundColor: grit.accent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    await GritHaptics.saveRoutine();

    setState(() { _isSaving = true; });

    try {
      final dao = ref.read(routinesDaoProvider);
    int routineId;

    if (widget.routineId == null) {
      routineId = await dao.insert(Routine(
        name: _nameController.text,
        createdAt: DateTime.now().toIso8601String(),
      ));
    } else {
      routineId = widget.routineId!;
      await dao.update(Routine(
        id: routineId,
        name: _nameController.text,
        createdAt: DateTime.now().toIso8601String(),
      ));
    }

    final exercisesToSave = _exercises.asMap().entries.map((e) {
      return e.value.copyWith(routineId: routineId, orderIndex: e.key);
    }).toList();

      await dao.saveExercises(routineId, exercisesToSave);
      ref.invalidate(routineListProvider);
      ref.invalidate(routineProvider(routineId));
      
      if (mounted) {
        setState(() { _isSaving = false; });
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
      rethrow;
    }
  }
}

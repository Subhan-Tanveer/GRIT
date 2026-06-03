import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../app/routes.dart';
import '../../core/utils/haptics.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/dao_providers.dart';
import '../../providers/profile_provider.dart';
import '../../data/models/body_measurement_entry.dart';
import '../../core/utils/workout_utils.dart';
import '../../core/constants/biometric_sites.dart';
import '../../core/theme/grit_theme.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../shared/widgets/grit_button.dart';
import '../../shared/widgets/grit_error_state.dart';

class MeasurementsLogScreen extends ConsumerStatefulWidget {
  const MeasurementsLogScreen({super.key});

  @override
  ConsumerState<MeasurementsLogScreen> createState() => _MeasurementsLogScreenState();
}

class _MeasurementsLogScreenState extends ConsumerState<MeasurementsLogScreen> {
  final Map<String, TextEditingController> _controllers = {};
  String _displayUnit = 'CM';
  bool _isInit = false;
  bool _isSaving = false;

  final List<BiometricSite> _sites = BiometricSites.all;

  @override
  void initState() {
    super.initState();
    for (var site in _sites) {
      _controllers[site.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _prefillData(BodyMeasurementEntry? latest) {
    if (_isInit || latest == null) return;
    final profile = ref.read(profileProvider);
    final heightUnit = profile.heightUnit;
    _displayUnit = (heightUnit == 'FT·IN' || heightUnit == 'FT-IN' || heightUnit == 'FT/IN') ? 'IN' : 'CM';

    final map = latest.toMap();
    for (var site in _sites) {
      final value = map[site.id] as double?;
      if (value != null) {
        double displayVal = value;
        if (_displayUnit == 'IN') displayVal = value / 2.54;
        _controllers[site.id]!.text = WorkoutUtils.formatDecimal(displayVal);
      }
    }
    _isInit = true;
  }

  void _convertValues(String newUnit) {
    if (_displayUnit == newUnit) return;
    
    // Calculate and update values based on CM to avoid drift
    for (var site in _sites) {
      final text = _controllers[site.id]!.text;
      if (text.isNotEmpty) {
        final valInUnits = double.tryParse(text);
        if (valInUnits != null) {
          double valInCm = _displayUnit == 'IN' ? valInUnits * 2.54 : valInUnits;
          double newVal = newUnit == 'IN' ? valInCm / 2.54 : valInCm;
          _controllers[site.id]!.text = WorkoutUtils.formatDecimal(newVal);
        }
      }
    }
    setState(() {
      _displayUnit = newUnit;
    });
  }

  Future<void> _save() async {
    final grit = Theme.of(context).grit;
    final entryMap = <String, dynamic>{
      'created_at': DateTime.now().toIso8601String(),
    };

    bool hasAny = false;
    for (var site in _sites) {
      final text = _controllers[site.id]!.text;
      if (text.isNotEmpty) {
        final parsed = double.tryParse(text);
        if (parsed != null) {
          double val = parsed;
          
          // Anti-Data-Corruption: Clamp values to reasonable biometric ranges
          val = val.clamp(0.1, 500.0);

          if (_displayUnit == 'IN') val = val * 2.54; // Store in CM
          entryMap[site.id] = val;
          hasAny = true;
        }
      }
    }

    if (!hasAny) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ENTER AT LEAST ONE MEASUREMENT TO SAVE.',
            style: GritTextStyles.metric(20,
              weight: FontWeight.w800,
              color: grit.textPrimary,
            ),
          ),
          backgroundColor: grit.surface2,
          behavior: SnackBarBehavior.floating,
          shape: Border(left: BorderSide(color: grit.accent, width: 2)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final dao = ref.read(bodyMeasurementDaoProvider);
    await dao.upsert(BodyMeasurementEntry.fromMap(entryMap));

    GritHaptics.selectionTick();
    ref.invalidate(latestMeasurementsProvider);
    ref.invalidate(measurementHistoryProvider);
    ref.invalidate(dashboardDataProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final latestAsync = ref.watch(latestMeasurementsProvider);

    return latestAsync.when(
      data: (latest) {
        _prefillData(latest);
        final isUpdate = latest != null &&
            latest.createdAt.split('T')[0] ==
                DateTime.now().toIso8601String().split('T')[0];

        return Scaffold(
          backgroundColor: grit.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: grit.border, width: 1)),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(PhosphorIcons.arrowLeft(),
                                color: grit.textPrimary, size: 28),
                            onPressed: () => context.canPop() ? context.pop() : context.go(GritRoutes.profile),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'LOG MEASUREMENTS',
                              style: GritTextStyles.metric(24,
                                  weight: FontWeight.w900, height: 1, color: grit.textPrimary),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            GritHaptics.deleteAction();
                            setState(() {
                              for (var controller in _controllers.values) {
                                controller.clear();
                              }
                            });
                          },
                          child: Text(
                            'CLEAR ALL',
                            style: GritTextStyles.labelCaps().copyWith(
                              fontSize: 12,
                              color: grit.accent,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: grit.border, width: 1)),
                ),
                child: Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()).toUpperCase(),
                  style: GritTextStyles.labelCaps().copyWith(
                    fontSize: 12,
                    color: grit.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildInputRow(context, _sites.firstWhere((s) => s.id == 'neck')),
                    _buildInputRow(context, _sites.firstWhere((s) => s.id == 'shoulders')),
                    _buildInputRow(context, _sites.firstWhere((s) => s.id == 'chest')),
                    _buildInputRow(context, _sites.firstWhere((s) => s.id == 'waist')),
                    _buildLateralRow(context, 'left_bicep', 'right_bicep'),
                    _buildLateralRow(context, 'left_forearm', 'right_forearm'),
                    _buildLateralRow(context, 'left_thigh', 'right_thigh'),
                    _buildLateralRow(context, 'left_calf', 'right_calf'),
                    _buildUnitToggle(context),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.of(context).padding.bottom + 20,
                ),
                child: _buildSaveButton(context, isUpdate),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).grit.background,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                height: 64,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Theme.of(context).grit.border, width: 1)),
                ),
                child: Row(
                  children: [
                    GritSkeleton(height: 28, width: 28),
                    const SizedBox(width: 12),
                    GritSkeleton(height: 24, width: 180),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 8,
                  itemBuilder: (context, index) => Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Theme.of(context).grit.border, width: 1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GritSkeleton(height: 14, width: 80),
                        GritSkeleton(height: 36, width: 64),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: Theme.of(context).grit.background,
        body: GritErrorState(
          error: err,
          onRetry: () => ref.invalidate(latestMeasurementsProvider),
        ),
      ),
    );
  }

  Widget _buildLateralRow(BuildContext context, String leftId, String rightId) {
    final grit = Theme.of(context).grit;
    final leftSite = _sites.firstWhere((s) => s.id == leftId);
    final rightSite = _sites.firstWhere((s) => s.id == rightId);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: grit.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildLateralInput(context, leftSite)),
          Container(width: 1, color: grit.border),
          Expanded(child: _buildLateralInput(context, rightSite)),
        ],
      ),
    );
  }

  Widget _buildLateralInput(BuildContext context, BiometricSite site) {
    final grit = Theme.of(context).grit;
    // Shorten label if needed
    final label = site.label.replaceAll('LEFT ', 'L ').replaceAll('RIGHT ', 'R ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GritTextStyles.metric(13,
              weight: FontWeight.w700,
              color: grit.textPrimary,
            ),
          ),
          Focus(
            onFocusChange: (hasFocus) {
              if (mounted) setState(() {});
            },
            child: Builder(
              builder: (context) {
                final isFocused = Focus.of(context).hasFocus;
                return Row(
                  children: [
                    Container(
                      width: 64,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: grit.surface2,
                        border: Border.all(
                          color: isFocused ? grit.accent : grit.border,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controllers[site.id],
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        textInputAction: TextInputAction.next,
                        onChanged: (v) => GritHaptics.counterClick(),
                        cursorColor: grit.accent,
                        style: GritTextStyles.mono(
                          14,
                          weight: FontWeight.w700,
                          color: grit.textPrimary,
                        ).copyWith(height: 1.0),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          isCollapsed: true,
                          filled: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _displayUnit,
                      style: GritTextStyles.mono(
                        9,
                        weight: FontWeight.w400,
                        color: grit.textSecondary,
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(BuildContext context, BiometricSite site) {
    final grit = Theme.of(context).grit;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: grit.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            site.label,
            style: GritTextStyles.metric(14,
              weight: FontWeight.w700,
              color: grit.textPrimary,
            ),
          ),
          Focus(
            onFocusChange: (hasFocus) {
              if (mounted) setState(() {});
            },
            child: Builder(
              builder: (context) {
                final isFocused = Focus.of(context).hasFocus;
                return Row(
                  children: [
                    Container(
                      width: 80,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: grit.surface2,
                        border: Border.all(
                          color: isFocused ? grit.accent : grit.border,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controllers[site.id],
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        textInputAction: TextInputAction.next,
                        onChanged: (v) => GritHaptics.counterClick(),
                        cursorColor: grit.accent,
                        style: GritTextStyles.mono(
                          15,
                          weight: FontWeight.w700,
                          color: grit.textPrimary,
                        ).copyWith(height: 1.0),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          isCollapsed: true,
                          filled: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _displayUnit,
                      style: GritTextStyles.mono(
                        11,
                        weight: FontWeight.w400,
                        color: grit.textSecondary,
                      ),
                    ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'DISPLAY UNIT',
            style: GritTextStyles.labelCaps().copyWith(
              fontSize: 10,
              color: grit.textSecondary,
            ),
          ),
          Container(
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: grit.border, width: 1),
            ),
            child: Row(
              children: [
                _buildToggleOption(context, 'CM'),
                _buildToggleOption(context, 'IN'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(BuildContext context, String unit) {
    final grit = Theme.of(context).grit;
    final isActive = _displayUnit == unit;
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          GritHaptics.selectionTick();
          _convertValues(unit);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        color: isActive ? grit.accent : Colors.transparent,
        child: Text(
          unit,
          style: GritTextStyles.labelCaps().copyWith(
            fontSize: 12,
            color: isActive ? Colors.white : grit.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, bool isUpdate) {
    return GritPrimaryButton(
      label: isUpdate ? "UPDATE LOG" : "SAVE MEASUREMENTS",
      onPressed: _save,
      isLoading: _isSaving,
      icon: PhosphorIcons.arrowRight(),
    );
  }
}

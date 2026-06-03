import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/utils/workout_utils.dart';
import '../../core/theme/grit_theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/dao_providers.dart';
import '../../shared/widgets/grit_button.dart';
import '../../shared/widgets/grit_input.dart';
import '../../shared/widgets/grit_date_picker.dart';
import '../../data/models/body_weight_entry.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/routes.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Profile Data
  final TextEditingController _nameController = TextEditingController();
  DateTime _dateOfBirth = DateTime.now().subtract(const Duration(days: 365 * 25));
  bool _dobSelected = true;

  // Biometrics
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _feetController = TextEditingController();
  final TextEditingController _inchesController = TextEditingController();
  String _weightUnit = 'KG';
  String _heightUnit = 'CM';

  // Training History
  DateTime _trainingSince = DateTime.now();
  bool _historySelected = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _heightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PLEASE ENTER YOUR NAME')),
        );
        return;
      }
    }

    if (_currentStep == 1) {
      final isHeightEmpty = _heightUnit == 'FT-IN'
          ? (_feetController.text.isEmpty && _inchesController.text.isEmpty)
          : _heightController.text.isEmpty;
      if (_weightController.text.isEmpty || isHeightEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WEIGHT AND HEIGHT ARE REQUIRED')),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Scaffold(
      backgroundColor: grit.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildIdentityStep(),
                  _buildBiometricsStep(),
                  _buildHistoryStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(GritSpacing.horizontalMargin),
              child: GritPrimaryButton(
                label: _currentStep == 2 ? 'COMPLETE SETUP' : 'NEXT',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final grit = Theme.of(context).grit;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= _currentStep;
          return Expanded(
            child: Container(
              height: 2,
              margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
              color: active ? grit.accent : grit.surface2,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIdentityStep() {
    final grit = Theme.of(context).grit;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(GritSpacing.horizontalMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              'assets/images/grit_main_logo.png',
              width: 80,
              height: 80,
            ),
          ),
          const SizedBox(height: 40),
          Text('WHAT SHOULD\nWE CALL YOU?', style: GritTextStyles.displayMedium()),
          const SizedBox(height: 32),
          
          Focus(
            onFocusChange: (hasFocus) {
              setState(() {});
            },
            child: Builder(
              builder: (context) {
                final hasFocus = Focus.of(context).hasFocus;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: grit.surface,
                    border: Border.all(
                      color: hasFocus ? grit.accent : grit.border,
                      width: hasFocus ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: GritTextStyles.metric(32, color: grit.textPrimary),
                    decoration: const InputDecoration(
                      hintText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                );
              }
            ),
          ),
          
          const SizedBox(height: 48),
          Text('DATE OF BIRTH', style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 12),
          GritDatePicker(
            initialDate: _dateOfBirth,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            onDateChanged: (date) {
              setState(() {
                _dateOfBirth = date;
                _dobSelected = true;
              });
            },
          ),
          if (_dobSelected)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                DateFormat('dd.MM.yyyy').format(_dateOfBirth),
                style: GritTextStyles.mono(12, color: grit.accent, weight: FontWeight.w700),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildBiometricsStep() {
    final grit = Theme.of(context).grit;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(GritSpacing.horizontalMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text('MEASUREMENTS', style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text('HEIGHT AND\nWEIGHT.', style: GritTextStyles.displayMedium()),
          const SizedBox(height: 48),
          
          // Weight
          Row(
            children: [
              Expanded(child: Text('WEIGHT', style: GritTextStyles.metric(24, color: grit.textPrimary))),
              SizedBox(
                width: 140,
                child: GritNumericInput(
                  controller: _weightController,
                  label: _weightUnit,
                  onChanged: (v) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _unitToggle(['KG', 'LBS'], _weightUnit, (v) {
                if (_weightUnit != v) {
                  final val = double.tryParse(_weightController.text);
                  if (val != null) {
                    if (v == 'LBS') {
                      _weightController.text = WorkoutUtils.formatDecimal(val * 2.20462);
                    } else {
                      _weightController.text = WorkoutUtils.formatDecimal(val / 2.20462);
                    }
                  }
                  setState(() => _weightUnit = v);
                }
              }),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Height
          Row(
            children: [
              Expanded(child: Text('HEIGHT', style: GritTextStyles.metric(24, color: grit.textPrimary))),
              if (_heightUnit == 'FT-IN') ...[
                SizedBox(
                  width: 90,
                  child: GritNumericInput(
                    controller: _feetController,
                    label: 'FT',
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: GritNumericInput(
                    controller: _inchesController,
                    label: 'IN',
                    onChanged: (v) => setState(() {}),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: 140,
                  child: GritNumericInput(
                    controller: _heightController,
                    label: _heightUnit,
                    onChanged: (v) => setState(() {}),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _unitToggle(['CM', 'FT-IN'], _heightUnit, (v) {
                if (_heightUnit != v) {
                  if (v == 'FT-IN') {
                    final val = double.tryParse(_heightController.text);
                    if (val != null) {
                      final totalInches = val * 0.393701;
                      final feet = (totalInches / 12).floor();
                      final inches = totalInches % 12;
                      _feetController.text = feet.toString();
                      _inchesController.text = WorkoutUtils.formatDecimal(inches);
                    }
                  } else {
                    final feetVal = double.tryParse(_feetController.text) ?? 0.0;
                    final inchVal = double.tryParse(_inchesController.text) ?? 0.0;
                    final totalInches = (feetVal * 12) + inchVal;
                    if (totalInches > 0) {
                      _heightController.text = WorkoutUtils.formatDecimal(totalInches / 0.393701);
                    }
                  }
                  setState(() => _heightUnit = v);
                }
              }),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _unitToggle(List<String> options, String current, Function(String) onSelect) {
    final grit = Theme.of(context).grit;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: grit.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = opt == current;
          return GestureDetector(
            onTap: () => onSelect(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? grit.accent : Colors.transparent,
              ),
              child: Text(
                opt,
                style: GritTextStyles.tileSubtitle().copyWith(
                  color: isSelected ? Colors.white : grit.textSecondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryStep() {
    final grit = Theme.of(context).grit;
    return Padding(
      padding: const EdgeInsets.all(GritSpacing.horizontalMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text('START DATE', style: GritTextStyles.labelMicro().copyWith(color: grit.textSecondary, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text('WHEN DID YOU\nSTART TRAINING?', style: GritTextStyles.displayMedium().copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 48),
          
          GritDatePicker(
            initialDate: _trainingSince,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
            onDateChanged: (date) {
              setState(() {
                _trainingSince = date;
                _historySelected = true;
              });
            },
          ),
          
          if (_historySelected)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                DateFormat('dd.MM.yyyy').format(_trainingSince),
                style: GritTextStyles.mono(12, color: grit.accent, weight: FontWeight.w700),
              ),
            ),
            
          const SizedBox(height: 48),
          Text(
            'WE USE THIS TO CALCULATE YOUR PROGRESS AND STREAKS FROM YOUR FIRST DAY.',
            style: GritTextStyles.labelMicro().copyWith(color: grit.muted, height: 1.2, letterSpacing: 1),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Future<void> _finish() async {
    try {
      final notifier = ref.read(profileProvider.notifier);
      // Update Profile
      final weightVal = double.tryParse(_weightController.text);
      double? heightCm;
      if (_heightUnit == 'FT-IN') {
        final feet = double.tryParse(_feetController.text) ?? 0.0;
        final inches = double.tryParse(_inchesController.text) ?? 0.0;
        final totalInches = (feet * 12) + inches;
        heightCm = totalInches > 0 ? totalInches / 0.393701 : null;
      } else {
        heightCm = double.tryParse(_heightController.text);
      }

      // Update Profile
      await notifier.updateProfile(
        displayName: _nameController.text.trim(),
        dateOfBirth: _dateOfBirth.toIso8601String(),
        heightCm: heightCm,
        trainingSinceYear: _trainingSince.year,
      );
      
      await notifier.setWeightUnit(_weightUnit);
      await notifier.setHeightUnit(_heightUnit);
      
      // Log Initial Weight
      if (weightVal != null && weightVal > 0) {
        double weightKg = _weightUnit == 'LBS' ? weightVal / 2.20462 : weightVal;
        
        final dao = ref.read(bodyWeightDaoProvider);
        await dao.insert(BodyWeightEntry(
          weightKg: weightKg,
          loggedAt: DateTime.now().toIso8601String(),
          notes: 'INITIAL WEIGHT',
        ));
      }

      await notifier.setOnboarded();
      
      try {
        await ref.read(sessionsDaoProvider).closeAllActiveSessions();
      } catch (_) {}

      if (mounted) context.go(GritRoutes.dashboard);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ERROR SAVING PROFILE: $e')),
        );
      }
    }
  }
}

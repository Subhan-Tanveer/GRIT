import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../providers/profile_provider.dart';
import '../../providers/dao_providers.dart';
import '../../providers/metrics_provider.dart';
import '../../shared/widgets/grit_components.dart';
import '../../data/models/body_weight_entry.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/workout_utils.dart';
import '../../shared/widgets/grit_date_picker.dart';
import '../../app/routes.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _dobController;
  late TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.displayName);
    _heightController = TextEditingController(
        text: _formatHeightForEditor(profile.heightCm, profile.heightUnit));
    _weightController = TextEditingController();
    _dobController = TextEditingController(text: _formatToDMY(profile.dateOfBirth));
    _yearController =
        TextEditingController(text: profile.trainingSinceYear.toString());

    // Initialize weight when data is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final weightAsync = ref.read(bodyWeightProvider);
      if (weightAsync is AsyncData<List<BodyWeightEntry>>) {
        final entries = weightAsync.value;
        if (entries.isNotEmpty) {
          double weight = entries.first.weightKg;
          if (profile.weightUnit == 'LBS') {
            weight = weight * 2.20462;
          }
          _weightController.text = WorkoutUtils.formatDecimal(weight);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final grit = Theme.of(context).grit;
    final name = profile.displayName.toUpperCase();
    String initials = 'U';
    if (name.isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length > 1) {
        initials = (parts[0][0] + parts[1][0]);
      } else {
        initials = parts[0].substring(0, parts[0].length.clamp(0, 2));
      }
    }

    return Scaffold(
      backgroundColor: grit.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildEditorHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 8),
                    child: GritCard(
                      title: 'IDENTITY',
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: grit.background,
                              border: Border.all(color: grit.border),
                              image: profile.photoPath != null
                                  ? DecorationImage(
                                      image: FileImage(File(profile.photoPath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: profile.photoPath == null
                                ? Text(initials,
                                    style: GritTextStyles.displayMedium().copyWith(
                                        color: grit.accent,
                                        fontWeight: FontWeight.w700))
                                : null,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickPhoto,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: grit.accent, width: 1.5),
                                  color: grit.accent.withValues(alpha: 0.05),
                                ),
                                child: Text('REPLACE PHOTO',
                                    textAlign: TextAlign.center,
                                    style: GritTextStyles.labelCaps().copyWith(
                                        color: grit.accent,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _field(context, 'NAME', _nameController, 'DISPLAY NAME'),
                  _field(context, 'DATE OF BIRTH', _dobController, 'DD / MM / YYYY',
                      onTap: () => _selectDate(context)),
                  _field(context, 'HEIGHT (${profile.heightUnit})', _heightController,
                      profile.heightUnit == 'CM' ? '178' : '5\' 10"'),
                  _field(context, 'CURRENT WEIGHT (${profile.weightUnit})', _weightController,
                      profile.weightUnit == 'KG' ? '75.0' : '165.0'),
                  _field(context, 'TRAINING SINCE', _yearController, 'YYYY',
                      onTap: () => _selectYear(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorHeader(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: grit.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(PhosphorIcons.arrowLeft(),
                    color: grit.textPrimary, size: 28),
                onPressed: () => context.canPop() ? context.pop() : context.go(GritRoutes.profile),
              ),
              const SizedBox(width: 12),
              Text(
                'EDIT PROFILE',
                style: GritTextStyles.headlineSmall().copyWith(
                    fontWeight: FontWeight.w900, height: 1),
              ),
            ],
          ),
          Material(
            color: grit.accent,
            child: InkWell(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('SAVE',
                    style: GritTextStyles.buttonPrimary().copyWith(
                        color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (image != null) {
      await ref.read(profileProvider.notifier).updateProfile(
            photoPath: image.path,
          );
    }
  }

  String _formatHeightForEditor(double? cm, String unit) {
    if (cm == null) return '';
    if (unit == 'CM') return cm.toStringAsFixed(0);
    final totalInches = cm / 2.54;
    final ft = (totalInches / 12).floor();
    final inch = (totalInches % 12).round();
    return "$ft' $inch\"";
  }

  String _formatToDMY(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      if (date.contains('/')) return date;
      final dt = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return date;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final profile = ref.read(profileProvider);
    DateTime initialDate;
    final dob = profile.dateOfBirth;
    try {
      if (dob != null && dob.contains('/')) {
        final parts = dob.split('/');
        initialDate = DateTime(
            int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } else {
        initialDate = dob != null
            ? DateTime.parse(dob)
            : DateTime(1995);
      }
    } catch (_) {
      initialDate = DateTime(1995);
    }

    final grit = Theme.of(context).grit;
    final DateTime? picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: grit.background,
          border: Border(top: BorderSide(color: grit.borderHighlight, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SELECT DATE', style: GritTextStyles.tileTitle().copyWith(fontWeight: FontWeight.w900)),
                IconButton(
                  icon: Icon(PhosphorIcons.check(), color: grit.accent),
                  onPressed: () => Navigator.pop(context, initialDate),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GritDatePicker(
              initialDate: initialDate,
              firstDate: DateTime(1940),
              lastDate: DateTime.now(),
              onDateChanged: (newDate) {
                initialDate = newDate;
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectYear(BuildContext context) async {
    final profile = ref.read(profileProvider);
    DateTime initialDate = DateTime(profile.trainingSinceYear);

    final grit = Theme.of(context).grit;
    final DateTime? picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: grit.background,
          border: Border(top: BorderSide(color: grit.borderHighlight, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SELECT YEAR', style: GritTextStyles.tileTitle().copyWith(fontWeight: FontWeight.w900)),
                IconButton(
                  icon: Icon(PhosphorIcons.check(), color: grit.accent),
                  onPressed: () => Navigator.pop(context, initialDate),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: GritDatePicker(
                initialDate: initialDate,
                firstDate: DateTime(1980),
                lastDate: DateTime.now(),
                onDateChanged: (newDate) {
                  initialDate = newDate;
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        _yearController.text = picked.year.toString();
      });
    }
  }


  Widget _field(BuildContext context, String label, TextEditingController ctrl, String hint,
      {VoidCallback? onTap}) {
    final grit = Theme.of(context).grit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(label,
                style: GritTextStyles.labelMicro().copyWith(
                    color: grit.textSecondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
          ),
          TextField(
            controller: ctrl,
            readOnly: onTap != null,
            onTap: onTap,
            style: GritTextStyles.tileTitle().copyWith(
                fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GritTextStyles.tileTitle().copyWith(
                  fontSize: 18, color: grit.muted, fontWeight: FontWeight.w800),
              fillColor: grit.surface2,
              filled: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: grit.border, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: grit.accent, width: 1.5),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
    );
  }

  Future<void> _save() async {
    GritHaptics.saveRoutine();
    final profile = ref.read(profileProvider);
    double? newWeight = double.tryParse(_weightController.text);

    if (newWeight != null) {
      if (profile.weightUnit == 'LBS') {
        newWeight = newWeight / 2.20462;
      }
      await ref.read(bodyWeightDaoProvider).upsert(newWeight);
      ref.invalidate(bodyWeightProvider);
    }

    await ref.read(profileProvider.notifier).updateProfile(
          displayName: _nameController.text,
          heightCm:
              _parseHeightFromEditor(_heightController.text, profile.heightUnit),
          dateOfBirth: _dobController.text,
          trainingSinceYear: int.tryParse(_yearController.text),
        );
    if (mounted) {
      context.go(GritRoutes.profile);
    }
  }

  double? _parseHeightFromEditor(String value, String unit) {
    if (unit == 'CM') return double.tryParse(value);
    try {
      final parts = value.split("'");
      if (parts.length < 2) return double.tryParse(value);
      final ft = double.parse(parts[0].trim());
      final inchPart = parts[1].replaceAll('"', '').trim();
      final inch = double.parse(inchPart.isEmpty ? '0' : inchPart);
      return (ft * 12 + inch) * 2.54;
    } catch (e) {
      return double.tryParse(value);
    }
  }
}

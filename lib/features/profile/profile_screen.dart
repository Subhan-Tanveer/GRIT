import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/haptics.dart';
import '../../providers/profile_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../data/models/user_profile.dart';
import '../../core/utils/workout_utils.dart';
import '../../core/theme/grit_theme.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../app/routes.dart';
import '../../shared/widgets/grit_button.dart';
import '../../providers/gamification_provider.dart';
import '../../shared/widgets/gamification_widgets.dart';
import '../../providers/social_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final profile = ref.watch(profileProvider);
    final weightHistory = ref.watch(bodyWeightProvider);

    return Scaffold(
      backgroundColor: grit.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 12),
          decoration: BoxDecoration(
            border:
                Border(bottom: BorderSide(color: grit.border, width: 1)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Text(
                  'PROFILE',
                  style: GritTextStyles.headlineSmall().copyWith(
                    color: grit.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileIdentityHeader(profile: profile),
            const GamificationPreviewCard(),
            MetricGrid(
              profile: profile,
              weightHistoryAsync: weightHistory,
            ),
            const SizedBox(height: GritSpacing.sectionSpacing),
            _buildSettingsSection(context, ref, profile),
            _buildMeasurementsButton(context),
            const SizedBox(height: GritSpacing.sectionSpacing),
            _buildSystemSection(context, ref),
            const SizedBox(height: GritSpacing.sectionSpacing * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
      BuildContext context, WidgetRef ref, UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _buildToggleRow(
          context,
          label: 'WEIGHT UNIT',
          value: profile.weightUnit,
          options: ['KG', 'LBS'],
          onToggle: (val) =>
              ref.read(profileProvider.notifier).setWeightUnit(val),
        ),
        _buildToggleRow(
          context,
          label: 'HEIGHT UNIT',
          value: (profile.heightUnit == 'FT·IN' || profile.heightUnit == 'FT/IN') ? 'FT-IN' : profile.heightUnit,
          options: ['CM', 'FT-IN'],
          onToggle: (val) =>
              ref.read(profileProvider.notifier).setHeightUnit(val),
        ),
      ],
    );
  }

  Widget _buildToggleRow(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> options,
    required Function(String) onToggle,
  }) {
    final grit = Theme.of(context).grit;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 0),
      decoration: BoxDecoration(
        color: grit.background,
        border: Border(top: BorderSide(color: grit.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GritTextStyles.tileTitle().copyWith(
              color: grit.textPrimary,
              letterSpacing: 2,
            ),
          ),
          TogglePill(
            value: value,
            options: options,
            onToggle: onToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsButton(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Column(
      children: [

        InkWell(
          onTap: () {
            GritHaptics.selectionTick();
            context.push(GritRoutes.progressPhotos);
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin),
            decoration: BoxDecoration(
              color: grit.background,
              border: Border(
                top: BorderSide(color: grit.borderHighlight, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PROGRESS PHOTOS',
                  style: GritTextStyles.tileTitle().copyWith(
                    color: grit.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                Icon(PhosphorIcons.caretRight(), size: 20, color: grit.accent),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.1),
        InkWell(
          onTap: () {
            GritHaptics.selectionTick();
            context.push(GritRoutes.strengthStandards);
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin),
            decoration: BoxDecoration(
              color: grit.background,
              border: Border(
                top: BorderSide(color: grit.borderHighlight, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'STRENGTH STANDARDS',
                  style: GritTextStyles.tileTitle().copyWith(
                    color: grit.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                Icon(PhosphorIcons.caretRight(), size: 20, color: grit.accent),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 290.ms).slideY(begin: 0.1),
        InkWell(
          onTap: () {
            GritHaptics.selectionTick();
            context.push(GritRoutes.measurements);
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin),
            decoration: BoxDecoration(
              color: grit.background,
              border: Border.symmetric(
                horizontal:
                    BorderSide(color: grit.borderHighlight, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BODY MEASUREMENTS',
                  style: GritTextStyles.tileTitle().copyWith(
                    color: grit.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                Icon(PhosphorIcons.caretRight(),
                    size: 20, color: grit.accent),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
        InkWell(
          onTap: () {
            GritHaptics.selectionTick();
            context.push(GritRoutes.wellness);
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin),
            decoration: BoxDecoration(
              color: grit.background,
              border: Border(
                bottom: BorderSide(color: grit.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WELLNESS HUB',
                  style: GritTextStyles.tileTitle().copyWith(
                    color: grit.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                Icon(PhosphorIcons.caretRight(),
                    size: 20, color: grit.accent),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.1),
        InkWell(
          onTap: () {
            GritHaptics.selectionTick();
            context.push(GritRoutes.nutrition);
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin),
            decoration: BoxDecoration(
              color: grit.background,
              border: Border(
                bottom: BorderSide(color: grit.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NUTRITION',
                  style: GritTextStyles.tileTitle().copyWith(
                    color: grit.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                Icon(PhosphorIcons.caretRight(),
                    size: 20, color: grit.accent),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 340.ms).slideY(begin: 0.1),
        InkWell(
          onTap: () {
            GritHaptics.selectionTick();
            context.push(GritRoutes.aiCoach);
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin),
            decoration: BoxDecoration(
              color: grit.background,
              border: Border(
                bottom: BorderSide(color: grit.borderHighlight, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GRIT AI COACH',
                  style: GritTextStyles.tileTitle().copyWith(
                    color: grit.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                Icon(PhosphorIcons.caretRight(),
                    size: 20, color: grit.accent),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 360.ms).slideY(begin: 0.1),
        InkWell(
          onTap: () {
            GritHaptics.selectionTick();
            context.push(GritRoutes.community);
          },
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin),
            decoration: BoxDecoration(
              color: grit.background,
              border: Border(
                bottom: BorderSide(color: grit.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COMMUNITY',
                  style: GritTextStyles.tileTitle().copyWith(
                    color: grit.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                Icon(PhosphorIcons.caretRight(),
                    size: 20, color: grit.accent),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildSystemSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: GritSpacing.horizontalMargin),
          child: Column(
            children: [
              GritSecondaryButton(
                label: 'ABOUT GRIT',
                icon: PhosphorIcons.caretRight(),
                onPressed: () {
                  GritHaptics.selectionTick();
                  context.push(GritRoutes.about);
                },
              ),
              const SizedBox(height: 12),
              GritSecondaryButton(
                label: 'LOG OUT',
                icon: PhosphorIcons.signOut(),
                onPressed: () {
                  GritHaptics.selectionTick();
                  ref.read(socialAuthProvider.notifier).logout();
                },
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}

class GamificationPreviewCard extends ConsumerWidget {
  const GamificationPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final summaryAsync = ref.watch(gamificationProvider);

    return InkWell(
      onTap: () {
        GritHaptics.selectionTick();
        context.push(GritRoutes.gamification);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: GritSpacing.horizontalMargin, vertical: 16),
        decoration: BoxDecoration(
          color: grit.surface,
          border: Border(bottom: BorderSide(color: grit.border, width: 1)),
        ),
        child: summaryAsync.when(
          loading: () => const GritSkeleton(height: 44, width: double.infinity),
          error: (_, __) => const SizedBox.shrink(),
          data: (summary) => Row(
            children: [
              LevelBadge(levelInfo: summary.levelInfo, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.levelInfo.name} · GRIT SCORE ${summary.gritScore}',
                      style: GritTextStyles.tileTitle().copyWith(
                        color: levelColor(summary.levelInfo.level, grit),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StreakFlame(streakDays: summary.stats.currentStreak),
                  ],
                ),
              ),
              Icon(PhosphorIcons.caretRight(), size: 20, color: grit.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileIdentityHeader extends StatefulWidget {
  final UserProfile profile;

  const ProfileIdentityHeader({super.key, required this.profile});

  @override
  State<ProfileIdentityHeader> createState() => _ProfileIdentityHeaderState();
}

class _ProfileIdentityHeaderState extends State<ProfileIdentityHeader> {
  bool _photoValid = false;

  @override
  void initState() {
    super.initState();
    _checkPhoto();
  }

  @override
  void didUpdateWidget(ProfileIdentityHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile.photoPath != oldWidget.profile.photoPath) {
      _checkPhoto();
    }
  }

  Future<void> _checkPhoto() async {
    if (widget.profile.photoPath == null) {
      if (mounted) setState(() => _photoValid = false);
      return;
    }
    final exists = await File(widget.profile.photoPath!).exists();
    if (mounted) setState(() => _photoValid = exists);
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final subLine = "${widget.profile.yearsLifting} YEARS LIFTING";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 32),
      decoration: BoxDecoration(
        color: grit.surface,
        border: Border(bottom: BorderSide(color: grit.border, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              GritHaptics.buttonTap();
              context.push(GritRoutes.profileEdit);
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: grit.surface2,
                border: Border.all(color: grit.accent, width: 2),
                image: _photoValid
                    ? DecorationImage(
                        image: FileImage(File(widget.profile.photoPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  if (!_photoValid)
                    Center(
                      child: Text(
                        widget.profile.initials,
                        style: GritTextStyles.displayMedium().copyWith(
                          color: grit.accent,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Transform.translate(
                      offset: const Offset(1, 1), // Optical nudge to corner
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: grit.accent,
                        child: Icon(
                          PhosphorIcons.pencilSimple(),
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .scale(duration: 300.ms, curve: Curves.easeOutBack)
              .fadeIn(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.profile.displayName.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GritTextStyles.headlineLarge().copyWith(
                    color: grit.textPrimary,
                    height: 1.0,
                  ),
                ).animate().fadeIn(delay: 50.ms).slideX(begin: -0.1),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: grit.borderHighlight, width: 1),
                  ),
                  child: Text(
                    subLine,
                    style: GritTextStyles.label(
                      11,
                      weight: FontWeight.w600,
                      color: grit.accent,
                      letterSpacing: 1.5,
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MetricGrid extends StatelessWidget {
  final UserProfile profile;
  final AsyncValue<List<dynamic>> weightHistoryAsync;

  const MetricGrid({
    super.key,
    required this.profile,
    required this.weightHistoryAsync,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      decoration: BoxDecoration(
        color: grit.background,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: weightHistoryAsync
                    .when(
                      data: (entries) {
                        String currentWeight = "--";
                        if (entries.isNotEmpty) {
                          double w = entries.last.weightKg;
                          if (profile.weightUnit == 'LBS') w *= 2.20462;
                          currentWeight = WorkoutUtils.formatWeight(w);
                        }
                        return MetricTile(
                          label: 'WEIGHT',
                          value: currentWeight,
                          unit: profile.weightUnit,
                          onTap: () => context.push(GritRoutes.weightHistory),
                          showHistoryBadge: true,
                        );
                      },
                      loading: () => MetricTile.loading(
                          label: 'WEIGHT', unit: profile.weightUnit),
                      error: (_, __) => MetricTile(
                          label: 'WEIGHT',
                          value: 'ERR',
                          unit: profile.weightUnit),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.1),
              ),
              Expanded(
                child: MetricTile(
                  label: 'HEIGHT',
                  value: WorkoutUtils.formatHeight(
                      profile.heightCm, profile.heightUnit),
                  unit: profile.heightUnit,
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'SINCE',
                  value: profile.trainingSinceYear.toString(),
                  unit: '${profile.yearsLifting} YRS',
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              ),
              Expanded(
                child: MetricTile(
                  label: 'AGE',
                  value: profile.age == 0 ? '--' : profile.age.toString(),
                  unit: 'YRS',
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool showHistoryBadge;
  final VoidCallback? onTap;
  final bool isLoading;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.showHistoryBadge = false,
    this.onTap = migratoryOnTap,
    this.isLoading = false,
  });

  // Simplified loading constructor
  factory MetricTile.loading({required String label, required String unit}) {
    return MetricTile(label: label, value: '', unit: unit, isLoading: true);
  }

  static void migratoryOnTap() {}

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return InkWell(
      onTap: onTap != migratoryOnTap
          ? () async {
              await GritHaptics.selectionTick();
              onTap!();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: grit.border, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GritTextStyles.tileSubtitle().copyWith(
                    color: grit.textSecondary,
                    letterSpacing: 2.0,
                  ),
                ),
                if (showHistoryBadge) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      border: Border.all(color: grit.accent, width: 1),
                    ),
                    child: Text(
                      'HISTORY',
                      style: GritTextStyles.tileSubtitle().copyWith(
                        fontSize: 8,
                        color: grit.accent,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const GritSkeleton(height: 42, width: 80)
            else
              Text(
                value,
                textAlign: TextAlign.center,
                style: GritTextStyles.displayMedium().copyWith(
                  color: grit.textPrimary,
                  height: 1.0,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              unit,
              textAlign: TextAlign.center,
              style: GritTextStyles.tileSubtitle().copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: grit.textSecondary,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TogglePill extends StatelessWidget {
  final String value;
  final List<String> options;
  final Function(String) onToggle;

  const TogglePill({
    super.key,
    required this.value,
    required this.options,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: grit.border, width: 1),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isActive = value == opt;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (!isActive) {
                  GritHaptics.selectionTick();
                  onToggle(opt);
                }
              },
              child: Container(
                width: 90,
                height: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? grit.accent : Colors.transparent,
                ),
                child: Text(
                  opt.toUpperCase(),
                  style: GritTextStyles.tileSubtitle().copyWith(
                    fontSize: 12,
                    color: isActive ? Colors.white : grit.muted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/date_provider.dart';
import '../../providers/metrics_provider.dart';
import '../../data/models/today_workout_stats.dart';
import '../../core/theme/grit_theme.dart';
import 'widgets/muscle_breakdown_panel.dart';
import '../../shared/widgets/grit_section_header.dart';
import '../../core/utils/haptics.dart';
import '../../core/utils/workout_utils.dart';
import '../../providers/dao_providers.dart';
import '../../providers/profile_provider.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../core/utils/muscle_mapper.dart';
import 'package:muscle_selector/muscle_selector.dart';
import '../../shared/widgets/scroll_animations.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(viewportFraction: 0.92);
  bool _isTogglingRest = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Scaffold(
      backgroundColor: grit.background,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // HERO SECTION: GREETING (Fade)
            SliverToBoxAdapter(
              child: FadeOnScroll(
                scrollController: _scrollController,
                child: _buildGreetingPanel(),
              ),
            ),

            // STICKY HEADER: WEEKLY ACTIVITY
            SliverPersistentHeader(
              pinned: true,
              delegate: SliverHeaderDelegate(
                minHeight: 48,
                maxHeight: 48,
                child: Container(
                  color: grit.background,
                  child: _buildActivityPanelHeader(),
                ),
              ),
            ),

            // WEEKLY STRIP
            SliverToBoxAdapter(
              child: ScrollAnimatedWidget(
                child: _buildActivityPanelBody(),
              ),
            ),

            // STICKY HEADER: TODAY'S WORKOUT
            SliverPersistentHeader(
              pinned: true,
              delegate: SliverHeaderDelegate(
                minHeight: 48,
                maxHeight: 48,
                child: Container(
                  color: grit.background,
                  child: _buildTodayHeader(),
                ),
              ),
            ),

            // MUSCLE SELECTOR & METRICS
            SliverToBoxAdapter(
              child: ScrollAnimatedWidget(
                child: _buildMuscleSelectorPanel(),
              ),
            ),

            // DYNAMIC BOTTOM SPACER (Safe Area)
            SliverToBoxAdapter(
              child: Builder(builder: (context) {
                return SizedBox(
                    height: GritSpacing.bottomSafeArea(context) + GritSpacing.cardMargin);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingPanel() {
    final streakAsync = ref.watch(streakProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final dateStr =
        DateFormat('EEEE · MMM d').format(selectedDate).toUpperCase();

    final workoutAsync = ref.watch(dashboardWorkoutProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: GritSpacing.horizontalMargin, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: GritTextStyles.mono(
                    11,
                    weight: FontWeight.w800,
                    color: Theme.of(context).grit.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                streakAsync.when(
                  data: (streak) => Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${streak.current} DAY\n',
                          style: GritTextStyles.metric(56,
                              height: 0.92,
                              letterSpacing: -1.5,
                              weight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: 'STREAK.',
                          style: GritTextStyles.metric(56,
                                  height: 0.92,
                                  letterSpacing: -1.5,
                                  weight: FontWeight.w800)
                              .copyWith(
                            color: Theme.of(context).grit.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GritSkeleton(width: 140, height: 48),
                      const SizedBox(height: 8),
                      GritSkeleton(width: 180, height: 48),
                    ],
                  ),
                  error: (_, __) => Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '0 DAY\n',
                          style: GritTextStyles.metric(56,
                              height: 0.92,
                              letterSpacing: -1.5,
                              weight: FontWeight.w800),
                        ),
                        TextSpan(
                          text: 'STREAK.',
                          style: GritTextStyles.metric(56,
                                  height: 0.92,
                                  letterSpacing: -1.5,
                                  weight: FontWeight.w800)
                              .copyWith(
                            color: Theme.of(context)
                                .grit
                                .accent
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          workoutAsync.when(
            data: (data) => Row(
              children: [
                _buildRestToggle(data.stats.isRestDay, () async {
                  if (_isTogglingRest) return;
                  setState(() => _isTogglingRest = true);
                  try {
                    final dateIso = DateTime(selectedDate.year,
                            selectedDate.month, selectedDate.day)
                        .toIso8601String();
                    await ref
                        .read(sessionsDaoProvider)
                        .toggleRestDay(dateIso, !data.stats.isRestDay);
                    ref.invalidate(dashboardDataProvider);
                    ref.invalidate(streakProvider);
                    ref.invalidate(dashboardWorkoutProvider);
                    GritHaptics.selectionTick();
                  } finally {
                    if (mounted) setState(() => _isTogglingRest = false);
                  }
                }),
              ],
            ),
            loading: () => const SizedBox(width: 60, height: 28),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildRestToggle(bool isRest, VoidCallback onToggle) {
    final grit = Theme.of(context).grit;
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44, // Minimum ergonomic touch target
        height: 44,
        alignment: Alignment.centerRight,
        child: Container(
          width: 42,
          height: 20,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isRest ? grit.accent.withValues(alpha: 0.15) : grit.surface2,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: isRest ? grit.accent : grit.border,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Align(
                alignment:
                    isRest ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 14,
                  height: 16, // Aligned to 4pt grid
                  decoration: BoxDecoration(
                    color: isRest ? grit.accent : grit.muted,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityPanelHeader() {
    return const GritSectionHeader(label: "WEEKLY ACTIVITY");
  }

  Widget _buildActivityPanelBody() {
    final dashboardData = ref.watch(dashboardDataProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final grit = Theme.of(context).grit;

    return Container(
      color: grit.background, // Flat on black
      child: dashboardData.when(
        data: (data) => _buildWeeklyStrip(
            data.trainedDays, data.restDays, data.dailyVolumes, selectedDate),
        loading: () => dashboardData.hasValue
            ? _buildWeeklyStrip(
                dashboardData.value!.trainedDays,
                dashboardData.value!.restDays,
                dashboardData.value!.dailyVolumes,
                selectedDate)
            : const GritSkeleton(height: 80),
        error: (e, __) => const SizedBox(),
      ),
    );
  }

  Widget _buildTodayHeader() {
    return const GritSectionHeader(label: "TODAY'S WORKOUT");
  }

  Widget _buildWeeklyStrip(List<bool> activity, List<bool> restDays,
      List<double> volumes, DateTime selectedDate) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final profile = ref.watch(profileProvider);
    final startOfWeek =
        WorkoutUtils.getStartOfWeek(selectedDate, profile.firstDayOfWeek);
    final today = DateTime.now(); // For highlighting 'Today' real-time

    final grit = Theme.of(context).grit;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: GritSpacing.horizontalMargin, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final isTrained = activity[index];
                final dayDate = startOfWeek.add(Duration(days: index));
                final isToday = dayDate.isAtSameMomentAs(today) ||
                    (dayDate.year == today.year &&
                        dayDate.month == today.month &&
                        dayDate.day == today.day);
                final isSelected = dayDate.year == selectedDate.year &&
                    dayDate.month == selectedDate.month &&
                    dayDate.day == selectedDate.day;

                return GestureDetector(
                  key: ValueKey('day_${dayDate.toIso8601String()}'),
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).setDate(dayDate);
                    GritHaptics.selectionTick();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Text(
                        days[index],
                        style: GritTextStyles.labelMicro().copyWith(
                          color: isSelected
                              ? grit.textPrimary
                              : (isToday ? grit.accent : grit.muted),
                          fontWeight: (isSelected || isToday)
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isTrained ? grit.accent : Colors.transparent,
                          borderRadius: BorderRadius.zero,
                          border: isSelected
                              ? Border.all(color: grit.accent, width: 2)
                              : (isTrained
                                  ? null
                                  : Border.all(
                                      color:
                                          isToday ? grit.accent : grit.border,
                                      width: isToday
                                          ? 2
                                          : 1, // Stronger industrial stroke for today
                                    )),
                        ),
                        child: !isTrained && restDays[index]
                            ? CustomPaint(
                                painter: DiagonalHatchPainter(
                                  color: grit.border,
                                  gap: 4,
                                  strokeWidth: 1.2,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleSelectorPanel() {
    final dashboardWorkoutAsync = ref.watch(dashboardWorkoutProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return dashboardWorkoutAsync.when(
      data: (data) => data.stats.isRestDay
          ? _buildRestDayPanel(selectedDate)
          : _buildUnifiedSelectorPanel(data,
              key: ValueKey('dash_panel_${selectedDate.toIso8601String()}')),
      loading: () => dashboardWorkoutAsync.hasValue
          ? (dashboardWorkoutAsync.value!.stats.isRestDay
              ? _buildRestDayPanel(selectedDate)
              : _buildUnifiedSelectorPanel(dashboardWorkoutAsync.value!,
                  key: ValueKey(
                      'dash_panel_stale_${selectedDate.toIso8601String()}')))
          : const _MuscleSelectorSkeleton(),
      error: (e, __) => _buildUnifiedSelectorPanel(DashboardWorkoutData.empty(),
          key: const ValueKey('dash_panel_error')),
    );
  }

  Widget _buildRestDayPanel(DateTime date) {
    final dashboardData = ref.watch(dashboardDataProvider).valueOrNull;
    int totalRestDaysInWeek = 0;

    if (dashboardData != null) {
      for (int i = 0; i < 7; i++) {
        if (dashboardData.restDays[i]) {
          totalRestDaysInWeek++;
        }
      }
    }

    final grit = Theme.of(context).grit;
    final double panelHeight = 240;
    return Container(
      height: panelHeight,
      margin: const EdgeInsets.symmetric(
        horizontal: GritSpacing.horizontalMargin,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: grit.surface,
        border: Border.all(color: grit.borderHighlight, width: 2),
      ),
      child: Stack(
        children: [
          // Brutalist Accent Tag
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              color: grit.accent,
            ),
          ),
          // Mechanical indicator crosshairs in corners
          Positioned(
            top: 12,
            right: 12,
            child: Icon(
              PhosphorIcons.plus(),
              color: grit.borderHighlight.withValues(alpha: 0.5),
              size: 16,
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Icon(
              PhosphorIcons.plus(),
              color: grit.borderHighlight.withValues(alpha: 0.5),
              size: 16,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "REST DAY",
                  style: GritTextStyles.displayMedium()
                      .copyWith(color: grit.textPrimary),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: totalRestDaysInWeek.toString().padLeft(2, '0'),
                        style: GritTextStyles.mono(14,
                            weight: FontWeight.w700, color: grit.accent),
                      ),
                      TextSpan(
                        text: " REST DAYS THIS WEEK",
                        style: GritTextStyles.mono(14,
                            weight: FontWeight.w700, color: grit.textPrimary),
                      ),
                    ],
                  ),
                  style: GritTextStyles.mono(
                    14,
                    weight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedSelectorPanel(DashboardWorkoutData data, {Key? key}) {
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final double baseWidth = constraints.maxWidth;
        final double mapHeight = baseWidth * 0.78;
        const double scaleFactor = 1.15;

        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 320),
          child: Column(
            children: [
              // MAP SECTION
              SizedBox(
                width: baseWidth,
                height: mapHeight,
                child: ClipRect(
                  child: Transform.translate(
                    offset: Offset(baseWidth * -0.05,
                        0), // Responsive proportion instead of hardcoded -18
                    child: Transform.scale(
                      scale: scaleFactor,
                      alignment: Alignment.topCenter,
                      child: IgnorePointer(
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            // STATIC BASE LAYER
                            MusclePickerMap(
                              width: baseWidth,
                              height: baseWidth * 1.1,
                              map: Maps.BODY,
                              onChanged: (_) {},
                              strokeColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).grit.muted
                                  : Theme.of(context).grit.textSecondary,
                              selectedColor: Theme.of(context).grit.accent,
                              initialSelectedGroups: const [],
                            ), // BUTTERY QUICK CROSS-FADE HIGHLIGHTS
                            Stack(
                              key: ValueKey(
                                  'highlights_${data.muscles.primary.join(",")}_${data.muscles.secondary.join(",")}_${data.stats.isRestDay}'),
                              children: [
                                if (data.muscles.secondary.isNotEmpty)
                                  Builder(builder: (context) {
                                    final primaryIds =
                                        MuscleMapper.mapToPackageGroups(
                                                data.muscles.primary)
                                            .toSet();
                                    final secondaryIds = MuscleMapper
                                            .mapToPackageGroups(
                                                data.muscles.secondary)
                                        .where((id) => !primaryIds.contains(id))
                                        .toList();

                                    if (secondaryIds.isEmpty) {
                                      return const SizedBox.shrink();
                                    }

                                    return MusclePickerMap(
                                      width: baseWidth,
                                      height: baseWidth * 1.1,
                                      map: Maps.BODY,
                                      onChanged: (_) {},
                                      strokeColor: Colors.transparent,
                                      selectedColor: Theme.of(context)
                                          .grit
                                          .accent
                                          .withValues(alpha: 0.35),
                                      initialSelectedGroups: secondaryIds,
                                    );
                                  }),
                                if (data.muscles.primary.isNotEmpty)
                                  MusclePickerMap(
                                    width: baseWidth,
                                    height: baseWidth * 1.1,
                                    map: Maps.BODY,
                                    onChanged: (_) {},
                                    strokeColor: Colors.transparent,
                                    selectedColor:
                                        Theme.of(context).grit.accent,
                                    initialSelectedGroups:
                                        MuscleMapper.mapToPackageGroups(
                                            data.muscles.primary),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // METRICS SECTION (QUICK CROSS-FADE VALUES)
              _buildTodayMetricsPanel(data.stats),
              const SizedBox(height: 12),
              // INDUSTRIAL MUSCLE BREAKDOWN (SPEC-SHEET)
              MuscleBreakdownPanel(
                key: ValueKey(
                    'breakdown_${data.muscles.primary.length}_${data.muscles.secondary.length}'),
                data: data,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayMetricsPanel(TodayWorkoutStats stats) {
    final grit = Theme.of(context).grit;
    final profile = ref.watch(profileProvider);
    final isLb = profile.weightUnit == 'LBS';
    final displayVolume =
        isLb ? WorkoutUtils.kgToLb(stats.totalVolume) : stats.totalVolume;
    final unitLabel = isLb ? 'LBS' : 'KG';

    return Container(
      margin: const EdgeInsets.fromLTRB(
          GritSpacing.horizontalMargin, GritSpacing.cardGap, GritSpacing.horizontalMargin, GritSpacing.cardMargin),
      decoration: BoxDecoration(
        color: grit.surface,
        border: Border.all(color: grit.border, width: 1),
      ),
      child: Column(
        children: [
          // Row 1: TOTAL VOLUME (Primary Prominence)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: grit.border, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricItemHeader(context, "TOTAL VOLUME"),
                Text(
                  "${displayVolume.toInt()} $unitLabel",
                  style: GritTextStyles.metric(
                    24,
                    weight: FontWeight.w900,
                    color: grit.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Row 2: FOCUS STATS (Split 50/50 with breathing room)
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: _buildMetricItemBody(
                      context,
                      "DOMINANT",
                      stats.dominantLabel,
                      grit.accent,
                    ),
                  ),
                ),
                Container(width: 1, color: grit.border),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: _buildMetricItemBody(
                      context,
                      "WEAKEST",
                      stats.weakestLabel,
                      grit.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItemHeader(BuildContext context, String label) {
    return Text(
      label,
      style: GritTextStyles.mono(
        10,
        letterSpacing: 2.0,
        weight: FontWeight.w700,
        color: Theme.of(context).grit.muted,
      ),
    );
  }

  Widget _buildMetricItemBody(
      BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricItemHeader(context, label),
        const SizedBox(height: 8),
        SizedBox(
          height: 28,
          child: Container(
            key: ValueKey('metric_${label}_$value'),
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GritTextStyles.metric(22, color: color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MuscleSelectorSkeleton extends StatelessWidget {
  const _MuscleSelectorSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      padding:
          const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin),
      child: Column(
        children: [
          const Expanded(
            child: Center(
              child: Opacity(
                opacity: 0.1,
                child: GritSkeleton(height: 300, width: 200),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
                3,
                (i) => const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: GritSkeleton(height: 40),
                      ),
                    )),
          ),
          const SizedBox(height: 12),
          GritSkeleton(height: 60, width: double.infinity),
        ],
      ),
    );
  }
}

class DiagonalHatchPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DiagonalHatchPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    for (double i = -size.height * 2; i < size.width + size.height; i += gap) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

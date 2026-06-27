import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../providers/wellness_provider.dart';
import '../../shared/widgets/wellness_widgets.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../shared/widgets/grit_button.dart';
import '../../utils/wellness.dart';

class WellnessScreen extends ConsumerStatefulWidget {
  const WellnessScreen({super.key});

  @override
  ConsumerState<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends ConsumerState<WellnessScreen> {
  final _notesController = TextEditingController();
  bool _hydratedFromToday = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final summaryAsync = ref.watch(wellnessSummaryProvider);
    final draft = ref.watch(wellnessNotifierProvider);
    final notifier = ref.read(wellnessNotifierProvider.notifier);

    summaryAsync.whenData((summary) {
      if (!_hydratedFromToday && summary.today != null) {
        _hydratedFromToday = true;
        notifier.loadFrom(summary.today!);
        _notesController.text = summary.today!.notes;
      }
    });

    return Scaffold(
      backgroundColor: grit.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: grit.border, width: 1)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: grit.textPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Text(
                  'WELLNESS',
                  style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: GritSkeleton(height: 220, width: 220)),
        error: (e, st) => Center(
          child: Text('Failed to load wellness data', style: GritTextStyles.label(13, color: grit.textSecondary)),
        ),
        data: (summary) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: ReadinessGauge(score: draft.readinessScore))
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.9, 0.9)),
              const SizedBox(height: 32),
              _sectionLabel(context, 'HOW DO YOU FEEL?'),
              const SizedBox(height: 12),
              MoodSelector(selectedMood: draft.mood, onSelected: (m) {
                GritHaptics.selectionTick();
                notifier.setMood(m);
              }),
              const SizedBox(height: 28),
              _sectionLabel(context, 'SLEEP'),
              const SizedBox(height: 12),
              _sleepRow(context, draft.sleepHours, draft.sleepQuality, notifier),
              const SizedBox(height: 28),
              _sectionLabel(context, 'STRESS LEVEL'),
              const SizedBox(height: 8),
              _stressSlider(context, draft.stressLevel, notifier),
              const SizedBox(height: 32),
              GritPrimaryButton(
                label: 'SAVE CHECK-IN',
                onPressed: () async {
                  GritHaptics.mediumImpact();
                  notifier.setNotes(_notesController.text);
                  final score = await notifier.save();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Readiness score: $score — ${WellnessCalc.readinessLabel(score)}')),
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
              _sectionLabel(context, 'BREATHE'),
              const SizedBox(height: 16),
              const Center(child: BreathingExercise()),
              const SizedBox(height: 40),
              _sectionLabel(context, "TODAY'S JOURNAL PROMPT"),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: grit.surface,
                  border: Border.all(color: grit.border),
                ),
                child: Text(
                  journalPromptForDate(DateTime.now()),
                  style: GritTextStyles.label(14, color: grit.textSecondary, height: 1.5),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: GritTextStyles.label(13, color: grit.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Write a few lines...',
                  hintStyle: GritTextStyles.label(13, color: grit.muted),
                ),
              ),
              const SizedBox(height: 40),
              if (summary.history.length >= 2) ...[
                _sectionLabel(context, 'READINESS TREND'),
                const SizedBox(height: 16),
                _readinessChart(context, summary.history),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    final grit = Theme.of(context).grit;
    return Text(label, style: GritTextStyles.sectionHeader().copyWith(color: grit.textSecondary, letterSpacing: 1.5));
  }

  Widget _sleepRow(BuildContext context, double hours, int quality, WellnessNotifier notifier) {
    final grit = Theme.of(context).grit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${hours.toStringAsFixed(1)} HRS', style: GritTextStyles.dataValueLarge().copyWith(color: grit.textPrimary)),
            Row(
              children: List.generate(5, (i) {
                final filled = i < quality;
                return GestureDetector(
                  onTap: () {
                    GritHaptics.selectionTick();
                    notifier.setSleepQuality(i + 1);
                  },
                  child: Icon(
                    filled ? Icons.star : Icons.star_border,
                    size: 22,
                    color: filled ? grit.accent : grit.textSecondary,
                  ),
                );
              }),
            ),
          ],
        ),
        Slider(
          value: hours,
          min: 0,
          max: 12,
          divisions: 24,
          activeColor: grit.accent,
          inactiveColor: grit.surface2,
          onChanged: (v) => notifier.setSleepHours(v),
        ),
      ],
    );
  }

  Widget _stressSlider(BuildContext context, int stress, WellnessNotifier notifier) {
    final grit = Theme.of(context).grit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$stress / 10', style: GritTextStyles.dataValueLarge().copyWith(color: grit.textPrimary)),
        Slider(
          value: stress.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: grit.warning,
          inactiveColor: grit.surface2,
          onChanged: (v) => notifier.setStressLevel(v.round()),
        ),
      ],
    );
  }

  Widget _readinessChart(BuildContext context, List<dynamic> history) {
    final grit = Theme.of(context).grit;
    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), (history[i].readinessScore as int).toDouble()));
    }

    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) => FlLine(color: grit.border, strokeWidth: 0.5),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: grit.accent,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: grit.accent.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }
}

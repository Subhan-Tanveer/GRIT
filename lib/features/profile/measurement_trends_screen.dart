import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/grit_theme.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/profile_provider.dart';
import '../../shared/widgets/grit_error_state.dart';
import '../../shared/widgets/grit_empty_state.dart';
import '../../shared/widgets/grit_skeleton.dart';
import './widgets/site_selector_strip.dart';
import './widgets/measurement_chart_panel.dart';
import './widgets/latest_measurements_grid.dart';
import './widgets/measurement_history_tile.dart';
import '../../app/routes.dart';

class MeasurementTrendsScreen extends ConsumerStatefulWidget {
  const MeasurementTrendsScreen({super.key});

  @override
  ConsumerState<MeasurementTrendsScreen> createState() => _MeasurementTrendsScreenState();
}

class _MeasurementTrendsScreenState extends ConsumerState<MeasurementTrendsScreen> {
  String _selectedSite = 'ALL';
  String? _expandedEntryId;

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final historyAsync = ref.watch(measurementHistoryProvider);
    final displayUnit = ref.watch(profileProvider.select((p) =>
        (p.heightUnit == 'FT·IN' || p.heightUnit == 'FT-IN' || p.heightUnit == 'FT/IN') ? 'IN' : 'CM'));

    return Scaffold(
      backgroundColor: grit.background,
      appBar: _buildAppBar(context),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) return _buildEmptyState(context);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. SITE SELECTOR
              SliverToBoxAdapter(
                child: SiteSelectorStrip(
                  selectedSiteId: _selectedSite,
                  onSiteSelected: (siteId) => setState(() => _selectedSite = siteId),
                ),
              ),

              // 2. CHART SECTION (IF NOT ALL)
              if (_selectedSite != 'ALL')
                SliverToBoxAdapter(
                  child: MeasurementChartPanel(siteId: _selectedSite, unit: displayUnit)
                      .animate()
                      .fadeIn(duration: 400.ms, curve: Curves.easeOutExpo)
                      .slideY(begin: 0.1),
                ),

              // 3. CURRENT STATS (IF ALL)
              if (_selectedSite == 'ALL') ...[
                _buildSliverSectionHeader(context, 'CURRENT STATS', trailing: _buildLogNewAction(context)),
                SliverToBoxAdapter(
                  child: LatestMeasurementsGrid(latest: history.first, displayUnit: displayUnit),
                ),
              ],

              // 4. HISTORY LIST
              _buildSliverSectionHeader(context, 'HISTORY'),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = history[index];
                    final entryId = entry.id?.toString() ?? entry.createdAt;
                    
                    return MeasurementHistoryTile(
                      key: ValueKey('trend_row_$entryId'),
                      entry: entry,
                      displayUnit: displayUnit,
                      isExpanded: _expandedEntryId == entryId,
                      onToggle: () => setState(() {
                        _expandedEntryId = _expandedEntryId == entryId ? null : entryId;
                      }),
                    ).animate()
                     .fadeIn(delay: (100 + index.clamp(0, 10) * 20).ms)
                     .slideY(begin: 0.1, curve: Curves.easeOutExpo);
                  },
                  childCount: history.length,
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
        loading: () => _buildLoadingState(context),
        error: (e, _) => GritErrorState(
          error: e,
          onRetry: () => ref.invalidate(measurementHistoryProvider),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final grit = Theme.of(context).grit;
    return PreferredSize(
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
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(PhosphorIcons.arrowLeft(), color: grit.textPrimary, size: 28),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 12),
              Text(
                'MEASUREMENTS',
                style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverSectionHeader(BuildContext context, String label, {Widget? trailing}) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(GritSpacing.horizontalMargin, 24, GritSpacing.horizontalMargin, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GritTextStyles.sectionHeader(),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildLogNewAction(BuildContext context) {
    final grit = Theme.of(context).grit;
    return InkWell(
      onTap: () => context.push(GritRoutes.measurementsLog),
      child: Text(
        'UPDATE LOG [ + ]',
        style: GritTextStyles.labelMicro().copyWith(fontWeight: FontWeight.w900, color: grit.accent, letterSpacing: 2),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GritEmptyState(
      icon: PhosphorIcons.ruler(PhosphorIconsStyle.bold),
      title: 'NO MEASUREMENTS LOGGED',
      description: 'Track body metrics to visualize progression and metabolic changes over time.',
      actionLabel: 'LOG MEASUREMENTS',
      onAction: () => context.push(GritRoutes.measurementsLog),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Column(
      children: [
        const GritSkeleton(height: 48, width: double.infinity),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20),
            itemCount: 8,
            itemBuilder: (c, i) => Container(
              padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 16),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: grit.border, width: 1))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GritSkeleton(height: 18, width: 180),
                      const SizedBox(height: 6),
                      GritSkeleton(height: 14, width: 100),
                    ],
                  ),
                  const GritSkeleton(height: 24, width: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

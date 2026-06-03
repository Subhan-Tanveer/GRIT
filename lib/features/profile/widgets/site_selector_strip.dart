import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/grit_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/constants/biometric_sites.dart';

class Site {
  final String id;
  final String label;

  const Site({required this.id, required this.label});
}

class SiteSelectorStrip extends StatelessWidget {
  final String selectedSiteId;
  final ValueChanged<String> onSiteSelected;

  const SiteSelectorStrip({
    super.key,
    required this.selectedSiteId,
    required this.onSiteSelected,
  });

  static final List<Site> _sites = [
    const Site(id: 'ALL', label: 'ALL'),
    ...BiometricSites.all.map((s) => Site(id: s.id, label: s.label)),
  ];

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: grit.border, width: 1)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin),
        itemCount: _sites.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final site = _sites[index];
          final isActive = selectedSiteId == site.id;

          return Center(
            child: SiteSelectorChip(
              label: site.label,
              isActive: isActive,
              onTap: () => onSiteSelected(site.id),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, curve: Curves.easeOutExpo);
  }
}

class SiteSelectorChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const SiteSelectorChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    return GestureDetector(
      onTap: () {
        GritHaptics.selectionTick();
        onTap();
      },
      behavior: HitTestBehavior.opaque, // Ensure even the transparent padding captures taps
      child: Container(
        height: 44, // Standard ergonomic hit target
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: 200.ms,
          curve: Curves.easeOutQuad,
          height: 30, // Optimized for 8px-aligned rhythm (total 48 stripe - margins)
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? grit.accent : grit.surface2,
            borderRadius: BorderRadius.zero,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GritTextStyles.labelMicro().copyWith(
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.black : grit.textSecondary,
            ),
          ),
        ).animate(target: isActive ? 1 : 0)
         .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 200.ms, curve: Curves.easeOutBack),
      ),
    );
  }
}

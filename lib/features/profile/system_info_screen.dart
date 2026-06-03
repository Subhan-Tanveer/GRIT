import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../app/routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../shared/widgets/grit_section_header.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;

    return Scaffold(
      backgroundColor: grit.background,
      appBar: AppBar(
        backgroundColor: grit.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: grit.textPrimary, size: 22),
          onPressed: () => context.canPop() ? context.pop() : context.go(GritRoutes.profile),
        ),
        title: Text(
          "ABOUT",
          style: GritTextStyles.metric(20, weight: FontWeight.w900, color: grit.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: grit.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Center(
              child: Image.asset(
                'assets/images/grit_main_logo.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 24),
            _buildDevSection(context),
            const SizedBox(height: 32),
            _buildTechnicalSection(context),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Widget _buildDevSection(BuildContext context) {
    final grit = Theme.of(context).grit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "DEVELOPER",
            style: GritTextStyles.labelMicro().copyWith(color: grit.accent, letterSpacing: 4),
          ),
          const SizedBox(height: 12),
          Text(
            "SUJAN A JAIN",
            style: GritTextStyles.metric(32, weight: FontWeight.w900, color: grit.textPrimary),
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: grit.surface,
              border: Border.all(color: grit.border, width: 1),
            ),
            child: Text(
              "Most workout apps want you to engage with them. GRIT just wants you to lift.\n\n"
              "Log your sets and reps, track your personal records, monitor your bodyweight over time, and see exactly what you've done this week. Open the app, log your workout, close it. That's the whole idea.\n\n"
              "No account required. No data leaves your phone. No streaks, no badges, no daily reminders. Just a clean log of everything you've lifted.",
              style: GritTextStyles.label(14, color: grit.textSecondary, height: 1.6),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 32),
          InkWell(
            onTap: () async {
              final url = Uri.parse('https://github.com/sponsors/7saj');
              if (await canLaunchUrl(url)) {
                GritHaptics.mediumImpact();
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: grit.accent,
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.githubLogo(PhosphorIconsStyle.fill), color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    "SUPPORT ONGOING DEVELOPMENT",
                    style: GritTextStyles.metric(13, weight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GritSectionHeader(label: "APP INFO"),
        _buildInfoRow(context, "VERSION", "1.0.0"),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final grit = Theme.of(context).grit;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: grit.border, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GritTextStyles.labelMicro().copyWith(color: grit.muted)),
          Text(value, style: GritTextStyles.mono(11, weight: FontWeight.w700, color: grit.textPrimary)),
        ],
      ),
    );
  }
}

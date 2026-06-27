import 'package:flutter/material.dart';
import '../../core/theme/grit_theme.dart';
import '../../shared/widgets/ai_coach_panel.dart';

class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;

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
                Text('GRIT AI COACH', style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary)),
              ],
            ),
          ),
        ),
      ),
      body: const AiCoachPanel(),
    );
  }
}

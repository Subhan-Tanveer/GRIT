import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../providers/app_guide_provider.dart';
import 'ai_coach_panel.dart';

/// Global "talk to GRIT AI" bubble, present on every tab screen. Watches the
/// current route so the active guide flow can auto-advance when the user
/// navigates to the screen a step asked them to go to.
class AiFloatingAssistant extends ConsumerStatefulWidget {
  final String currentRoute;
  final double bottomOffset;

  const AiFloatingAssistant({super.key, required this.currentRoute, required this.bottomOffset});

  @override
  ConsumerState<AiFloatingAssistant> createState() => _AiFloatingAssistantState();
}

class _AiFloatingAssistantState extends ConsumerState<AiFloatingAssistant> {
  @override
  void didUpdateWidget(AiFloatingAssistant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _notifyRouteChange();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyRouteChange());
  }

  void _notifyRouteChange() {
    ref.read(guideProvider.notifier).onRouteChanged(widget.currentRoute);
  }

  void _openChat() {
    GritHaptics.buttonTap();
    final grit = Theme.of(context).grit;
    showModalBottomSheet(
      context: context,
      backgroundColor: grit.background,
      isScrollControlled: true,
      builder: (sheetContext) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 100),
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (sheetCtx, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(width: 36, height: 4, decoration: BoxDecoration(color: grit.border)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('GRIT AI', style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary)),
                      IconButton(
                        icon: Icon(Icons.close, color: grit.textSecondary),
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(child: AiCoachPanel(scrollController: scrollController)),
              ],
            );
          },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;

    return Positioned(
      right: 16,
      bottom: widget.bottomOffset,
      child: GestureDetector(
        onTap: _openChat,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: grit.accent,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: grit.accent.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 1)],
          ),
          child: const Icon(Icons.psychology, color: Colors.white, size: 26),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8));
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_guides.dart';
import 'dao_providers.dart';
import '../data/models/ai_message.dart';
import 'ai_coach_provider.dart';

class ActiveGuideState {
  final GuideFlow? flow;
  final int stepIndex;
  final String? lastAdvancedRoute;

  const ActiveGuideState({this.flow, this.stepIndex = 0, this.lastAdvancedRoute});

  ActiveGuideState copyWith({GuideFlow? flow, int? stepIndex, String? lastAdvancedRoute, bool clearFlow = false}) {
    return ActiveGuideState(
      flow: clearFlow ? null : (flow ?? this.flow),
      stepIndex: stepIndex ?? this.stepIndex,
      lastAdvancedRoute: lastAdvancedRoute ?? this.lastAdvancedRoute,
    );
  }
}

class GuideNotifier extends Notifier<ActiveGuideState> {
  @override
  ActiveGuideState build() => const ActiveGuideState();

  /// Starts a guide flow and sends its first instruction as a coach message.
  /// Returns true if a matching guide was found and started.
  Future<bool> tryStart(String userMessage) async {
    final flow = appGuides.firstWhere(
      (g) => g.matches(userMessage),
      orElse: () => const GuideFlow(id: '', triggerKeywords: [], steps: []),
    );
    if (flow.id.isEmpty) return false;

    state = ActiveGuideState(flow: flow, stepIndex: 0);
    await _sendStepMessage(flow.steps.first);

    if (flow.steps.first.targetRoute == null) {
      state = state.copyWith(clearFlow: true);
    }
    return true;
  }

  Future<void> onRouteChanged(String route) async {
    final flow = state.flow;
    if (flow == null) return;
    if (route == state.lastAdvancedRoute) return;

    final currentStep = flow.steps[state.stepIndex];
    if (currentStep.targetRoute != route) return;

    final nextIndex = state.stepIndex + 1;
    if (nextIndex >= flow.steps.length) {
      state = state.copyWith(lastAdvancedRoute: route, clearFlow: true);
      return;
    }

    final nextStep = flow.steps[nextIndex];
    state = state.copyWith(stepIndex: nextIndex, lastAdvancedRoute: route);
    await _sendStepMessage(nextStep);

    if (nextStep.targetRoute == null) {
      state = state.copyWith(clearFlow: true);
    }
  }

  Future<void> _sendStepMessage(GuideStep step) async {
    final dao = ref.read(aiCoachDaoProvider);
    await dao.insert(AiMessage(role: AiRole.coach, content: step.instruction, createdAt: ''));
    ref.invalidate(aiMessagesProvider);
  }
}

final guideProvider = NotifierProvider<GuideNotifier, ActiveGuideState>(GuideNotifier.new);

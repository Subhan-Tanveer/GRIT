import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dao_providers.dart';
import 'profile_provider.dart';
import '../data/models/ai_message.dart';
import '../utils/ai_coach_engine.dart';
import '../utils/gamification.dart';
import '../utils/nutrition.dart';
import '../utils/app_guides.dart';
import 'app_guide_provider.dart';
import '../services/nvidia_service.dart';
import '../config/ai_config.dart';

final aiMessagesProvider = FutureProvider.autoDispose<List<AiMessage>>((ref) async {
  final dao = ref.watch(aiCoachDaoProvider);
  return dao.getAll();
});

final _isTypingProvider = StateProvider<bool>((ref) => false);
final isCoachTypingProvider = Provider<bool>((ref) => ref.watch(_isTypingProvider));

class AiCoachActions {
  final Ref ref;
  AiCoachActions(this.ref);

  Future<CoachContext> _buildContext() async {
    final sessionsDao = ref.read(sessionsDaoProvider);
    final wellnessDao = ref.read(wellnessDaoProvider);
    final nutritionDao = ref.read(nutritionDaoProvider);
    final profile = ref.read(profileProvider);

    final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final rollingStats = await sessionsDao.getRollingStats(weekAgo);
    final dailyVolumes = await sessionsDao.getDailyVolumesForPeriod(weekAgo);
    final recentMaxWeights = await sessionsDao.getRecentMaxWeightsByExercise();

    final trainedDays = await sessionsDao.getAllTrainedDays();
    final currentStreak = GritGamification.currentStreak(trainedDays);

    final wellnessHistory = await wellnessDao.getRecent(7);
    final latestReadiness = wellnessHistory.isNotEmpty ? wellnessHistory.last.readinessScore : null;

    final today = DateTime.now().toIso8601String().split('T')[0];
    final totals = await nutritionDao.getTotalsForDate(today);
    final targets = MacroTargets.forBodyweight(profile.weightKg);

    final sortedDates = dailyVolumes.keys.toList()..sort();
    final volumeList = sortedDates.map((d) => dailyVolumes[d]!).toList();

    return CoachContext(
      sessionsLast7Days: rollingStats['count'] as int? ?? 0,
      dailyVolumesLast7Days: volumeList,
      recentMaxWeightsByExercise: recentMaxWeights,
      latestReadinessScore: latestReadiness,
      currentStreak: currentStreak,
      todayCalories: totals['calories'] ?? 0,
      targetCalories: targets.calories,
      todayProtein: totals['protein'] ?? 0,
      targetProtein: targets.proteinG,
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final dao = ref.read(aiCoachDaoProvider);

    await dao.insert(AiMessage(role: AiRole.user, content: text.trim(), createdAt: ''));
    ref.invalidate(aiMessagesProvider);

    ref.read(_isTypingProvider.notifier).state = true;
    await Future.delayed(const Duration(milliseconds: 500));

    final startedGuide = await ref.read(guideProvider.notifier).tryStart(text);
    if (startedGuide) {
      ref.read(_isTypingProvider.notifier).state = false;
      return;
    }

    final apiKey = AiConfig.nvidiaApiKey;
    String? response = apiKey.isNotEmpty ? await _tryLlmResponse(apiKey) : null;

    response ??= knowledgeAnswer(text) ??
        navigationFallback(text) ??
        AiCoachEngine.respond(text, await _buildContext());

    await dao.insert(AiMessage(role: AiRole.coach, content: response, createdAt: ''));
    ref.read(_isTypingProvider.notifier).state = false;
    ref.invalidate(aiMessagesProvider);
  }

  /// Attempts a real LLM response grounded in the user's actual logged data.
  /// Returns null on any failure (no network, bad key, timeout) so the
  /// caller falls back to the fully offline rule-based engine.
  Future<String?> _tryLlmResponse(String apiKey) async {
    try {
      final ctx = await _buildContext();
      final dao = ref.read(aiCoachDaoProvider);
      final allMessages = await dao.getAll();
      final recentHistory = allMessages.length > 12
          ? allMessages.sublist(allMessages.length - 12)
          : allMessages;

      final systemPrompt = '''
You are GRIT AI, the in-app coach for GRIT, an offline gym/fitness tracking app. Be direct, concise (2-4 sentences unless asked for detail), and practical — like a knowledgeable training partner, not a corporate chatbot. Never invent data you weren't given.

The user's real current stats:
- Workouts in last 7 days: ${ctx.sessionsLast7Days}
- Current streak: ${ctx.currentStreak} days
- Latest wellness readiness score: ${ctx.latestReadinessScore ?? "not logged yet"}
- Today's nutrition: ${ctx.todayCalories.round()} / ${ctx.targetCalories.round()} kcal, ${ctx.todayProtein.round()} / ${ctx.targetProtein.round()}g protein
- Exercises possibly plateaued (same weight 3+ sessions): ${ctx.plateauedExercises.isEmpty ? "none detected" : ctx.plateauedExercises.join(', ')}

The app has these sections the user can navigate to: Dashboard, Workout (routines + active session logging), Analysis (muscle/exercise stats), Profile (settings, body measurements, Wellness Hub, Nutrition, GRIT Rank/achievements, this AI Coach). If the user asks how to do something specific in the app, tell them which section to tap, briefly.
''';

      // recentHistory already includes the just-inserted latest user message.
      final history = recentHistory
          .map((m) => {
                'role': m.role == AiRole.user ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList();

      return await NvidiaService.sendChat(
        apiKey: apiKey,
        systemPrompt: systemPrompt,
        history: history,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> askQuickQuestion(QuickQuestion q) async {
    await sendMessage(q.label);
  }

  Future<void> clear() async {
    final dao = ref.read(aiCoachDaoProvider);
    await dao.clear();
    ref.invalidate(aiMessagesProvider);
  }
}

final aiCoachActionsProvider = Provider((ref) => AiCoachActions(ref));

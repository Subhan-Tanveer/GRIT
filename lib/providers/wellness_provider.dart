import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dao_providers.dart';
import '../data/models/wellness_log.dart';
import '../utils/wellness.dart';

String _todayIso() => DateTime.now().toIso8601String().split('T')[0];

class WellnessSummary {
  final WellnessLog? today;
  final List<WellnessLog> history;

  const WellnessSummary({required this.today, required this.history});
}

final wellnessSummaryProvider = FutureProvider.autoDispose<WellnessSummary>((ref) async {
  final wellnessDao = ref.watch(wellnessDaoProvider);
  final today = await wellnessDao.getForDate(_todayIso());
  final history = await wellnessDao.getRecent(30);
  return WellnessSummary(today: today, history: history);
});

class WellnessNotifier extends Notifier<WellnessLog> {
  @override
  WellnessLog build() {
    return WellnessLog(
      date: _todayIso(),
      mood: 3,
      sleepHours: 7.0,
      sleepQuality: 3,
      stressLevel: 5,
      readinessScore: 0,
    );
  }

  void setMood(int mood) => state = state.copyWith(mood: mood);
  void setSleepHours(double hours) => state = state.copyWith(sleepHours: hours);
  void setSleepQuality(int quality) => state = state.copyWith(sleepQuality: quality);
  void setStressLevel(int level) => state = state.copyWith(stressLevel: level);
  void setNotes(String notes) => state = state.copyWith(notes: notes);

  Future<int> save() async {
    final sessionsDao = ref.read(sessionsDaoProvider);
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
    final rollingStats = await sessionsDao.getRollingStats(twoDaysAgo);
    final recentSessions = rollingStats['count'] as int? ?? 0;

    final score = WellnessCalc.readinessScore(
      sleepHours: state.sleepHours,
      sleepQuality: state.sleepQuality,
      mood: state.mood,
      stressLevel: state.stressLevel,
      recentSessionsLast2Days: recentSessions,
    );

    final toSave = state.copyWith(readinessScore: score);
    final wellnessDao = ref.read(wellnessDaoProvider);
    await wellnessDao.upsert(toSave);
    state = toSave;

    ref.invalidate(wellnessSummaryProvider);
    return score;
  }

  void loadFrom(WellnessLog log) {
    state = log;
  }
}

final wellnessNotifierProvider = NotifierProvider<WellnessNotifier, WellnessLog>(
  WellnessNotifier.new,
);

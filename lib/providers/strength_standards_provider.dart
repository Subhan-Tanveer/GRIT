import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_preferences_provider.dart';
import 'dao_providers.dart';
import 'profile_provider.dart';
import '../utils/strength_standards.dart';

const _isMalePrefKey = 'grit_strength_standards_is_male';

class IsMaleNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_isMalePrefKey) ?? true;
  }

  Future<void> set(bool isMale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_isMalePrefKey, isMale);
    state = isMale;
  }
}

final isMaleProvider = NotifierProvider<IsMaleNotifier, bool>(IsMaleNotifier.new);

class LiftStandard {
  final StandardLift lift;
  final double bestE1rmKg;
  final StrengthLevel level;
  final double progressToNext;

  const LiftStandard({
    required this.lift,
    required this.bestE1rmKg,
    required this.level,
    required this.progressToNext,
  });
}

final strengthStandardsProvider = FutureProvider.autoDispose<List<LiftStandard>>((ref) async {
  final sessionsDao = ref.watch(sessionsDaoProvider);
  final profile = ref.watch(profileProvider);
  final isMale = ref.watch(isMaleProvider);
  final bodyweight = profile.weightKg;

  final results = <LiftStandard>[];
  for (final lift in StandardLift.values) {
    final best = await sessionsDao.getBestE1rmForExerciseName(lift.namePattern);
    results.add(LiftStandard(
      lift: lift,
      bestE1rmKg: best,
      level: StrengthStandards.levelFor(best, bodyweight, lift, isMale),
      progressToNext: StrengthStandards.progressToNextLevel(best, bodyweight, lift, isMale),
    ));
  }
  return results;
});

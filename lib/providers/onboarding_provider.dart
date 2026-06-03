import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_preferences_provider.dart';

class OnboardingState {
  final bool hasSeenTour;

  OnboardingState({required this.hasSeenTour});

  OnboardingState copyWith({bool? hasSeenTour}) {
    return OnboardingState(
      hasSeenTour: hasSeenTour ?? this.hasSeenTour,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  static const String _tourSeenKey = 'grit_tour_seen_v1';
  final SharedPreferences _prefs;

  OnboardingNotifier(this._prefs)
      : super(OnboardingState(
          hasSeenTour: _prefs.getBool(_tourSeenKey) ?? false,
        ));

  Future<void> markTourAsSeen() async {
    await _prefs.setBool(_tourSeenKey, true);
    state = state.copyWith(hasSeenTour: true);
  }

  Future<void> resetTour() async {
    await _prefs.setBool(_tourSeenKey, false);
    state = state.copyWith(hasSeenTour: false);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingNotifier(prefs);
});

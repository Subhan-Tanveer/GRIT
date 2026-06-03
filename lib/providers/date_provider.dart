import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedDateNotifier extends Notifier<DateTime> {
  Timer? _midnightTimer;

  @override
  DateTime build() {
    ref.onDispose(() => _midnightTimer?.cancel());
    _scheduleMidnightRefresh();
    return DateTime.now();
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    
    _midnightTimer = Timer(diff + const Duration(seconds: 1), () {
      refreshIfToday();
      _scheduleMidnightRefresh(); // Reschedule for next day
    });
  }

  void setDate(DateTime date) => state = date;

  /// Resets the date to [DateTime.now()] if the current state is already set to the 
  /// previous 'Today'. This fixes the 'Frozen Today' bug when the app stays open across midnight.
  void refreshIfToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentState = DateTime(state.year, state.month, state.day);
    
    // Only auto-advance if the user hasn't manually selected a different historical date
    if (currentState.isBefore(today)) {
      state = now;
      debugPrint('GRIT: Dashboard auto-advanced to new day: $today');
    }
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(SelectedDateNotifier.new);

/// A provider that always points to the current calendar day and refreshes at midnight.
final todayProvider = Provider<DateTime>((ref) {
  // We watch the selectedDateProvider because it already has midnight logic
  ref.watch(selectedDateProvider);
  return DateTime.now();
});

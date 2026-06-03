import 'package:flutter_test/flutter_test.dart';
import 'package:grit/core/utils/workout_utils.dart';

void main() {
  group('WorkoutUtils.calculateStreaks', () {
    test('returns 0 for empty list', () {
      final streak = WorkoutUtils.calculateStreaks([], []);
      expect(streak.current, 0);
      expect(streak.best, 0);
    });

    test('calculates streak including today', () {
      final now = DateTime.now().toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      final streak =
          WorkoutUtils.calculateStreaks([today, yesterday, twoDaysAgo], []);
      expect(streak.current, 3);
      expect(streak.best, 3);
    });

    test('calculates streak including yesterday (today missed)', () {
      final now = DateTime.now().toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      final streak = WorkoutUtils.calculateStreaks([yesterday, twoDaysAgo], []);
      expect(streak.current, 2);
      expect(streak.best, 2);
    });

    test('detects broken current streak', () {
      final now = DateTime.now().toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      final threeDaysAgo = today.subtract(const Duration(days: 3));

      final streak = WorkoutUtils.calculateStreaks([twoDaysAgo, threeDaysAgo], []);
      expect(streak.current, 2); // Now it's NOT broken (2-day grace period)
      expect(streak.best, 2);
    });

    test('detects strictly broken current streak (> 2 days)', () {
      final now = DateTime.now().toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);
      final threeDaysAgo = today.subtract(const Duration(days: 3));
      final fourDaysAgo = today.subtract(const Duration(days: 4));

      final streak = WorkoutUtils.calculateStreaks([threeDaysAgo, fourDaysAgo], []);
      expect(streak.current, 0);
      expect(streak.best, 2);
    });

    test('handles multiple streaks and identifies best', () {
      final now = DateTime.now().toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);

      // Streak 1: 3 days (10 days ago)
      // Streak 2: 5 days (Current)
      final days = [
        today,
        today.subtract(const Duration(days: 1)),
        today.subtract(const Duration(days: 2)),
        today.subtract(const Duration(days: 3)),
        today.subtract(const Duration(days: 4)),
        today.subtract(const Duration(days: 10)),
        today.subtract(const Duration(days: 11)),
        today.subtract(const Duration(days: 12)),
      ];

      final streak = WorkoutUtils.calculateStreaks(days, []);
      expect(streak.current, 5);
      expect(streak.best, 5);
    });

    test('handles disordered input', () {
      final now = DateTime.now().toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);
      final days = [
        today.subtract(const Duration(days: 1)),
        today,
        today.subtract(const Duration(days: 2)),
      ];

      final streak = WorkoutUtils.calculateStreaks(days, []);
      expect(streak.current, 3);
      expect(streak.best, 3);
    });
  });


  group('WorkoutUtils.calculateE1RM', () {
    test('returns 0 for 0 reps', () {
      expect(WorkoutUtils.calculateE1RM(100, 0), 0.0);
    });

    test('returns weight for 1 rep', () {
      expect(WorkoutUtils.calculateE1RM(100, 1), 100.0);
    });

    test('calculates correct 10-rep max using Brzycki', () {
      // 100 * (36 / (37 - 10)) = 100 * (36 / 27) = 133.333...
      expect(WorkoutUtils.calculateE1RM(100, 10), closeTo(133.33, 0.01));
    });

    test('caps at 36 reps to avoid errors', () {
      // 100 * (36 / (37 - 36)) = 3600
      expect(WorkoutUtils.calculateE1RM(100, 36), 3600.0);
      expect(WorkoutUtils.calculateE1RM(100, 40), 3600.0); // Clamped
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grit/features/analysis/exercise_analysis_screen.dart';
import 'package:grit/providers/metrics_provider.dart';
import 'package:grit/providers/routine_provider.dart';
import 'package:grit/core/theme/grit_theme.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  testWidgets('ExerciseAnalysisScreen shows correct 1RM, delta and milestones', (WidgetTester tester) async {
    // Mock data for progression
    final mockPoints = [
      {
        'max_e1rm': 100.0,
        'session_volume': 1000.0,
        'max_weight': 90.0,
        'date': '2026-05-10T12:00:00Z',
      },
      {
        'max_e1rm': 105.0,
        'session_volume': 1100.0,
        'max_weight': 95.0,
        'date': '2026-05-11T12:00:00Z',
      },
      {
        'max_e1rm': 110.0,
        'session_volume': 1200.0,
        'max_weight': 100.0,
        'date': '2026-05-12T12:00:00Z',
      },
    ];

    // Mock details
    final mockDetails = {
      'name': 'Bench Press',
    };

    // Mock history
    final mockHistory = <Map<String, dynamic>>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseDetailStatsProvider(1).overrideWith((ref) => mockDetails),
          exerciseProgressionProvider(1).overrideWith((ref) => mockPoints),
          exerciseSessionHistoryProvider(1).overrideWith((ref) => mockHistory),
          exerciseAnalysisMetricProvider(1).overrideWith((ref) => ExerciseAnalysisMetric.e1rm),
        ],
        child: MaterialApp(
          theme: GritTheme.obsidian(),
          home: const ExerciseAnalysisScreen(exerciseId: 1),
        ),
      ),
    );

    // Pump to complete animations and loading states
    await tester.pumpAndSettle();

    // Verify Exercise Name is shown in AppBar
    expect(find.text('BENCH PRESS'), findsOneWidget);

    // Verify latest 1RM is 110.0
    expect(find.text('110.0'), findsOneWidget);

    // Verify delta (+5.0 KG) is shown
    expect(find.text('+5.0 KG'), findsOneWidget);

    // Verify delta percentage (+4.8% VS. PREVIOUS)
    // prev1rm was 105.0. Delta = 110.0 - 105.0 = 5.0. Percent = 5 / 105 * 100 = 4.76% ~ 4.8%
    expect(find.text('+4.8% VS. PREV'), findsOneWidget);

    // Verify New All-Time PR! is displayed (since 110.0 is greater than 105.0 and 100.0)
    expect(find.text('NEW ALL-TIME PR!'), findsOneWidget);

    // Verify Streak indicator (streak of 2: 100 -> 105 -> 110. Both sessions improved)
    expect(find.text('2-SESSION IMPROVEMENT STREAK!'), findsOneWidget);

    // Verify Sparkline is present by looking for LineChart
    expect(find.byType(LineChart), findsOneWidget);
  });
}

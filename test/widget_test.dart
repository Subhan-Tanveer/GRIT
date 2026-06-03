import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grit/main.dart';
import 'package:grit/providers/shared_preferences_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'grit_profile_onboarded': true,
      'grit_profile_displayName': 'TEST USER',
      'grit_profile_weightKg': 80.0,
      'grit_profile_heightCm': 180.0,
    });
  });

  testWidgets('App smoke test - bootstraps and renders dashboard', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const GritApp(),
      ),
    );

    // Initial pump to trigger router redirection
    await tester.pump();

    // Pump and settle to complete navigation and fade transitions
    await tester.pumpAndSettle();

    // Verify bottom nav items or tabs
    expect(find.text('DASHBOARD'), findsWidgets);
  });
}

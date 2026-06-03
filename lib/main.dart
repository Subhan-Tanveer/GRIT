// Copyright (C) 2026 GRIT Authors
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/shared_preferences_provider.dart';
import 'providers/workout_timer_provider.dart';
import 'providers/date_provider.dart';
import 'providers/workout_provider.dart';
import 'app/router.dart';
import 'core/theme/grit_theme.dart';
import 'core/utils/grit_scroll_behavior.dart';

import 'services/notification_service.dart';
import 'app/routes.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('GRIT: Flutter Binding Initialized');

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('GRIT FRAMEWORK ERROR: ${details.exceptionAsString()}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('GRIT ASYNC ERROR: $error');
      debugPrint('GRIT ASYNC STACK: $stack');
      return true;
    };

    // 1. Initialize Essential Services
    final prefs = await SharedPreferences.getInstance();
    debugPrint('GRIT: SharedPreferences Initialized');

    // 2. Initialize Non-Essential Services (with safety guards)
    // We don't await this directly if it might hang,
    // but NotificationService.init() now has its own internal try-catch.
    await NotificationService().init();
    debugPrint('GRIT: NotificationService Initialized');

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const GritApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('GRIT CRITICAL ERROR during startup: $e');
    debugPrint('GRIT Stacktrace: $stack');

    // Attempt to run the app anyway, perhaps with a fallback if prefs failed
    // but usually if this fails, we want to at least try showing SOMETHING.
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('GRIT: FAILED TO INITIALIZE APPLICATION'),
          ),
        ),
      ),
    );
  }
}

class GritApp extends ConsumerStatefulWidget {
  const GritApp({super.key});

  @override
  ConsumerState<GritApp> createState() => _GritAppState();
}

class _GritAppState extends ConsumerState<GritApp> with WidgetsBindingObserver {
  StreamSubscription<String>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    _notificationSubscription?.cancel();
    _notificationSubscription =
        NotificationService().actionStream.listen((path) {
      if (!mounted) return;

      try {
        final router = ref.read(routerProvider);

        // ANTI-BLANK-PAGE GUARD: If navigating to active workout but none exists, route to library
        if (path == GritRoutes.activeWorkout) {
          final hasActive = ref.read(activeWorkoutProvider).hasActiveSession;
          if (!hasActive) {
            debugPrint(
                'GRIT: Notification click for active workout, but none found. Routing to library.');
            router.go(GritRoutes.workout);
            return;
          }
        }

        if (path.startsWith('/')) {
          // Use go() for notification navigation to ensure a clean stack and avoid mixed navigator issues
          router.go(path);
        }
      } catch (e) {
        debugPrint('GRIT: Error processing notification route: $e');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Always let the timer provider know so it can manage notification visibility
    ref.read(workoutTimerProvider.notifier).handleLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // 1. Re-sync timers from wall-clock anchors after OS may have paused Dart timers
      ref.read(workoutTimerProvider.notifier).recoverFromBackground();

      // 2. Fix 'Frozen Today' bug: Auto-advance dashboard date if day has changed
      ref.read(selectedDateProvider.notifier).refreshIfToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GRIT',
      debugShowCheckedModeBanner: false,
      theme: GritTheme.obsidian(),
      darkTheme: GritTheme.obsidian(),
      themeMode: ThemeMode.dark,
      routerConfig: router,
      scrollBehavior: const GritScrollBehavior(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: HapticScrollWrapper(child: child!),
      ),
    );
  }
}

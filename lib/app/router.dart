import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../core/utils/haptics.dart';
import '../features/workout/routine_list_screen.dart';
import '../features/workout/routine_editor_screen.dart';
import '../features/workout/session_detail_screen.dart';
import '../features/workout/active_workout_screen.dart';
import '../features/workout/workout_summary_screen.dart';
import '../data/models/exercise.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/system_info_screen.dart';
import '../features/profile/weight_history_screen.dart';
import '../features/profile/measurement_trends_screen.dart';
import '../providers/profile_provider.dart';
import '../features/analysis/muscle_group_list_screen.dart';
import '../features/analysis/muscle_exercise_list_screen.dart';
import '../features/analysis/exercise_analysis_screen.dart';
import '../core/theme/grit_theme.dart';
import '../features/profile/measurements_log_screen.dart';
import '../features/workout/components/active_workout_mini_panel.dart';
import '../providers/workout_provider.dart';
import '../features/timer/timer_screen.dart';
import '../core/theme/grit_animations.dart';
import '../core/utils/tour_keys.dart';
import '../features/exercises/exercise_library_screen.dart';
import '../features/profile/gamification/gamification_screen.dart';
import '../features/wellness/wellness_screen.dart';
import '../features/nutrition/nutrition_screen.dart';
import '../features/ai_coach/ai_coach_screen.dart';
import '../features/social/community_screen.dart';
import '../features/social/friends_screen.dart';
import '../features/social/social_login_screen.dart';
import '../features/social/leaderboard_screen.dart';
import '../features/social/challenges_screen.dart';
import '../features/progress/progress_photos_screen.dart';
import '../features/progress/strength_standards_screen.dart';
import '../features/nutrition/meal_plan_screen.dart';
import '../providers/social_provider.dart';
import '../shared/widgets/ai_floating_assistant.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'routes.dart';

final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');
});

final routerProvider = Provider<GoRouter>((ref) {
  final navigatorKey = ref.watch(rootNavigatorKeyProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: GritRoutes.dashboard,
    redirect: (context, state) {
      final onboarded = ref.read(profileProvider).onboarded;
      final isLoggedIn = ref.read(socialAuthProvider).isLoggedIn;
      final onOnboarding = state.uri.path == GritRoutes.onboarding;
      final onSocialLogin = state.uri.path == GritRoutes.socialLogin;

      // Evaluate both gates every pass, in priority order, so completing one
      // step (e.g. onboarding) always lands on the next required step (e.g.
      // login) instead of skipping straight to the dashboard.
      if (!onboarded) {
        return onOnboarding ? null : GritRoutes.onboarding;
      }
      if (!isLoggedIn) {
        return onSocialLogin ? null : GritRoutes.socialLogin;
      }
      if (onOnboarding || onSocialLogin) {
        return GritRoutes.dashboard;
      }

      return null;
    },
    refreshListenable: _RouterRefreshListenable(ref),
    routes: [
      ShellRoute(
        builder: (context, state, child) => _GlobalOverlayWrapper(child: child),
        routes: [
          GoRoute(
            path: GritRoutes.onboarding,
            pageBuilder: (ctx, state) => NoTransitionPage<void>(
              key: state.pageKey,
              child: const OnboardingScreen(),
            ),
          ),
          StatefulShellRoute.indexedStack(
            builder: (ctx, state, navigationShell) =>
                _MainShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: GritRoutes.dashboard,
                    pageBuilder: (ctx, state) => _fadePage(
                        key: state.pageKey, child: const DashboardScreen()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: GritRoutes.workout,
                    pageBuilder: (ctx, state) => _fadePage(
                        key: state.pageKey, child: const RoutineListScreen()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: GritRoutes.analysis,
                    pageBuilder: (ctx, state) => _fadePage(
                        key: state.pageKey,
                        child: const MuscleGroupListScreen()),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: GritRoutes.profile,
                    pageBuilder: (ctx, state) => _fadePage(
                        key: state.pageKey, child: const ProfileScreen()),
                  ),
                ],
              ),
            ],
          ),
          // Detail routes as children of the ShellRoute but using root navigator
          GoRoute(
            path:
                '/session/:id', // Using parameter syntax directly for router definition
            pageBuilder: (ctx, state) {
              final idStr = state.pathParameters['id'];
              final id = int.tryParse(idStr ?? '');
              if (id == null) {
                return _slidePage(
                    key: state.pageKey, child: const DashboardScreen());
              }
              return _slidePage(
                  key: state.pageKey,
                  child: SessionDetailScreen(sessionId: id));
            },
          ),
          GoRoute(
            path: '/routine/edit/:id',
            pageBuilder: (ctx, state) {
              final idStr = state.pathParameters['id'];
              if (idStr == 'new') {
                final initialExercises = state.extra as List<Exercise>?;
                return _slidePage(
                  key: state.pageKey,
                  child: RoutineEditorScreen(
                    routineId: null,
                    initialExercises: initialExercises,
                  ),
                );
              }
              final id = int.tryParse(idStr ?? '');
              if (id == null) {
                return _slidePage(
                    key: state.pageKey, child: const RoutineListScreen());
              }
              return _slidePage(
                  key: state.pageKey,
                  child: RoutineEditorScreen(routineId: id));
            },
          ),
          GoRoute(
            path: GritRoutes.profileEdit,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const EditProfileScreen()),
          ),
          GoRoute(
            path: GritRoutes.weightHistory,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const WeightHistoryScreen()),
          ),
          GoRoute(
            path: GritRoutes.measurements,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const MeasurementTrendsScreen()),
          ),
          GoRoute(
            path: GritRoutes.about,
            pageBuilder: (ctx, state) =>
                _slidePage(key: state.pageKey, child: const AboutScreen()),
          ),
          GoRoute(
            path: GritRoutes.gamification,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const GamificationScreen()),
          ),
          GoRoute(
            path: GritRoutes.wellness,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const WellnessScreen()),
          ),
          GoRoute(
            path: GritRoutes.nutrition,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const NutritionScreen()),
          ),
          GoRoute(
            path: GritRoutes.aiCoach,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const AiCoachScreen()),
          ),
          GoRoute(
            path: GritRoutes.community,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const CommunityScreen()),
          ),
          GoRoute(
            path: GritRoutes.friends,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const FriendsScreen()),
          ),
          GoRoute(
            path: GritRoutes.socialLogin,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const SocialLoginScreen()),
          ),
          GoRoute(
            path: GritRoutes.leaderboard,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const LeaderboardScreen()),
          ),
          GoRoute(
            path: GritRoutes.challenges,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const ChallengesScreen()),
          ),
          GoRoute(
            path: GritRoutes.progressPhotos,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const ProgressPhotosScreen()),
          ),
          GoRoute(
            path: GritRoutes.strengthStandards,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const StrengthStandardsScreen()),
          ),
          GoRoute(
            path: GritRoutes.mealPlan,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const MealPlanScreen()),
          ),
          GoRoute(
            path: GritRoutes.measurementsLog,
            pageBuilder: (ctx, state) => _slidePage(
              key: state.pageKey,
              child: const MeasurementsLogScreen(),
            ),
          ),
          GoRoute(
            path: GritRoutes.activeWorkout,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const ActiveWorkoutScreen()),
          ),
          GoRoute(
            path: GritRoutes.workoutTimer,
            pageBuilder: (ctx, state) => _slidePage(
                key: state.pageKey, child: const StandardTimerScreen()),
          ),
          GoRoute(
            path: '/workout/summary/:id',
            pageBuilder: (ctx, state) {
              final idStr = state.pathParameters['id'];
              final id = int.tryParse(idStr ?? '');
              if (id == null) {
                return _slidePage(
                    key: state.pageKey, child: const RoutineListScreen());
              }
              return _slidePage(
                  key: state.pageKey,
                  child: WorkoutSummaryScreen(sessionId: id));
            },
          ),
          GoRoute(
            path: GritRoutes.exerciseLibrary,
            pageBuilder: (ctx, state) => _slidePage(
              key: state.pageKey,
              child: const ExerciseLibraryScreen(selectMode: false),
            ),
          ),
          GoRoute(
            path: GritRoutes.exerciseLibrarySelect,
            pageBuilder: (ctx, state) => _slidePage(
              key: state.pageKey,
              child: const ExerciseLibraryScreen(
                  selectMode: true, multipleSelection: true),
            ),
          ),
          GoRoute(
            path: GritRoutes.exerciseLibrarySwap,
            pageBuilder: (ctx, state) => _slidePage(
              key: state.pageKey,
              child: const ExerciseLibraryScreen(
                  selectMode: true, multipleSelection: false),
            ),
          ),
          GoRoute(
            name: 'muscle_analysis',
            path: '/analysis/muscle/:group',
            pageBuilder: (ctx, state) {
              final group = state.pathParameters['group']!;
              return _slidePage(
                  key: state.pageKey,
                  child: MuscleExerciseListScreen(muscle: group));
            },
          ),
          GoRoute(
            name: 'exercise_analysis',
            path: '/analysis/exercise/:id',
            pageBuilder: (ctx, state) {
              final idStr = state.pathParameters['id'];
              final id = int.tryParse(idStr ?? '');
              if (id == null) {
                return _slidePage(
                    key: state.pageKey, child: const MuscleGroupListScreen());
              }
              return _slidePage(
                  key: state.pageKey,
                  child: ExerciseAnalysisScreen(exerciseId: id));
            },
          ),
        ],
      ),
    ],
  );
});

class _GlobalOverlayWrapper extends ConsumerWidget {
  final Widget child;
  const _GlobalOverlayWrapper({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActiveSession =
        ref.watch(activeWorkoutProvider.select((s) => s.hasActiveSession));
    final location = GoRouterState.of(context).uri.path;

    // Determine if we are on a tab route to avoid overlapping the bottom nav bar
    final isTabRoute = GritRoutes.isTabRoute(location);

    // Hide Overlay if on the active workout screen itself (redundant)
    final isActiveWorkoutPage = location == GritRoutes.activeWorkout;
    final showStatusPanel = hasActiveSession && !isActiveWorkoutPage && isTabRoute;

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double bottomOffset = isTabRoute
        ? GritSpacing.bottomNavHeight + bottomPadding + GritSpacing.horizontalMargin + MediaQuery.of(context).viewInsets.bottom
        : bottomPadding + GritSpacing.horizontalMargin + MediaQuery.of(context).viewInsets.bottom;

    final showAssistant = location != GritRoutes.activeWorkout && location != GritRoutes.aiCoach;
    final assistantBottomOffset = showStatusPanel ? bottomOffset + 76 : bottomOffset;

    return Stack(
      children: [
        child,
        if (showStatusPanel)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomOffset,
            child: const ActiveWorkoutStatusPanel(),
          ),
        if (showAssistant)
          AiFloatingAssistant(currentRoute: location, bottomOffset: assistantBottomOffset),
      ],
    );
  }
}

class _RouterRefreshListenable extends ChangeNotifier {
  bool _isDisposed = false;

  _RouterRefreshListenable(Ref ref) {
    _profileSubscription = ref.listen(profileProvider, (_, __) {
      if (!_isDisposed) notifyListeners();
    });
    _workoutSubscription = ref.listen(activeWorkoutProvider, (_, __) {
      if (!_isDisposed) notifyListeners();
    });
    _socialAuthSubscription = ref.listen(socialAuthProvider, (_, __) {
      if (!_isDisposed) notifyListeners();
    });
  }

  late final ProviderSubscription<dynamic> _profileSubscription;
  late final ProviderSubscription<dynamic> _workoutSubscription;
  late final ProviderSubscription<dynamic> _socialAuthSubscription;

  @override
  void dispose() {
    _isDisposed = true;
    _profileSubscription.close();
    _workoutSubscription.close();
    _socialAuthSubscription.close();
    super.dispose();
  }
}

class _MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const _MainShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isTabRoute = GritRoutes.isTabRoute(location);

    return Scaffold(
      body: KeyedSubtree(
        key: ValueKey<int>(navigationShell.currentIndex),
        child: navigationShell,
      ),
      bottomNavigationBar: (isTabRoute)
          ? _GritBottomNav(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                GritHaptics.selectionTick();
                navigationShell.goBranch(index);
              },
            )
          : null,
    );
  }
}

class _GritBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const _GritBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final grit = Theme.of(context).grit;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    
    return Container(
      height: GritSpacing.bottomNavHeight + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: grit.surface,
        border: Border(top: BorderSide(color: grit.border, width: 1)),
      ),
      child: Row(
        children: [
          _navItem(
            context,
            0,
            'DASHBOARD',
            PhosphorIcons.squaresFour(),
            PhosphorIcons.squaresFour(PhosphorIconsStyle.fill),
          ),
          _navItem(
            context,
            1,
            'WORKOUT',
            PhosphorIcons.barbell(),
            PhosphorIcons.barbell(PhosphorIconsStyle.fill),
            key: GritTourKeys.navWorkoutKey,
          ),
          _navItem(
            context,
            2,
            'ANALYSIS',
            PhosphorIcons.chartLine(),
            PhosphorIcons.chartLine(PhosphorIconsStyle.fill),
          ),
          _navItem(
            context,
            3,
            'PROFILE',
            PhosphorIcons.user(),
            PhosphorIcons.user(PhosphorIconsStyle.fill),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    int index,
    String label,
    IconData icon,
    IconData activeIcon, {
    Key? key,
  }) {
    final grit = Theme.of(context).grit;
    final isActive = currentIndex == index;
    final color = isActive ? grit.accent : grit.textSecondary.withValues(alpha: 0.4);

    return Expanded(
      child: InkWell(
        key: key,
        onTap: () => onTap(index),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isActive)
              Positioned(
                top: 0,
                child: Container(
                  width: 32,
                  height: 2,
                  color: grit.accent,
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 2), // accounts for the 2px top bar
                Icon(
                  isActive ? activeIcon : icon,
                  color: color,
                  size: 22,
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: GritTextStyles.mono(
                    9.5,
                    color: color,
                    letterSpacing: 1.2,
                    weight: isActive ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Weighted SharedAxis transition for detail routes
CustomTransitionPage<void> _slidePage(
    {required LocalKey key, required Widget child}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: GritAnimations.mechanicalDuration,
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        fillColor: Theme.of(ctx).grit.background,
        child: child,
      );
    },
  );
}

bool _firstLoad = true;

/// Seamless FadeThrough transition for tab-level routes
CustomTransitionPage<void> _fadePage(
    {required LocalKey key, required Widget child}) {
  if (_firstLoad) {
    _firstLoad = false;
    return NoTransitionPage<void>(
      key: key,
      child: child,
    );
  }
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: GritAnimations.mechanicalDuration,
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      return FadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        fillColor: Theme.of(ctx).grit.background,
        child: child,
      );
    },
  );
}

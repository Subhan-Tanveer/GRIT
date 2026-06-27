class GritRoutes {
  // Main Tabs
  static const String dashboard = '/dashboard';
  static const String workout = '/workout';
  static const String analysis = '/analysis';
  static const String profile = '/profile';
  static const String onboarding = '/onboarding';

  // Workout Flow
  static const String activeWorkout = '/workout/active';
  static const String workoutTimer = '/workout/timer';
  static String workoutSummary(int id) => '/workout/summary/$id';
  static String sessionDetail(int id) => '/session/$id';
  
  // Routine Management
  static String routineEdit(String idOrNew) => '/routine/edit/$idOrNew';
  static const String exerciseLibrary = '/workout/library';
  static const String exerciseLibrarySelect = '/workout/library/select';
  static const String exerciseLibrarySwap = '/workout/library/swap';

  // Analysis
  static String muscleAnalysis(String group) => '/analysis/muscle/$group';
  static String exerciseAnalysis(int id) => '/analysis/exercise/$id';

  // Profile Sub-screens
  static const String profileEdit = '/profile/edit';
  static const String weightHistory = '/profile/weight-history';
  static const String measurements = '/profile/measurements';
  static const String measurementsLog = '/profile/log-measurements';
  static const String about = '/profile/about';
  static const String gamification = '/profile/gamification';
  static const String wellness = '/wellness';
  static const String nutrition = '/nutrition';
  static const String aiCoach = '/ai-coach';
  static const String community = '/community';
  static const String friends = '/community/friends';
  static const String socialLogin = '/community/login';
  static const String leaderboard = '/community/leaderboard';
  static const String challenges = '/community/challenges';
  static const String progressPhotos = '/profile/progress-photos';
  static const String strengthStandards = '/profile/strength-standards';
  static const String mealPlan = '/nutrition/meal-plan';

  // Helper for Shell logic
  static bool isTabRoute(String path) {
    return path == dashboard ||
        path == workout ||
        path == analysis ||
        path == profile;
  }
}

class HeroTags {
  HeroTags._();

  static const String activeWorkoutName = 'active_workout_name';
  static const String activeWorkoutTimer = 'active_workout_timer';
  
  static String routineName(int id) => 'routine_name_$id';
  static String exerciseName(int id) => 'exercise_name_$id';
}

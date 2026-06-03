class WorkoutMuscles {
  final Set<String> primary;
  final Set<String> secondary;

  WorkoutMuscles({
    required this.primary,
    required this.secondary,
  });

  factory WorkoutMuscles.empty() => WorkoutMuscles(
    primary: {},
    secondary: {},
  );

  bool get isEmpty => primary.isEmpty && secondary.isEmpty;
}

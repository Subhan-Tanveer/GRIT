class TodayWorkoutStats {
  final double totalVolume;
  final String? dominantMuscle;
  final String? weakestMuscle;
  final Map<String, double> muscleVolumes;
  final bool isRestDay;

  TodayWorkoutStats({
    required this.totalVolume,
    this.dominantMuscle,
    this.weakestMuscle,
    required this.muscleVolumes,
    this.isRestDay = false,
  });

  factory TodayWorkoutStats.empty({bool isRestDay = false}) => TodayWorkoutStats(
        totalVolume: 0,
        muscleVolumes: {},
        isRestDay: isRestDay,
      );

  bool get isEmpty => totalVolume == 0;
  
  String get dominantLabel => isEmpty ? "---" : (dominantMuscle?.replaceAll('_', ' ') ?? "---");
  String get weakestLabel => (isEmpty || weakestMuscle == null) ? "---" : weakestMuscle!.replaceAll('_', ' ');
}

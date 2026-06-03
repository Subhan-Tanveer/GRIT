class TopLift {
  final double weightKg;
  final String exerciseName;
  final String sessionName;
  final String date;

  const TopLift({
    required this.weightKg,
    required this.exerciseName,
    required this.sessionName,
    required this.date,
  });
}

class DashboardData {
  final int sessionCount;
  final List<double> dailyVolumes; // 7 items (Mon-Sun)
  final double weeklyTotal;
  final double lastWeekTotal;
  final List<bool> trainedDays; // 7 items

  const DashboardData({
    required this.sessionCount,
    required this.dailyVolumes,
    required this.weeklyTotal,
    required this.lastWeekTotal,
    required this.trainedDays,
  });
}

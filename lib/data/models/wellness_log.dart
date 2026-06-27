class WellnessLog {
  final int? id;
  final String date; // yyyy-MM-dd
  final int mood; // 1-5
  final double sleepHours;
  final int sleepQuality; // 1-5
  final int stressLevel; // 1-10
  final String notes;
  final int readinessScore; // 0-100

  const WellnessLog({
    this.id,
    required this.date,
    required this.mood,
    required this.sleepHours,
    required this.sleepQuality,
    required this.stressLevel,
    this.notes = '',
    required this.readinessScore,
  });

  factory WellnessLog.fromMap(Map<String, dynamic> m) => WellnessLog(
        id: m['id'] as int?,
        date: m['date'] as String,
        mood: m['mood'] as int,
        sleepHours: (m['sleep_hours'] as num).toDouble(),
        sleepQuality: m['sleep_quality'] as int,
        stressLevel: m['stress_level'] as int,
        notes: m['notes'] as String? ?? '',
        readinessScore: m['readiness_score'] as int,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'mood': mood,
        'sleep_hours': sleepHours,
        'sleep_quality': sleepQuality,
        'stress_level': stressLevel,
        'notes': notes,
        'readiness_score': readinessScore,
      };

  WellnessLog copyWith({
    int? mood,
    double? sleepHours,
    int? sleepQuality,
    int? stressLevel,
    String? notes,
    int? readinessScore,
  }) {
    return WellnessLog(
      id: id,
      date: date,
      mood: mood ?? this.mood,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      stressLevel: stressLevel ?? this.stressLevel,
      notes: notes ?? this.notes,
      readinessScore: readinessScore ?? this.readinessScore,
    );
  }
}

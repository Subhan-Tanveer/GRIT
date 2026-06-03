enum SetEntryType {
  normal,
  warmup,
  dropSet,
  failure,
}

class SetEntry {
  final int? id;
  final int sessionExerciseId;
  final int setNumber;
  final double weightKg;
  final int? reps;
  final int? durationSeconds;
  final SetEntryType setType;
  final double? rpe;
  final String notes;
  final String loggedAt;
  final bool isCompleted;
  final bool isPr;

  const SetEntry({
    this.id,
    required this.sessionExerciseId,
    required this.setNumber,
    this.weightKg = 0.0,
    this.reps,
    this.durationSeconds,
    this.setType = SetEntryType.normal,
    this.rpe,
    this.notes = '',
    required this.loggedAt,
    this.isCompleted = false,
    this.isPr = false,
  });

  factory SetEntry.fromMap(Map<String, dynamic> m) {
    SetEntryType type = SetEntryType.normal;
    final typeStr = m['set_type'] as String? ?? '';
    if (typeStr == 'warmup') {
      type = SetEntryType.warmup;
    } else if (typeStr == 'dropSet') {
      type = SetEntryType.dropSet;
    } else if (typeStr == 'failure') {
      type = SetEntryType.failure;
    } else {
      // Backward compatibility for is_warmup column
      if ((m['is_warmup'] as int? ?? 0) == 1) {
        type = SetEntryType.warmup;
      }
    }

    return SetEntry(
      id: m['id'] as int?,
      sessionExerciseId: m['session_exercise_id'] as int,
      setNumber: m['set_number'] as int,
      weightKg: (m['weight_kg'] as num).toDouble(),
      reps: m['reps'] as int?,
      durationSeconds: m['duration_seconds'] as int?,
      setType: type,
      rpe: m['rpe'] != null ? (m['rpe'] as num).toDouble() : null,
      notes: m['notes'] as String? ?? '',
      loggedAt: m['logged_at'] as String,
      isCompleted: (m['is_completed'] as int) == 1,
      isPr: m['is_pr'] == 1,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'session_exercise_id': sessionExerciseId,
        'set_number': setNumber,
        'weight_kg': weightKg,
        'reps': reps,
        'duration_seconds': durationSeconds,
        'set_type': setType.name,
        'is_warmup': setType == SetEntryType.warmup ? 1 : 0,
        'rpe': rpe,
        'notes': notes,
        'logged_at': loggedAt,
        'is_completed': isCompleted ? 1 : 0,
        'is_pr': isPr ? 1 : 0,
      };

  SetEntry copyWith({
    int? id,
    int? sessionExerciseId,
    int? setNumber,
    double? weightKg,
    int? reps,
    int? durationSeconds,
    SetEntryType? setType,
    double? rpe,
    String? notes,
    String? loggedAt,
    bool? isCompleted,
    bool? isPr,
  }) =>
      SetEntry(
        id: id ?? this.id,
        sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
        setNumber: setNumber ?? this.setNumber,
        weightKg: weightKg ?? this.weightKg,
        reps: reps ?? this.reps,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        setType: setType ?? this.setType,
        rpe: rpe ?? this.rpe,
        notes: notes ?? this.notes,
        loggedAt: loggedAt ?? this.loggedAt,
        isCompleted: isCompleted ?? this.isCompleted,
        isPr: isPr ?? this.isPr,
      );
}

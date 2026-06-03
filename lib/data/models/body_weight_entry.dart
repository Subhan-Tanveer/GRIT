class BodyWeightEntry {
  final int? id;
  final double weightKg;
  final String loggedAt;
  final String notes;

  const BodyWeightEntry({
    this.id,
    required this.weightKg,
    required this.loggedAt,
    this.notes = '',
  });

  factory BodyWeightEntry.fromMap(Map<String, dynamic> m) => BodyWeightEntry(
        id: m['id'] as int?,
        weightKg: (m['weight_kg'] as num).toDouble(),
        loggedAt: m['logged_at'] as String,
        notes: m['notes'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'weight_kg': weightKg,
        'logged_at': loggedAt,
        'notes': notes,
      };
}

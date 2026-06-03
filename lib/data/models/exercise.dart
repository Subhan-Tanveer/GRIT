import '../../core/utils/muscle_mapper.dart';

class Exercise {
  final int? id;
  final String? canonicalId; // New: Unique ID from exercises.json (e.g. 'barbell_back_squat')
  final String name;
  final String muscleGroup;
  final String secondaryMuscles;
  final String equipment;
  final String type; // 'weighted' | 'bodyweight' | 'assisted_bodyweight' | 'cardio' | 'timed'
  final bool isCustom;
  final bool isHidden;
  final String instructions;
  final String createdAt;

  Exercise({
    this.id,
    this.canonicalId,
    required this.name,
    required this.muscleGroup,
    this.secondaryMuscles = '',
    required this.equipment,
    required this.type,
    this.isCustom = false,
    this.isHidden = false,
    this.instructions = '',
    required this.createdAt,
  });

  /// Parse a row that came back from SQLite.
  factory Exercise.fromMap(Map<String, dynamic> m) {
    return Exercise(
      id: m['id'] as int?,
      canonicalId: m['canonical_id'] as String?,
      name: m['name'] as String,
      muscleGroup: m['muscle_group'] as String,
      secondaryMuscles: m['secondary_muscles'] as String? ?? '',
      equipment: m['equipment'] as String,
      type: m['type'] as String,
      isCustom: (m['is_custom'] as int? ?? 0) == 1,
      isHidden: (m['is_hidden'] as int? ?? 0) == 1,
      instructions: m['instructions'] as String? ?? '',
      createdAt: m['created_at'] as String,
    );
  }

  /// Parse an item from the new curated exercises.json:
  /// { "id": "...", "name": "...", "equipment": "...", "pattern": "...",
  ///   "muscles_primary": [...], "muscles_secondary": [...] }
  factory Exercise.fromJson(Map<String, dynamic> j) {
    final primaryList = (j['muscles_primary'] as List<dynamic>? ?? []).cast<String>();
    final secondaryList = (j['muscles_secondary'] as List<dynamic>? ?? []).cast<String>();

    // Derive the canonical SVG muscle_group from the first primary muscle
    final muscleGroup = MuscleMapper.primarySvgId(primaryList);

    // Store secondary muscles as a comma-joined string of SVG IDs
    final secondaryIds = MuscleMapper.mapMuscleList(secondaryList).join(',');

    // Derive exercise type from equipment and name
    final equipmentStr = (j['equipment'] as String? ?? 'bodyweight').toLowerCase();
    final nameStr = (j['name'] as String? ?? '').toLowerCase();
    
    String type = 'weighted';
    if (equipmentStr == 'bodyweight' || equipmentStr == 'band') {
      type = 'bodyweight';
    } else if (nameStr.contains('assisted')) {
      type = 'assisted_bodyweight';
    }

    return Exercise(
      canonicalId: j['id'] as String?,
      name: j['name'] as String,
      muscleGroup: muscleGroup,
      secondaryMuscles: secondaryIds,
      equipment: _capitalize(equipmentStr),
      type: type,
      isCustom: false,
      instructions: '',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'canonical_id': canonicalId,
        'name': name,
        'muscle_group': muscleGroup,
        'secondary_muscles': secondaryMuscles,
        'equipment': equipment,
        'type': type,
        'is_custom': isCustom ? 1 : 0,
        'is_hidden': isHidden ? 1 : 0,
        'instructions': instructions,
        'created_at': createdAt,
      };

  Exercise copyWith({
    int? id,
    String? canonicalId,
    String? name,
    String? muscleGroup,
    String? secondaryMuscles,
    String? equipment,
    String? type,
    bool? isCustom,
    bool? isHidden,
    String? instructions,
    String? createdAt,
  }) =>
      Exercise(
        id: id ?? this.id,
        canonicalId: canonicalId ?? this.canonicalId,
        name: name ?? this.name,
        muscleGroup: muscleGroup ?? this.muscleGroup,
        secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
        equipment: equipment ?? this.equipment,
        type: type ?? this.type,
        isCustom: isCustom ?? this.isCustom,
        isHidden: isHidden ?? this.isHidden,
        instructions: instructions ?? this.instructions,
        createdAt: createdAt ?? this.createdAt,
      );
}


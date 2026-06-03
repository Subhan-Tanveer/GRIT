class BodyMeasurementEntry {
  final int? id;
  final String createdAt;
  final double? neck;
  final double? shoulders;
  final double? chest;
  final double? waist;
  final double? leftBicep;
  final double? rightBicep;
  final double? leftForearm;
  final double? rightForearm;
  final double? leftThigh;
  final double? rightThigh;
  final double? leftCalf;
  final double? rightCalf;

  BodyMeasurementEntry({
    this.id,
    required this.createdAt,
    this.neck,
    this.shoulders,
    this.chest,
    this.waist,
    this.leftBicep,
    this.rightBicep,
    this.leftForearm,
    this.rightForearm,
    this.leftThigh,
    this.rightThigh,
    this.leftCalf,
    this.rightCalf,
  });

  factory BodyMeasurementEntry.fromMap(Map<String, dynamic> map) {
    return BodyMeasurementEntry(
      id: map['id'] as int?,
      createdAt: map['created_at'] as String,
      neck: map['neck'] as double?,
      shoulders: map['shoulders'] as double?,
      chest: map['chest'] as double?,
      waist: map['waist'] as double?,
      leftBicep: map['left_bicep'] as double?,
      rightBicep: map['right_bicep'] as double?,
      leftForearm: map['left_forearm'] as double?,
      rightForearm: map['right_forearm'] as double?,
      leftThigh: map['left_thigh'] as double?,
      rightThigh: map['right_thigh'] as double?,
      leftCalf: map['left_calf'] as double?,
      rightCalf: map['right_calf'] as double?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'created_at': createdAt,
      'neck': neck,
      'shoulders': shoulders,
      'chest': chest,
      'waist': waist,
      'left_bicep': leftBicep,
      'right_bicep': rightBicep,
      'left_forearm': leftForearm,
      'right_forearm': rightForearm,
      'left_thigh': leftThigh,
      'right_thigh': rightThigh,
      'left_calf': leftCalf,
      'right_calf': rightCalf,
    };
  }

  BodyMeasurementEntry copyWith({
    int? id,
    String? createdAt,
    double? neck,
    double? shoulders,
    double? chest,
    double? waist,
    double? leftBicep,
    double? rightBicep,
    double? leftForearm,
    double? rightForearm,
    double? leftThigh,
    double? rightThigh,
    double? leftCalf,
    double? rightCalf,
  }) {
    return BodyMeasurementEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      neck: neck ?? this.neck,
      shoulders: shoulders ?? this.shoulders,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      leftBicep: leftBicep ?? this.leftBicep,
      rightBicep: rightBicep ?? this.rightBicep,
      leftForearm: leftForearm ?? this.leftForearm,
      rightForearm: rightForearm ?? this.rightForearm,
      leftThigh: leftThigh ?? this.leftThigh,
      rightThigh: rightThigh ?? this.rightThigh,
      leftCalf: leftCalf ?? this.leftCalf,
      rightCalf: rightCalf ?? this.rightCalf,
    );
  }

  /// Returns the value for a specific site, converted to [unit] if necessary.
  /// [unit] can be 'CM' or 'IN'. The underlying storage is always CM.
  double? getValue(String siteId, String unit) {
    final rawValue = toMap()[siteId] as double?;
    if (rawValue == null) return null;
    return unit == 'IN' ? rawValue / 2.54 : rawValue;
  }

  /// Returns the count of non-null measurement sites.
  int get activeCount {
    final values = toMap().values.where((v) => v != null && v is double);
    return values.length;
  }
}

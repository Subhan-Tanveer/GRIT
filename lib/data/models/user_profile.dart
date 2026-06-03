class UserProfile {
  final bool onboarded;
  final String weightUnit;
  final String heightUnit;
  final String theme;
  final String displayName;
  final String? photoPath;
  final String? dateOfBirth;
  final double heightCm;
  final double weightKg; // Added for volume formula support
  final int trainingSinceYear;
  final int firstDayOfWeek;

  const UserProfile({
    this.onboarded = false,
    this.weightUnit = 'KG',
    this.heightUnit = 'CM',
    this.theme = 'Obsidian',
    this.displayName = 'USER',
    this.photoPath,
    this.dateOfBirth,
    this.heightCm = 175.0,
    this.weightKg = 75.0,
    this.trainingSinceYear = 2024,
    this.firstDayOfWeek = 1, // 1 = Monday, 7 = Sunday
  });

  UserProfile copyWith({
    bool? onboarded,
    String? weightUnit,
    String? heightUnit,
    String? theme,
    String? displayName,
    String? photoPath,
    String? dateOfBirth,
    double? heightCm,
    double? weightKg,
    int? trainingSinceYear,
    int? firstDayOfWeek,
  }) {
    return UserProfile(
      onboarded: onboarded ?? this.onboarded,
      weightUnit: weightUnit ?? this.weightUnit,
      heightUnit: heightUnit ?? this.heightUnit,
      theme: theme ?? this.theme,
      displayName: displayName ?? this.displayName,
      photoPath: photoPath ?? this.photoPath,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      trainingSinceYear: trainingSinceYear ?? this.trainingSinceYear,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
    );
  }

  String get initials {
    final name = displayName.trim().toUpperCase();
    if (name.isEmpty) return 'U';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts.first[0] + parts.last[0]);
    }
    return parts.first.substring(0, parts.first.length.clamp(0, 2));
  }

  int get age {
    final dob = dateOfBirth;
    if (dob == null || dob.isEmpty) return 0;
    try {
      DateTime? birth;
      if (dob.contains('/')) {
        final parts = dob.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            birth = DateTime(year, month, day);
          }
        }
      }
      birth ??= DateTime.tryParse(dob);
      if (birth == null) return 0;

      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age.clamp(0, 120);
    } catch (_) {
      return 0;
    }
  }

  int get yearsLifting {
    return (DateTime.now().year - trainingSinceYear).clamp(0, 99);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_preferences_provider.dart';
import '../data/models/user_profile.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileNotifier extends Notifier<UserProfile> {
  void _migrateLegacyKeys(SharedPreferences prefs) {
    const legacyKeys = [
      'onboarded',
      'weightUnit',
      'heightUnit',
      'theme',
      'displayName',
      'photoPath',
      'dateOfBirth',
      'heightCm',
      'weightKg',
      'trainingSinceYear',
      'firstDayOfWeek',
    ];
    for (final key in legacyKeys) {
      if (prefs.containsKey(key)) {
        final val = prefs.get(key);
        final newKey = 'grit_profile_$key';
        if (!prefs.containsKey(newKey) && val != null) {
          if (val is bool) prefs.setBool(newKey, val);
          if (val is String) prefs.setString(newKey, val);
          if (val is double) prefs.setDouble(newKey, val);
          if (val is int) prefs.setInt(newKey, val);
        }
        prefs.remove(key);
      }
    }
  }

  @override
  UserProfile build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _migrateLegacyKeys(prefs);
    return UserProfile(
      onboarded: prefs.getBool('grit_profile_onboarded') ?? false,
      weightUnit: prefs.getString('grit_profile_weightUnit') ?? 'KG',
      heightUnit: prefs.getString('grit_profile_heightUnit') ?? 'CM',
      theme: prefs.getString('grit_profile_theme') ?? 'Obsidian',
      displayName: prefs.getString('grit_profile_displayName') ?? 'USER',
      photoPath: prefs.getString('grit_profile_photoPath'),
      dateOfBirth: prefs.getString('grit_profile_dateOfBirth'),
      heightCm: prefs.getDouble('grit_profile_heightCm') ?? 175.0,
      weightKg: prefs.getDouble('grit_profile_weightKg') ?? 75.0,
      trainingSinceYear:
          prefs.getInt('grit_profile_trainingSinceYear') ?? DateTime.now().year,
      firstDayOfWeek: prefs.getInt('grit_profile_firstDayOfWeek') ?? 1,
    );
  }

  Future<void> setTheme(String theme) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('grit_profile_theme', theme);
    state = state.copyWith(theme: theme);
  }

  Future<void> setFirstDayOfWeek(int day) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt('grit_profile_firstDayOfWeek', day);
    state = state.copyWith(firstDayOfWeek: day);
  }

  Future<void> setOnboarded() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('grit_profile_onboarded', true);
    state = state.copyWith(onboarded: true);
  }

  Future<void> setWeightUnit(String unit) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('grit_profile_weightUnit', unit);
    state = state.copyWith(weightUnit: unit);
  }

  Future<void> setHeightUnit(String unit) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('grit_profile_heightUnit', unit);
    state = state.copyWith(heightUnit: unit);
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoPath,
    String? dateOfBirth,
    double? heightCm,
    double? weightKg,
    int? trainingSinceYear,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (displayName != null) {
      await prefs.setString('grit_profile_displayName', displayName);
    }
    if (photoPath != null) {
      await prefs.setString('grit_profile_photoPath', photoPath);
    }
    if (dateOfBirth != null) {
      await prefs.setString('grit_profile_dateOfBirth', dateOfBirth);
    }
    if (heightCm != null) {
      await prefs.setDouble('grit_profile_heightCm', heightCm);
    }
    if (weightKg != null) {
      await prefs.setDouble('grit_profile_weightKg', weightKg);
    }
    if (trainingSinceYear != null) {
      await prefs.setInt('grit_profile_trainingSinceYear', trainingSinceYear);
    }

    state = state.copyWith(
      displayName: displayName,
      photoPath: photoPath,
      dateOfBirth: dateOfBirth,
      heightCm: heightCm,
      weightKg: weightKg,
      trainingSinceYear: trainingSinceYear,
    );
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

final packageInfoProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return "VERSION ${info.version} (BUILD ${info.buildNumber})";
  } catch (e) {
    return "VERSION 1.0.0 (DEBUG)";
  }
});

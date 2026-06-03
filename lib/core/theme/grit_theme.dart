import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  GRIT Design System — Tokens (Theme Extension)
// ─────────────────────────────────────────────

extension GritThemeExtension on ThemeData {
  GritThemeData get grit => extension<GritThemeData>()!;
}

class GritThemeData extends ThemeExtension<GritThemeData> {
  final Color background;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color borderHighlight;
  final Color muted;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color success;
  final Color warning;
  final Color timerAmber;
  final Color deltaPositive;
  final Color warmupSet;
  final Color dropSet;
  final Color failureSet;

  GritThemeData({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.borderHighlight,
    required this.muted,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.timerAmber,
    required this.deltaPositive,
    required this.warmupSet,
    required this.dropSet,
    required this.failureSet,
  });

  @override
  ThemeExtension<GritThemeData> copyWith({
    Color? background,
    Color? surface,
    Color? surface2,
    Color? border,
    Color? borderHighlight,
    Color? muted,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? success,
    Color? warning,
    Color? timerAmber,
    Color? deltaPositive,
    Color? warmupSet,
    Color? dropSet,
    Color? failureSet,
  }) {
    return GritThemeData(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      border: border ?? this.border,
      borderHighlight: borderHighlight ?? this.borderHighlight,
      muted: muted ?? this.muted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      timerAmber: timerAmber ?? this.timerAmber,
      deltaPositive: deltaPositive ?? this.deltaPositive,
      warmupSet: warmupSet ?? this.warmupSet,
      dropSet: dropSet ?? this.dropSet,
      failureSet: failureSet ?? this.failureSet,
    );
  }

  @override
  ThemeExtension<GritThemeData> lerp(
      ThemeExtension<GritThemeData>? other, double t) {
    if (other is! GritThemeData) return this;
    return GritThemeData(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderHighlight: Color.lerp(borderHighlight, other.borderHighlight, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      timerAmber: Color.lerp(timerAmber, other.timerAmber, t)!,
      deltaPositive: Color.lerp(deltaPositive, other.deltaPositive, t)!,
      warmupSet: Color.lerp(warmupSet, other.warmupSet, t)!,
      dropSet: Color.lerp(dropSet, other.dropSet, t)!,
      failureSet: Color.lerp(failureSet, other.failureSet, t)!,
    );
  }
}

// ─────────────────────────────────────────────
//  GRIT Design System — Typography
// ─────────────────────────────────────────────
class GritTextStyles {
  GritTextStyles._();

  static const String _metropolis = 'Metropolis';
  static const String _inter = 'Inter';

  /// DEPRECATED: Do not use `metric` directly in UI code.
  /// Use the semantic tokens below (e.g., `dataValueLarge()`, `headlineMedium()`)
  /// to maintain strict visual consistency.
  static TextStyle metric(double size,
          {Color? color,
          FontWeight? weight,
          double? letterSpacing,
          double? height}) =>
      TextStyle(
        fontFamily: _metropolis,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w800,
        color: color, // Leave null for theme default or explicit override
        letterSpacing: letterSpacing ?? (size > 20 ? -0.5 : 0.0),
        height: height ?? (size > 20 ? 0.95 : 1.0),
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle label(double size,
          {FontWeight? weight,
          Color? color,
          double? letterSpacing,
          double? height}) =>
      TextStyle(
        fontFamily: _inter,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        color: color,
        letterSpacing: letterSpacing,
        height: height ?? 1.0,
      );

  static TextStyle mono(double size,
          {FontWeight? weight,
          Color? color,
          double? letterSpacing,
          double? height}) =>
      TextStyle(
        fontFamily: _inter,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        color: color,
        letterSpacing: letterSpacing,
        height: height ?? 1.0,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // --- Displays ---
  static TextStyle displayHero() => metric(96, height: 0.9, letterSpacing: -2, weight: FontWeight.w800);
  static TextStyle displayLarge() => metric(72, height: 0.9, letterSpacing: -2, weight: FontWeight.w800);
  static TextStyle displayMedium() => metric(48, height: 0.95, letterSpacing: -1, weight: FontWeight.w800);

  // --- Headlines & Titles ---
  static TextStyle headlineLarge() => metric(32, weight: FontWeight.w800, letterSpacing: -0.5);
  static TextStyle headlineMedium() => metric(28, weight: FontWeight.w800, letterSpacing: -0.5);
  static TextStyle headlineSmall() => metric(24, weight: FontWeight.w800);
  static TextStyle titleLarge() => label(22, weight: FontWeight.w700);
  static TextStyle titleMedium() => label(20, weight: FontWeight.w700);
  static TextStyle titleSmall() => label(18, weight: FontWeight.w700);

  // --- Data & Metrics ---
  static TextStyle dataValueMassive() => metric(120, height: 0.9, weight: FontWeight.w800);
  static TextStyle dataValueLarge() => metric(28, weight: FontWeight.w800, letterSpacing: 0);
  static TextStyle dataValueSmall() => metric(24, weight: FontWeight.w800);
  static TextStyle dataUnitMedium() => label(12, weight: FontWeight.w700);
  static TextStyle dataUnitSmall() => label(9, weight: FontWeight.w700, letterSpacing: 1);

  // --- Hero Card & Deltas ---
  static TextStyle heroMetric({Color? color}) => metric(24, weight: FontWeight.w800, color: color);
  static TextStyle heroDeltaPositive({Color? color}) => mono(11, weight: FontWeight.w600, color: color);
  static TextStyle heroDeltaNegative({Color? color}) => mono(11, weight: FontWeight.w600, color: color);

  // --- Labels ---
  static TextStyle labelCaps() => label(14, weight: FontWeight.w600, letterSpacing: 2);
  static TextStyle sectionHeader() => label(11, weight: FontWeight.w600, letterSpacing: 1.5);
  static TextStyle dataLabel() => label(11, weight: FontWeight.w600);
  static TextStyle labelMicro() => label(10, weight: FontWeight.w400, letterSpacing: 0.5);
  static TextStyle buttonPrimary() => metric(20, weight: FontWeight.w700, letterSpacing: 3);
  static TextStyle tileTitle() => label(14, weight: FontWeight.w700);
  static TextStyle tileSubtitle() => label(10, weight: FontWeight.w600, letterSpacing: 1);
}

class GritSpacing {
  GritSpacing._();
  static const double base = 8.0;
  static const double horizontalMargin = 20.0;
  static const double cardMargin = 16.0;
  static const double sectionSpacing = 24.0;
  static const double touchTarget = 44.0;
  static const double divider = 1.0;

  static const double btnPrimary = 52.0;
  static const double sectionHeaderTop = 16.0;
  static const double sectionHeaderBottom = 8.0;
  static const double cardGap = 12.0;
  static const double bottomNavHeight = 60.0;
  
  static double bottomSafeArea(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return bottom > 0 ? bottom : 40.0;
  }
}

// ─────────────────────────────────────────────
//  GRIT Theme Data Factories
// ─────────────────────────────────────────────
class GritTheme {
  static final obsidianTokens = GritThemeData(
    background: const Color(0xFF0A0A0A),
    surface: const Color(0xFF121212),
    surface2: const Color(0xFF1A1A1A),
    border: const Color(0xFF333333),
    borderHighlight: const Color(0xFF444444),
    muted: const Color(0xFFC0C0C0),
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFE0E0E0),
    accent: const Color(0xFFE94560),
    success: const Color(0xFF2ECC71),
    warning: const Color(0xFFF59E0B),
    timerAmber: const Color(0xFFFFB000),
    deltaPositive: const Color(0xFF2ECC71),
    warmupSet: const Color(0xFFF59E0B),
    dropSet: const Color(0xFFD080FF),
    failureSet: const Color(0xFFFF5252),
  );

  static ThemeData obsidian() => _build(obsidianTokens, Brightness.dark);

  static ThemeData _build(GritThemeData tokens, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: tokens.background,
      extensions: [tokens],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: tokens.accent,
        onPrimary: Colors.white,
        secondary: tokens.accent,
        onSecondary: Colors.white,
        error: tokens.accent,
        onError: Colors.white,
        surface: tokens.surface,
        onSurface: tokens.textPrimary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        titleTextStyle: GritTextStyles.metric(22,
            weight: FontWeight.w900, color: tokens.textPrimary),
        contentTextStyle: GritTextStyles.label(13, color: tokens.textSecondary),
      ),
      dividerTheme: DividerThemeData(
        thickness: GritSpacing.divider,
        space: GritSpacing.divider,
        color: tokens.border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
        titleTextStyle: GritTextStyles.metric(22,
            weight: FontWeight.w900, color: tokens.textPrimary),
        shape: Border(bottom: BorderSide(color: tokens.border, width: 1)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tokens.surface,
        selectedItemColor: tokens.accent,
        unselectedItemColor: tokens.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GritTextStyles.labelMicro().copyWith(fontWeight: FontWeight.w500, letterSpacing: 1.0),
        unselectedLabelStyle: GritTextStyles.labelMicro().copyWith(fontWeight: FontWeight.w500, letterSpacing: 1.0),
      ),
      textTheme: TextTheme(
        displayLarge: GritTextStyles.metric(72, height: 0.9, letterSpacing: -2, color: tokens.textPrimary),
        displayMedium: GritTextStyles.metric(48, height: 0.95, letterSpacing: -1, weight: FontWeight.w900, color: tokens.textPrimary),
        headlineLarge: GritTextStyles.metric(32, weight: FontWeight.w900, letterSpacing: -0.5, color: tokens.textPrimary),
        titleLarge: GritTextStyles.titleLarge().copyWith(color: tokens.textPrimary),
        titleMedium: GritTextStyles.titleMedium().copyWith(color: tokens.textPrimary),
        titleSmall: GritTextStyles.titleSmall().copyWith(color: tokens.textPrimary),
        bodyLarge: GritTextStyles.label(14, color: tokens.textPrimary),
        bodyMedium: GritTextStyles.label(13, color: tokens.textPrimary),
        bodySmall: GritTextStyles.label(11, color: tokens.textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: tokens.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: tokens.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: tokens.accent, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          minimumSize: const Size(double.infinity, 52),
          textStyle: GritTextStyles.metric(18, weight: FontWeight.w800, letterSpacing: 3),
        ),
      ),
    );
  }

  static BoxDecoration gritDecoration(BuildContext context) {
    final grit = Theme.of(context).grit;
    return BoxDecoration(
      color: grit.surface,
      border: Border.all(color: grit.border, width: 1),
    );
  }
}

import 'package:material_ui/material_ui.dart';

class AppTheme {
  static const _lightAccent = Color(0xFF3A5A40);
  static const _darkAccent = Color(0xFFA9C7AF);

  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: const Color(0xFFF8F8F4),
        surface: Colors.white,
        ink: const Color(0xFF1B1C18),
        muted: const Color(0xFF74756C),
        line: const Color(0xFFE5E5DD),
        accent: _lightAccent,
        accentSoft: const Color(0xFFEDF3EE),
        error: const Color(0xFFA3413A),
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: const Color(0xFF121410),
        surface: const Color(0xFF1A1C17),
        ink: const Color(0xFFEDEEE8),
        muted: const Color(0xFFA4A79B),
        line: const Color(0xFF2D3128),
        accent: _darkAccent,
        accentSoft: const Color(0xFF223025),
        error: const Color(0xFFE2988F),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color ink,
    required Color muted,
    required Color line,
    required Color accent,
    required Color accentSoft,
    required Color error,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    ).copyWith(
      primary: accent,
      onPrimary: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF142016),
      surface: surface,
      onSurface: ink,
      error: error,
      outline: line,
      surfaceContainerHighest: accentSoft,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          color: ink,
          letterSpacing: -0.1,
        ),
        iconTheme: IconThemeData(color: ink),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      textTheme: base.textTheme.copyWith(
        displayLarge: TextStyle(
          fontFamily: 'InstrumentSerif',
          fontSize: 38,
          height: 1.03,
          color: ink,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: 'InstrumentSerif',
          fontSize: 32,
          height: 1.05,
          color: ink,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.4,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'InstrumentSerif',
          fontSize: 26,
          height: 1.1,
          color: ink,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ink,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          height: 1.5,
          color: ink,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          height: 1.5,
          color: ink,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          height: 1.45,
          color: muted,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.5,
          color: brightness == Brightness.light ? background : ink,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appBg =>
      isDark ? const Color(0xFF121410) : const Color(0xFFF8F8F4);
  Color get appSurface => isDark ? const Color(0xFF1A1C17) : Colors.white;
  Color get appSurfaceAlt =>
      isDark ? const Color(0xFF23261F) : const Color(0xFFF0F0E9);
  Color get appInk =>
      isDark ? const Color(0xFFEDEEE8) : const Color(0xFF1B1C18);
  Color get appMuted =>
      isDark ? const Color(0xFFA4A79B) : const Color(0xFF74756C);
  Color get appLine =>
      isDark ? const Color(0xFF2D3128) : const Color(0xFFE5E5DD);
  Color get appAccent =>
      isDark ? const Color(0xFFA9C7AF) : const Color(0xFF3A5A40);
  Color get appAccentSoft =>
      isDark ? const Color(0xFF223025) : const Color(0xFFEDF3EE);
  Color get appOnAccent =>
      isDark ? const Color(0xFF142016) : Colors.white;
  Color get appDanger =>
      isDark ? const Color(0xFFE2988F) : const Color(0xFFA3413A);
  Color get appDangerSoft =>
      isDark ? const Color(0xFF301E1B) : const Color(0xFFFBECEA);
  Color get appGood =>
      isDark ? const Color(0xFF9FCEAA) : const Color(0xFF2F6B3C);
  Color get appGoodSoft =>
      isDark ? const Color(0xFF1D2B20) : const Color(0xFFE9F3EA);
  Color get appMid =>
      isDark ? const Color(0xFFE0BC72) : const Color(0xFF8A6113);
  Color get appMidSoft =>
      isDark ? const Color(0xFF2B2517) : const Color(0xFFFBF3DF);
}

part of 'theme.dart';

/// Calm greens, readable type, cards without heavy shadows.
abstract final class AppTheme {
  static const _seed = Color(0xFF3F6A3A);

  static ThemeData get light => _build(Brightness.light, BotanicaColors.light);

  static ThemeData get dark => _build(Brightness.dark, BotanicaColors.dark);

  static ThemeData _build(Brightness brightness, BotanicaColors status) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [status],
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

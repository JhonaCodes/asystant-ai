part of 'theme.dart';

/// Status colors the Material scheme does not have: safe, caution, danger,
/// and the badges for bundled and person-added plants.
@immutable
class BotanicaColors extends ThemeExtension<BotanicaColors> {
  const BotanicaColors({
    required this.safe,
    required this.caution,
    required this.danger,
    required this.seed,
    required this.person,
  });

  static const light = BotanicaColors(
    safe: Color(0xFF1D6F5C),
    caution: Color(0xFF8A6100),
    danger: Color(0xFFB3261E),
    seed: Color(0xFF3F6A3A),
    person: Color(0xFF6A4C93),
  );

  static const dark = BotanicaColors(
    safe: Color(0xFF7FD1B9),
    caution: Color(0xFFE9C46A),
    danger: Color(0xFFF2B8B5),
    seed: Color(0xFFA7D49B),
    person: Color(0xFFCDB8F0),
  );

  final Color safe;

  final Color caution;

  final Color danger;

  final Color seed;

  final Color person;

  static BotanicaColors of(BuildContext context) =>
      Theme.of(context).extension<BotanicaColors>() ?? light;

  @override
  BotanicaColors copyWith({
    Color? safe,
    Color? caution,
    Color? danger,
    Color? seed,
    Color? person,
  }) => BotanicaColors(
    safe: safe ?? this.safe,
    caution: caution ?? this.caution,
    danger: danger ?? this.danger,
    seed: seed ?? this.seed,
    person: person ?? this.person,
  );

  @override
  BotanicaColors lerp(covariant BotanicaColors? other, double t) =>
      t < .5 ? this : other ?? this;
}

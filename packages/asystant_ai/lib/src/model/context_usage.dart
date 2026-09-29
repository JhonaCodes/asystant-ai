/// How much of the model's context window the conversation occupies.
///
/// Derived from the latest provider count, never stored.
class ContextUsage {
  const ContextUsage({required this.used, this.limit});

  /// From here the meter turns amber: the conversation is getting long.
  static const double longRatio = .7;

  /// From here the chat suggests starting a new conversation.
  static const double fullRatio = .9;

  final int used;

  /// The model's context window; null when the provider does not report it.
  final int? limit;

  int? get remaining => switch (limit) {
    final int limit => (limit - used).clamp(0, limit),
    null => null,
  };

  /// Used share between 0 and 1, or null without a known [limit].
  double? get ratio => switch (limit) {
    final int limit when limit > 0 => (used / limit).clamp(0, 1).toDouble(),
    _ => null,
  };

  bool get isLong => (ratio ?? 0) >= longRatio;

  bool get isAlmostFull => (ratio ?? 0) >= fullRatio;

  /// Used share as a whole percentage, or null without a known limit.
  int? get percent => switch (ratio) {
    final double ratio => (ratio * 100).round(),
    null => null,
  };

  ContextUsage copyWith({int? used, int? limit}) =>
      ContextUsage(used: used ?? this.used, limit: limit ?? this.limit);

  @override
  bool operator ==(Object other) =>
      other is ContextUsage && used == other.used && limit == other.limit;

  @override
  int get hashCode => Object.hash(used, limit);
}

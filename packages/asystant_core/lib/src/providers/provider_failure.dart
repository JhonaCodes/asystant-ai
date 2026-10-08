import 'package:asystant_core/src/model/assistant_failure.dart';

/// Failure signals every provider reads the same way, so OpenRouter and
/// Claude Code cannot classify one status or phrase differently again.
abstract final class ProviderFailure {
  /// Phrases every provider uses to say the request does not fit the context.
  static const contextFullPhrases = [
    'context length',
    'context window',
    'too many tokens',
  ];

  /// The code [status] decides on its own; null when the provider needs more.
  static FailureCode? codeOfStatus(Object? status) => switch (status) {
    401 || 403 => FailureCode.authentication,
    413 => FailureCode.contextFull,
    429 => FailureCode.rateLimited,
    _ => null,
  };

  /// Whether [detail] says the context is full, by a shared phrase or one
  /// of the provider's own [extraPhrases].
  static bool mentionsContextFull(
    String detail, {
    List<String> extraPhrases = const [],
  }) {
    final text = detail.toLowerCase();
    return [...contextFullPhrases, ...extraPhrases].any(text.contains);
  }
}

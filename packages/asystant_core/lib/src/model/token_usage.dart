import 'package:asystant_core/src/model/assistant_value.dart';

/// Tokens that one inference consumed, as reported by the provider.
///
/// [promptTokens] is the size of the whole conversation sent to the model, so
/// the latest value is what the conversation currently occupies of the
/// model's context window.
class TokenUsage extends AssistantValue {
  const TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
  });

  final int promptTokens;

  final int completionTokens;

  int get totalTokens => promptTokens + completionTokens;

  TokenUsage copyWith({int? promptTokens, int? completionTokens}) => TokenUsage(
    promptTokens: promptTokens ?? this.promptTokens,
    completionTokens: completionTokens ?? this.completionTokens,
  );

  factory TokenUsage.fromJson(Map<String, Object?> json) => TokenUsage(
    promptTokens: json['prompt_tokens'] as int,
    completionTokens: json['completion_tokens'] as int,
  );

  @override
  Map<String, Object?> toJson() => {
    'prompt_tokens': promptTokens,
    'completion_tokens': completionTokens,
  };
}

import 'package:asystant_core/src/model/assistant_value.dart';

/// A named instruction registered with the gateway for this assistant instance.
class AsystantSystemPrompt extends AssistantValue {
  const AsystantSystemPrompt({required this.id, required this.content});

  final String id;

  final String content;

  AsystantSystemPrompt copyWith({String? id, String? content}) =>
      AsystantSystemPrompt(id: id ?? this.id, content: content ?? this.content);

  factory AsystantSystemPrompt.fromJson(Map<String, Object?> json) =>
      AsystantSystemPrompt(
        id: json['id'] as String,
        content: json['content'] as String,
      );

  @override
  Map<String, Object?> toJson() => {'id': id, 'content': content};
}

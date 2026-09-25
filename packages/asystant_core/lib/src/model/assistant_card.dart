import 'package:asystant_core/src/model/assistant_value.dart';

/// Supported presentations for read-only summaries, user choices and action results.
enum AssistantCardKind { summary, entity, selection, permission, result }

/// A structured presentation returned by a local tool, never executable UI code.
class AssistantCard extends AssistantValue {
  const AssistantCard({
    required this.title,
    this.body = '',
    this.kind = AssistantCardKind.summary,
    this.options = const [],
  });
  final String title;
  final String body;
  final AssistantCardKind kind;

  /// Stable option values; application tools may map these to domain identifiers.
  final List<String> options;
  AssistantCard copyWith({
    String? title,
    String? body,
    AssistantCardKind? kind,
    List<String>? options,
  }) => AssistantCard(
    title: title ?? this.title,
    body: body ?? this.body,
    kind: kind ?? this.kind,
    options: List.unmodifiable(options ?? this.options),
  );
  factory AssistantCard.fromJson(Map<String, Object?> json) => AssistantCard(
    title: json['title'] as String,
    body: json['body'] as String,
    kind: AssistantCardKind.values.byName(json['kind'] as String),
    options: List.unmodifiable(
      (json['options'] as List<Object?>).cast<String>(),
    ),
  );
  @override
  Map<String, Object?> toJson() => {
    'title': title,
    'body': body,
    'kind': kind.name,
    'options': options,
  };
}

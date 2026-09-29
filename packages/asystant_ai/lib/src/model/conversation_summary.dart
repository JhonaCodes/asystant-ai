import 'package:asystant_core/asystant_core.dart';

/// One conversation as the list shows it: never its messages.
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.model,
    required this.createdAt,
    required this.updatedAt,
    this.usage,
  });

  /// Longest title kept from the first message.
  static const int titleLength = 60;

  final String id;

  /// An excerpt of the first message; empty until something is sent.
  final String title;

  final String model;

  final DateTime createdAt;

  final DateTime updatedAt;

  /// The provider's latest count for this conversation.
  final TokenUsage? usage;

  /// A one-line excerpt of [text] for the title.
  static String excerpt(String text) {
    final line = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    return line.length <= titleLength
        ? line
        : '${line.substring(0, titleLength - 1)}…';
  }

  ConversationSummary copyWith({
    String? id,
    String? title,
    String? model,
    DateTime? createdAt,
    DateTime? updatedAt,
    TokenUsage? usage,
  }) => ConversationSummary(
    id: id ?? this.id,
    title: title ?? this.title,
    model: model ?? this.model,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    usage: usage ?? this.usage,
  );

  factory ConversationSummary.fromJson(Map<String, Object?> json) =>
      ConversationSummary(
        id: json['id'] as String,
        title: json['title'] as String,
        model: json['model'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        usage: switch (json['usage']) {
          final Map<String, Object?> usage => TokenUsage.fromJson(usage),
          _ => null,
        },
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'model': model,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'usage': usage?.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is ConversationSummary &&
      id == other.id &&
      title == other.title &&
      model == other.model &&
      createdAt == other.createdAt &&
      updatedAt == other.updatedAt &&
      usage == other.usage;

  @override
  int get hashCode =>
      Object.hash(id, title, model, createdAt, updatedAt, usage);
}

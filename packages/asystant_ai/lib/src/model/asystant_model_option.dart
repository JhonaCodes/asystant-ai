import 'package:flutter/widgets.dart';

/// A model the person can choose in the chat, as the host names it.
///
/// ```dart
/// AsystantModelOption(
///   id: 'openai/gpt-oss-120b',
///   label: 'Preciso',
///   icon: Icons.psychology_outlined,
///   description: 'Respuestas más completas',
/// )
/// ```
@immutable
class AsystantModelOption {
  const AsystantModelOption({
    required this.id,
    required this.label,
    this.icon,
    this.description = '',
  });

  /// A model the host did not describe: its short id as the label.
  factory AsystantModelOption.fallback(String id) =>
      AsystantModelOption(id: id, label: id.split('/').last);

  factory AsystantModelOption.fromJson(Map<String, Object?> json) =>
      AsystantModelOption(
        id: json['id'] as String,
        label: json['label'] as String,
        description: json['description'] as String? ?? '',
      );

  /// The provider's model id, e.g. `openai/gpt-oss-120b`.
  final String id;

  /// What the person reads, e.g. "Preciso".
  final String label;

  /// Shown next to [label]; none when null.
  final IconData? icon;

  /// A short line under the label in the list, e.g. "Respuestas más completas".
  final String description;

  AsystantModelOption copyWith({
    String? id,
    String? label,
    IconData? icon,
    String? description,
  }) => AsystantModelOption(
    id: id ?? this.id,
    label: label ?? this.label,
    icon: icon ?? this.icon,
    description: description ?? this.description,
  );

  /// The icon is code, not data, so it is not serialized.
  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'description': description,
  };

  @override
  bool operator ==(Object other) =>
      other is AsystantModelOption &&
      id == other.id &&
      label == other.label &&
      icon == other.icon &&
      description == other.description;

  @override
  int get hashCode => Object.hash(id, label, icon, description);

  @override
  String toString() => 'AsystantModelOption($id, $label)';
}

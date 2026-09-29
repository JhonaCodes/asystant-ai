/// What the person wants to achieve, e.g. `sleep_better`.
class Goal {
  const Goal({required this.id, required this.description, this.tag});

  factory Goal.fromJson(Map<String, Object?> json) => Goal(
    id: json['id'] as String,
    description: json['description'] as String,
    tag: json['tag'] as String?,
  );

  final String id;

  final String description;

  final String? tag;

  Goal copyWith({String? id, String? description, String? tag}) => Goal(
    id: id ?? this.id,
    description: description ?? this.description,
    tag: tag ?? this.tag,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'description': description,
    'tag': tag,
  };

  @override
  bool operator ==(Object other) =>
      other is Goal &&
      id == other.id &&
      description == other.description &&
      tag == other.tag;

  @override
  int get hashCode => Object.hash(id, description, tag);

  @override
  String toString() => 'Goal($id, $tag)';
}

import 'package:collection/collection.dart';

/// JSON serialization is confined to this transport boundary, never to widgets.
abstract class AssistantValue {
  const AssistantValue();

  Map<String, Object?> toJson();

  // keel-debt: == and hashCode serialize the whole object with toJson() on every call;
  // keel-debt: cache the decoded map in ToolArguments, or rewrite the hierarchy in a major.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantValue &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(toJson(), other.toJson());

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(toJson()));
}

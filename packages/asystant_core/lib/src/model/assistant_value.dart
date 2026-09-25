import 'package:collection/collection.dart';

/// JSON serialization is confined to this transport boundary, never to widgets.
abstract class AssistantValue {
  const AssistantValue();

  Map<String, Object?> toJson();

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

import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/transport/inference_event.dart';

/// A terminal failure that must not trigger automatic replay of local writes.
class InferenceFailed extends InferenceEvent {
  const InferenceFailed(this.failure);

  final AssistantFailure failure;

  InferenceFailed copyWith({AssistantFailure? failure}) =>
      InferenceFailed(failure ?? this.failure);

  @override
  bool operator ==(Object other) =>
      other is InferenceFailed && failure == other.failure;

  @override
  int get hashCode => failure.hashCode;
}

import 'inference_event.dart';
import '../model/assistant_failure.dart';

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

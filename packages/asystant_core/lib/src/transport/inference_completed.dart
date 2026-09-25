import 'inference_event.dart';
import '../model/assistant_message.dart';

class InferenceCompleted extends InferenceEvent {
  const InferenceCompleted(this.message);
  final AssistantMessage message;
  InferenceCompleted copyWith({AssistantMessage? message}) =>
      InferenceCompleted(message ?? this.message);
  @override
  bool operator ==(Object other) =>
      other is InferenceCompleted && message == other.message;
  @override
  int get hashCode => message.hashCode;
}

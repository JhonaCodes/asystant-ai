import 'package:asystant_core/src/model/assistant_message.dart';
import 'package:asystant_core/src/transport/inference_event.dart';

/// A complete model response whose local calls can now be validated.
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

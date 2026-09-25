export 'text_delta.dart';
export 'inference_completed.dart';
export 'inference_failed.dart';

/// Ephemeral provider events. Concrete types define their own value semantics.
abstract class InferenceEvent {
  const InferenceEvent();
}

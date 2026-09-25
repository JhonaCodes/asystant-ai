export 'package:asystant_core/src/transport/inference_completed.dart';
export 'package:asystant_core/src/transport/inference_failed.dart';
export 'package:asystant_core/src/transport/text_delta.dart';

/// Ephemeral provider events. Concrete types define their own value semantics.
abstract class InferenceEvent {
  const InferenceEvent();
}

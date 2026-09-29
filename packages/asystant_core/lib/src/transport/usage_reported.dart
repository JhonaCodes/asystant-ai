import 'package:asystant_core/src/model/token_usage.dart';
import 'package:asystant_core/src/transport/inference_event.dart';

/// The provider's token count for the current inference, sent before
/// [InferenceCompleted].
class UsageReported extends InferenceEvent {
  const UsageReported(this.usage);

  final TokenUsage usage;

  UsageReported copyWith({TokenUsage? usage}) =>
      UsageReported(usage ?? this.usage);

  @override
  bool operator ==(Object other) =>
      other is UsageReported && usage == other.usage;

  @override
  int get hashCode => usage.hashCode;
}

import 'package:asystant_core/src/model/assistant_failure.dart';

/// An execution capability, not a serializable model. Host tools check cancellation
/// before committing a write and pass idempotencyKey to their own repository.
class ToolContext {
  ToolContext({
    required this.idempotencyKey,
    required this.selectedOptions,
    required bool Function() isCanceled,
  }) : _isCanceled = isCanceled;

  /// Pass this key to the host repository to prevent duplicate effects.
  final String idempotencyKey;

  /// Option values explicitly selected by the user for this call.
  final List<String> selectedOptions;
  final bool Function() _isCanceled;

  /// Whether this execution capability has been canceled or invalidated.
  bool get isCanceled => _isCanceled();

  /// Throws a canceled failure; call immediately before committing a write.
  void checkCanceled() {
    if (isCanceled) {
      throw const AssistantFailure(.canceled);
    }
  }
}

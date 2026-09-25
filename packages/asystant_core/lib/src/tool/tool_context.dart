import 'package:asystant_core/src/model/assistant_failure.dart';

/// An execution capability, not a serializable model. Host tools check cancellation
/// before committing a write and pass idempotencyKey to their own repository.
class ToolContext {
  ToolContext({
    required this.idempotencyKey,
    required this.selectedOptions,
    required bool Function() isCanceled,
  }) : _isCanceled = isCanceled;
  final String idempotencyKey;
  final List<String> selectedOptions;
  final bool Function() _isCanceled;
  bool get isCanceled => _isCanceled();
  void checkCanceled() {
    if (isCanceled) throw const AssistantFailure(.canceled);
  }
}

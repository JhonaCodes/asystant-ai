import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/model/asystant_attachment.dart';

/// Receives a tool's progress: [fraction] from 0 to 1 and a short [label]
/// for the person, or an empty one.
typedef ToolProgressListener = void Function(double fraction, String label);

/// An execution capability, not a serializable model. Host tools check cancellation
/// before committing a write and pass idempotencyKey to their own repository.
class ToolContext {
  ToolContext({
    required this.idempotencyKey,
    required this.selectedOptions,
    required bool Function() isCanceled,
    this.attachments = const [],
    ToolProgressListener? onProgress,
  }) : _isCanceled = isCanceled,
       _onProgress = onProgress;

  /// Pass this key to the host repository to prevent duplicate effects.
  final String idempotencyKey;

  /// Option values explicitly selected by the user for this call.
  final List<String> selectedOptions;

  /// Files attached in this conversation. The model refers to them by id.
  final List<AsystantAttachment> attachments;

  /// The attached file with [id], if any.
  AsystantAttachment? attachment(String id) {
    for (final file in attachments) {
      if (file.id == id) {
        return file;
      }
    }
    return null;
  }

  final bool Function() _isCanceled;

  final ToolProgressListener? _onProgress;

  /// Whether this execution capability has been canceled or invalidated.
  bool get isCanceled => _isCanceled();

  /// Throws a canceled failure; call immediately before committing a write.
  void checkCanceled() {
    if (isCanceled) {
      throw const AssistantFailure(.canceled);
    }
  }

  /// Reports how far a long tool has come, for the person to see while it
  /// runs: [fraction] from 0 to 1 (clamped; a non-finite value is ignored)
  /// and an optional short [label], such as "Frame 12 of 48".
  ///
  /// Call it as often as the work advances: the chat coalesces the updates.
  /// It never reaches the model, and it does nothing once the call is
  /// canceled or when nobody listens.
  void reportProgress(double fraction, {String label = ''}) {
    if (!fraction.isFinite || isCanceled) {
      return;
    }
    _onProgress?.call(fraction.clamp(0.0, 1.0), label);
  }
}

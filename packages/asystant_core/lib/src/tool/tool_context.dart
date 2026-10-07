// keel-debt: 5 public types in one file (one-class-per-file rule); split when
//   the next major allows moving declaring URIs.
import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/model/asystant_attachment.dart';

/// Receives a tool's progress: [fraction] from 0 to 1 and a short [label]
/// for the person, or an empty one.
typedef ToolProgressListener = void Function(double fraction, String label);

/// Metadata only. Values entered in the chat are delivered directly to the
/// executing local tool and are never part of a model message.
class PrivateInputField {
  const PrivateInputField({
    required this.name,
    required this.label,
    this.kind = .secret,
    this.required = true,
  });
  final String name;
  final String label;
  final PrivateInputKind kind;
  final bool required;
}

/// How a [PrivateInputField] should be entered and displayed; the host UI
/// decides obscuring and keyboard type from this, never from the field name.
enum PrivateInputKind { secret, password, code, totp, text }

// keel-debt: returns an untyped Map<String, String> unrelated to the fields asked;
//   type it as a PrivateInputValues model in the next major.
/// Shown by the host UI to collect [fields] inline in the chat, titled
/// [title]. Returns the entered values keyed by [PrivateInputField.name],
/// or null when the person dismisses the request without submitting.
typedef PrivateInputRequester = Future<Map<String, String>?> Function(
  String title,
  List<PrivateInputField> fields,
);

/// An execution capability, not a serializable model. Host tools check cancellation
/// before committing a write and pass idempotencyKey to their own repository.
class ToolContext {
  ToolContext({
    required this.idempotencyKey,
    required this.selectedOptions,
    required bool Function() isCanceled,
    this.attachments = const [],
    ToolProgressListener? onProgress,
    PrivateInputRequester? onPrivateInput,
  }) : _isCanceled = isCanceled,
       _onProgress = onProgress,
       _onPrivateInput = onPrivateInput;

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
  final PrivateInputRequester? _onPrivateInput;

  bool get supportsPrivateInput => _onPrivateInput != null;

  /// Requests any number of private fields in an inline chat card. The model
  /// sees only the tool's eventual safe outcome, never the entered values.
  Future<Map<String, String>?> requestPrivateInput(
    String title,
    List<PrivateInputField> fields,
  ) async {
    checkCanceled();
    if (_onPrivateInput == null) return null;
    final values = await _onPrivateInput(title, fields);
    checkCanceled();
    return values;
  }

  /// Whether this execution capability has been canceled or invalidated.
  bool get isCanceled => _isCanceled();

  // keel-debt: throws AssistantFailure for an expected flow, and callers that catch(_)
  //   lose the .canceled code; return a Result in the next major.
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

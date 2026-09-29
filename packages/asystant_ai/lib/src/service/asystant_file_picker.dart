import 'package:asystant_core/asystant_core.dart';
import 'package:file_picker/file_picker.dart';

/// Files the person picked, and why any of them were left out.
typedef AsystantPickedFiles = ({
  List<AsystantAttachment> files,
  AttachmentIssue? issue,
});

/// Opens a picker limited by the policy and returns the chosen files.
///
/// Pass your own to `AsystantChat.onPickFiles` to use a camera, a document
/// scanner or your app's file browser instead.
typedef AsystantFilePick = Future<AsystantPickedFiles> Function(
  AsystantAttachmentPolicy policy,
);

/// The system file picker, filtered by the policy's extensions.
abstract final class AsystantFilePicker {
  static Future<AsystantPickedFiles> pick(
    AsystantAttachmentPolicy policy,
  ) async {
    final picked = await FilePicker.pickFiles(
      type: policy.acceptsAnyType ? FileType.any : FileType.custom,
      allowedExtensions: policy.acceptsAnyType
          ? null
          : policy.normalizedExtensions,
    );
    final files = <AsystantAttachment>[];
    AttachmentIssue? issue;
    for (final file in picked) {
      // Checked before reading, so a huge file is never loaded.
      final size = await file.length();
      final rejected = policy.issueFor(
        filename: file.name,
        size: size,
        pending: files.length,
      );
      if (rejected != null) {
        issue ??= rejected;
        continue;
      }
      try {
        files.add(
          AsystantAttachment.fromBytes(
            bytes: await file.readAsBytes(),
            filename: file.name,
          ),
        );
      } on Exception {
        issue ??= AttachmentIssue.unreadable;
      }
    }
    return (files: List<AsystantAttachment>.unmodifiable(files), issue: issue);
  }
}

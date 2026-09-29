import 'package:collection/collection.dart';

import 'package:asystant_core/src/model/asystant_attachment.dart';

/// Which files the person may attach.
///
/// With no [allowedExtensions] every type is accepted:
///
/// ```dart
/// const AsystantAttachmentPolicy()                               // anything
/// const AsystantAttachmentPolicy(allowedExtensions: ['pdf', 'csv'])
/// AsystantAttachmentPolicy(allowedExtensions: AsystantFileTypes.images)
/// AsystantAttachmentPolicy.disabled                              // no attach button
/// ```
class AsystantAttachmentPolicy {
  const AsystantAttachmentPolicy({
    this.allowedExtensions = const [],
    this.maxFiles = 10,
    this.maxFileBytes = 10 * 1024 * 1024,
    this.enabled = true,
  });

  /// Hides the attach button and refuses every file.
  static const disabled = AsystantAttachmentPolicy(enabled: false);

  /// Extensions without the dot, case-insensitive; empty accepts all.
  final List<String> allowedExtensions;

  /// Files waiting in the composer at once.
  final int maxFiles;

  /// Largest file accepted, in bytes.
  final int maxFileBytes;

  final bool enabled;

  bool get acceptsAnyType => allowedExtensions.isEmpty;

  /// [allowedExtensions] lowercased and without dots, for pickers.
  List<String> get normalizedExtensions => [
    for (final extension in allowedExtensions)
      extension.trim().toLowerCase().replaceFirst(RegExp(r'^\.'), ''),
  ];

  bool acceptsName(String filename) =>
      acceptsAnyType ||
      normalizedExtensions.contains(AsystantAttachment.extensionOf(filename));

  /// Why a file of [filename] and [size] cannot join [pending] files, or
  /// null when it can.
  AttachmentIssue? issueFor({
    required String filename,
    required int size,
    required int pending,
  }) {
    if (!enabled) {
      return AttachmentIssue.disabled;
    }
    if (pending >= maxFiles) {
      return AttachmentIssue.tooMany;
    }
    if (!acceptsName(filename)) {
      return AttachmentIssue.type;
    }
    if (size > maxFileBytes) {
      return AttachmentIssue.tooLarge;
    }
    if (size == 0) {
      return AttachmentIssue.empty;
    }
    return null;
  }

  AsystantAttachmentPolicy copyWith({
    List<String>? allowedExtensions,
    int? maxFiles,
    int? maxFileBytes,
    bool? enabled,
  }) => AsystantAttachmentPolicy(
    allowedExtensions: List.unmodifiable(
      allowedExtensions ?? this.allowedExtensions,
    ),
    maxFiles: maxFiles ?? this.maxFiles,
    maxFileBytes: maxFileBytes ?? this.maxFileBytes,
    enabled: enabled ?? this.enabled,
  );

  @override
  bool operator ==(Object other) =>
      other is AsystantAttachmentPolicy &&
      const ListEquality<String>().equals(
        allowedExtensions,
        other.allowedExtensions,
      ) &&
      maxFiles == other.maxFiles &&
      maxFileBytes == other.maxFileBytes &&
      enabled == other.enabled;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(allowedExtensions),
    maxFiles,
    maxFileBytes,
    enabled,
  );
}

/// Why a file was not attached.
enum AttachmentIssue { disabled, tooMany, type, tooLarge, empty, unreadable }

/// Ready-made extension groups for [AsystantAttachmentPolicy].
abstract final class AsystantFileTypes {
  static const images = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'heic'];

  static const documents = ['pdf', 'txt', 'md', 'doc', 'docx'];

  static const spreadsheets = ['csv', 'tsv', 'xls', 'xlsx'];

  static const data = ['json', 'xml', 'yaml', 'yml'];

  static const audio = ['mp3', 'wav', 'm4a'];
}

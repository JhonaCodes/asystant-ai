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
    this.allowedMimeTypes = const [],
    this.allowedFilenamePatterns = const [],
    this.blockedFilenamePatterns = const [],
    this.blockedTextPatterns = const [],
    this.maxFiles = 10,
    this.maxFileBytes = 10 * 1024 * 1024,
    this.enabled = true,
    this.rejectLikelySecrets = false,
  });

  /// Hides the attach button and refuses every file.
  static const disabled = AsystantAttachmentPolicy(enabled: false);

  /// Extensions without the dot, case-insensitive; empty accepts all.
  final List<String> allowedExtensions;

  /// Exact MIME types or groups like `image/*`; empty accepts any MIME type.
  final List<String> allowedMimeTypes;

  /// Host-defined regular expressions for file names. Allow rules are ORed;
  /// an accepted extension and MIME type are still required when configured.
  final List<RegExp> allowedFilenamePatterns;

  /// Any matching name is rejected, even when an allow rule matched.
  final List<RegExp> blockedFilenamePatterns;

  /// Any matching text attachment is rejected before it enters the chat.
  /// These rules apply only to files recognized as text.
  final List<RegExp> blockedTextPatterns;

  /// Files waiting in the composer at once.
  final int maxFiles;

  /// Largest file accepted, in bytes.
  final int maxFileBytes;

  final bool enabled;

  /// Refuses text files that appear to contain embedded credentials. This is
  /// a best-effort guard for accidental uploads, not a secret detector for
  /// PDFs, images or arbitrary encoded values.
  final bool rejectLikelySecrets;

  static final RegExp _likelySecret = RegExp(
    r'''["']?(?:api[_-]?key|client[_-]?secret|access[_-]?token|refresh[_-]?token|password)["']?\s*[:=]\s*["']?[A-Za-z0-9_./+=-]{16,}|\bBearer\s+[A-Za-z0-9._~-]{20,}|-----BEGIN [A-Z ]+PRIVATE KEY-----|https?://[^\s/@:]+:[^\s/@]+@''',
    caseSensitive: false,
  );

  bool get acceptsAnyType => allowedExtensions.isEmpty;

  /// [allowedExtensions] lowercased and without dots, for pickers.
  List<String> get normalizedExtensions => [
    for (final extension in allowedExtensions)
      extension.trim().toLowerCase().replaceFirst(RegExp(r'^\.'), ''),
  ];

  bool acceptsName(String filename) =>
      (acceptsAnyType ||
          normalizedExtensions.contains(
            AsystantAttachment.extensionOf(filename),
          )) &&
      (allowedFilenamePatterns.isEmpty ||
          allowedFilenamePatterns.any(
            (pattern) => pattern.hasMatch(filename),
          )) &&
      !blockedFilenamePatterns.any((pattern) => pattern.hasMatch(filename));

  bool acceptsMimeType(String mimeType) =>
      allowedMimeTypes.isEmpty ||
      allowedMimeTypes.any((allowed) {
        final rule = allowed.toLowerCase().trim();
        final actual = mimeType.toLowerCase();
        return rule == actual ||
            (rule.endsWith('/*') &&
                actual.startsWith(rule.substring(0, rule.length - 1)));
      });

  /// Why a file of [filename] and [size] cannot join [pending] files, or
  /// null when it can.
  AttachmentIssue? issueFor({
    required String filename,
    required int size,
    required int pending,
    String? mimeType,
  }) {
    if (!enabled) {
      return AttachmentIssue.disabled;
    }
    if (pending >= maxFiles) {
      return AttachmentIssue.tooMany;
    }
    if (!acceptsName(filename) ||
        !acceptsMimeType(mimeType ?? AsystantAttachment.mimeTypeOf(filename))) {
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

  /// Validates metadata first, then checks text content when enabled.
  AttachmentIssue? issueForAttachment(
    AsystantAttachment file, {
    required int pending,
  }) {
    final issue = issueFor(
      filename: file.filename,
      size: file.size,
      pending: pending,
      mimeType: file.mimeType,
    );
    if (issue != null) return issue;
    if (rejectLikelySecrets &&
        file.isText &&
        _likelySecret.hasMatch(file.text)) {
      return AttachmentIssue.sensitiveContent;
    }
    if (file.isText &&
        blockedTextPatterns.any((pattern) => pattern.hasMatch(file.text))) {
      return AttachmentIssue.blockedContent;
    }
    return null;
  }

  AsystantAttachmentPolicy copyWith({
    List<String>? allowedExtensions,
    List<String>? allowedMimeTypes,
    List<RegExp>? allowedFilenamePatterns,
    List<RegExp>? blockedFilenamePatterns,
    List<RegExp>? blockedTextPatterns,
    int? maxFiles,
    int? maxFileBytes,
    bool? enabled,
    bool? rejectLikelySecrets,
  }) => AsystantAttachmentPolicy(
    allowedExtensions: List.unmodifiable(
      allowedExtensions ?? this.allowedExtensions,
    ),
    allowedMimeTypes: List.unmodifiable(
      allowedMimeTypes ?? this.allowedMimeTypes,
    ),
    allowedFilenamePatterns: List.unmodifiable(
      allowedFilenamePatterns ?? this.allowedFilenamePatterns,
    ),
    blockedFilenamePatterns: List.unmodifiable(
      blockedFilenamePatterns ?? this.blockedFilenamePatterns,
    ),
    blockedTextPatterns: List.unmodifiable(
      blockedTextPatterns ?? this.blockedTextPatterns,
    ),
    maxFiles: maxFiles ?? this.maxFiles,
    maxFileBytes: maxFileBytes ?? this.maxFileBytes,
    enabled: enabled ?? this.enabled,
    rejectLikelySecrets: rejectLikelySecrets ?? this.rejectLikelySecrets,
  );

  @override
  bool operator ==(Object other) =>
      other is AsystantAttachmentPolicy &&
      const ListEquality<String>().equals(
        allowedExtensions,
        other.allowedExtensions,
      ) &&
      const ListEquality<String>().equals(
        allowedMimeTypes,
        other.allowedMimeTypes,
      ) &&
      const ListEquality<RegExp>().equals(
        allowedFilenamePatterns,
        other.allowedFilenamePatterns,
      ) &&
      const ListEquality<RegExp>().equals(
        blockedFilenamePatterns,
        other.blockedFilenamePatterns,
      ) &&
      const ListEquality<RegExp>().equals(
        blockedTextPatterns,
        other.blockedTextPatterns,
      ) &&
      maxFiles == other.maxFiles &&
      maxFileBytes == other.maxFileBytes &&
      enabled == other.enabled &&
      rejectLikelySecrets == other.rejectLikelySecrets;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(allowedExtensions),
    Object.hashAll(allowedMimeTypes),
    Object.hashAll(allowedFilenamePatterns),
    Object.hashAll(blockedFilenamePatterns),
    Object.hashAll(blockedTextPatterns),
    maxFiles,
    maxFileBytes,
    enabled,
    rejectLikelySecrets,
  );
}

/// Why a file was not attached.
enum AttachmentIssue {
  disabled,
  tooMany,
  type,
  tooLarge,
  empty,
  unreadable,
  sensitiveContent,
  blockedContent,
}

/// Ready-made extension groups for [AsystantAttachmentPolicy].
abstract final class AsystantFileTypes {
  static const images = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'heic'];

  static const documents = ['pdf', 'txt', 'md', 'doc', 'docx'];

  static const spreadsheets = ['csv', 'tsv', 'xls', 'xlsx'];

  static const data = ['json', 'xml', 'yaml', 'yml'];

  static const audio = ['mp3', 'wav', 'm4a'];
}

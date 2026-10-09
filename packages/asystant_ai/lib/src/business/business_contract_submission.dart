import 'package:asystant_core/asystant_core.dart';

/// A contract the register or update tool is about to save, with the
/// source document it came from: an attached text file
/// ([documentAttachmentId], such as the endpoints `.md`) or text the model
/// passed ([documentText]). Transient tool input, never serialized, so it
/// has no JSON form.
class BusinessContractSubmission {
  const BusinessContractSubmission({
    required this.contract,
    this.documentAttachmentId,
    this.documentText,
  });

  final BusinessContract contract;
  final String? documentAttachmentId;
  final String? documentText;

  /// Whether a source document comes with the contract.
  bool get hasDocument => documentAttachmentId != null || documentText != null;

  BusinessContractSubmission copyWith({
    BusinessContract? contract,
    String? documentAttachmentId,
    String? documentText,
  }) => BusinessContractSubmission(
    contract: contract ?? this.contract,
    documentAttachmentId: documentAttachmentId ?? this.documentAttachmentId,
    documentText: documentText ?? this.documentText,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessContractSubmission &&
          contract == other.contract &&
          documentAttachmentId == other.documentAttachmentId &&
          documentText == other.documentText;

  @override
  int get hashCode => Object.hash(contract, documentAttachmentId, documentText);
}

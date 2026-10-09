import 'package:asystant_core/src/business/business_json_reading.dart';

/// The source document a business was registered from, such as the `.md`
/// that maps its endpoints. Kept per business so the model can consult it
/// later (`BusinessDocumentReading`), never as instructions.
class BusinessDocument {
  const BusinessDocument({
    required this.businessId,
    required this.text,
    this.title = '',
  });

  /// The largest document kept, in characters.
  static const int maxLength = 512000;

  final String businessId;

  /// Where it came from, such as the attached file name; may be empty.
  final String title;

  /// The document as written, usually Markdown.
  final String text;

  factory BusinessDocument.fromJson(Map<String, Object?> json) =>
      BusinessDocument(
        businessId: json.requiredString('business_id'),
        title: json.optionalString('title', ''),
        text: json.requiredString('text'),
      );

  Map<String, Object?> toJson() => {
    'business_id': businessId,
    if (title.isNotEmpty) 'title': title,
    'text': text,
  };

  BusinessDocument copyWith({
    String? businessId,
    String? title,
    String? text,
  }) => BusinessDocument(
    businessId: businessId ?? this.businessId,
    title: title ?? this.title,
    text: text ?? this.text,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessDocument &&
          businessId == other.businessId &&
          title == other.title &&
          text == other.text;

  @override
  int get hashCode => Object.hash(businessId, title, text);
}

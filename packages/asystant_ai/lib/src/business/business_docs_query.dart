import 'package:asystant_core/asystant_core.dart';

/// One decoded call of `ReadBusinessDocsTool`: the business and the query,
/// empty to read from the start. Transient tool input, never serialized,
/// so it has no JSON form.
class BusinessDocsQuery {
  const BusinessDocsQuery({required this.business, this.query = ''});

  final BusinessContract business;
  final String query;

  BusinessDocsQuery copyWith({BusinessContract? business, String? query}) =>
      BusinessDocsQuery(
        business: business ?? this.business,
        query: query ?? this.query,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessDocsQuery &&
          business == other.business &&
          query == other.query;

  @override
  int get hashCode => Object.hash(business, query);
}

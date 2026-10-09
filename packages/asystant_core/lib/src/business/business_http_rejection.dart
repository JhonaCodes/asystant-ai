import 'dart:convert';

import 'package:asystant_core/src/business/business_failure.dart';
import 'package:asystant_core/src/business/business_failure_code.dart';
import 'package:asystant_core/src/business/business_http_request.dart';
import 'package:asystant_core/src/business/business_http_response.dart';
import 'package:asystant_core/src/business/business_redaction.dart';

/// Says why an API refused a request, without leaking what it carried.
extension BusinessHttpRejection on BusinessHttpResponse {
  /// The longest server message quoted, in characters.
  static const int _maxMessage = 160;

  /// The longest body excerpt quoted, in characters.
  static const int _maxExcerpt = 600;

  /// A [BusinessFailureCode.rejected] failure for [request]:
  /// `POST https://host/path answered 422 (the server's short message).`
  ///
  /// With [quotesBody], the redacted body follows, so the model can read a
  /// validation error and correct the call; [privateValues] are redacted
  /// from it. Sign-in failures never quote the body.
  BusinessFailure toRejection(
    BusinessHttpRequest request, {
    bool quotesBody = false,
    Iterable<String> privateValues = const [],
  }) {
    final serverMessage = switch (body.toRedacted(privateValues)) {
      {'message': final String text} when text.length <= _maxMessage =>
        ' ($text)',
      {'error': final String text} when text.length <= _maxMessage =>
        ' ($text)',
      _ => '',
    };
    final excerpt = quotesBody && body != null
        ? ' Body: ${jsonEncode(body.toRedacted(privateValues))}'
        : '';
    return BusinessFailure(
      .rejected,
      message:
          '${request.method} ${request.address} answered $statusCode'
          '$serverMessage.'
          '${excerpt.length > _maxExcerpt ? '${excerpt.substring(0, _maxExcerpt)}…' : excerpt}',
      statusCode: statusCode,
      address: request.address,
    );
  }
}

import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/business/business_failure.dart';
import 'package:asystant_core/src/business/business_http_request.dart';
import 'package:asystant_core/src/business/business_http_response.dart';

/// Sends the requests of business sign-ins and operations. The host injects
/// it; `BusinessHttpClient` is the default over `package:http`, and a test
/// passes a fake one.
abstract interface class BusinessHttp {
  /// Sends [request] without following redirects. Any HTTP status is an
  /// `Ok`: the caller decides what an error status means. Only a request
  /// that got no answer (no connection, timeout) is an `Err`, with
  /// `BusinessFailureCode.unreachable`.
  Future<Result<BusinessHttpResponse, BusinessFailure>> send(
    BusinessHttpRequest request,
  );
}

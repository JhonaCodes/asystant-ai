import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/business/business_failure.dart';
import 'package:asystant_core/src/business/business_http.dart';
import 'package:asystant_core/src/business/business_http_request.dart';
import 'package:asystant_core/src/business/business_http_response.dart';

/// [BusinessHttp] over `package:http`: JSON bodies, no redirects and a
/// [timeout] per request.
class BusinessHttpClient implements BusinessHttp {
  BusinessHttpClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// How long one request may take, connection and answer included.
  final Duration timeout;

  @override
  Future<Result<BusinessHttpResponse, BusinessFailure>> send(
    BusinessHttpRequest request,
  ) async {
    final outgoing = http.Request(request.method, request.uri)
      ..followRedirects = false
      ..headers.addAll(request.headers);
    if (request.body case final Object body) {
      outgoing
        ..headers.putIfAbsent('Content-Type', () => 'application/json')
        ..body = jsonEncode(body);
    }
    try {
      final streamed = await _client.send(outgoing).timeout(timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(timeout);
      return Ok(
        BusinessHttpResponse(
          statusCode: response.statusCode,
          body: _decode(response.body),
        ),
      );
    } on TimeoutException {
      return Err(
        BusinessFailure(
          .unreachable,
          message: '${request.uri.host} did not answer in time.',
          address: request.address,
        ),
      );
    } on http.ClientException {
      return Err(
        BusinessFailure(
          .unreachable,
          message:
              'No connection with ${request.uri.host}. Check the base URL of '
              'the environment.',
          address: request.address,
        ),
      );
    }
  }

  /// Closes the underlying client; no request can be sent afterwards.
  void close() => _client.close();

  static Object? _decode(String text) {
    if (text.trim().isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }
}

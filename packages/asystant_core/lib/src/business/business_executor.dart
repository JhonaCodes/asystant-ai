import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/business/business_auth_scheme.dart';
import 'package:asystant_core/src/business/business_contract.dart';
import 'package:asystant_core/src/business/business_credential_scope.dart';
import 'package:asystant_core/src/business/business_credential_store.dart';
import 'package:asystant_core/src/business/business_endpoint.dart';
import 'package:asystant_core/src/business/business_failure.dart';
import 'package:asystant_core/src/business/business_failure_code.dart';
import 'package:asystant_core/src/business/business_http.dart';
import 'package:asystant_core/src/business/business_http_rejection.dart';
import 'package:asystant_core/src/business/business_http_request.dart';
import 'package:asystant_core/src/business/business_http_response.dart';
import 'package:asystant_core/src/business/business_operation.dart';
import 'package:asystant_core/src/business/business_operation_arguments.dart';
import 'package:asystant_core/src/business/business_operation_response.dart';
import 'package:asystant_core/src/business/business_private_headers.dart';
import 'package:asystant_core/src/business/business_redaction.dart';
import 'package:asystant_core/src/business/business_sign_in.dart';

/// Runs a registered operation against one explicitly chosen environment
/// and credential profile.
///
/// It validates the arguments against the contract, builds the request
/// (path, query, body and headers, including the saved credential and the
/// private headers), and redacts every secret from the answer before
/// anyone reads it. A 401 renews the session once through
/// [BusinessSignIn.refresh] and retries; when renewal is impossible or
/// rejected, the session is cleared and the failure says to sign in again.
class BusinessExecutor {
  BusinessExecutor({
    required BusinessHttp http,
    required BusinessCredentialStore store,
    BusinessSignIn? signIn,
  }) : _http = http,
       _store = store,
       _signIn = signIn ?? BusinessSignIn(http: http, store: store);

  final BusinessHttp _http;
  final BusinessCredentialStore _store;
  final BusinessSignIn _signIn;

  /// Runs [operationId] of [contract] for [scope] with [arguments].
  ///
  /// Pass [idempotencyKey] (such as `ToolContext.idempotencyKey`) so a
  /// retried write is not applied twice; it is sent as `Idempotency-Key`
  /// on every method but `GET`. Secret fields go in [arguments] like any
  /// other, typed by the person, never by the model.
  Future<Result<BusinessOperationResponse, BusinessFailure>> execute({
    required BusinessContract contract,
    required BusinessCredentialScope scope,
    required String operationId,
    Map<String, Object?> arguments = const {},
    String? idempotencyKey,
  }) async {
    final label = scope.environment.name.toUpperCase();
    final endpoint = contract.endpoint(scope.environment);
    final operation = contract.operation(operationId);
    if (scope.businessId != contract.id ||
        endpoint == null ||
        endpoint.profile(scope.profile) == null ||
        operation == null) {
      return Err(
        BusinessFailure(
          .notConfigured,
          message:
              '${contract.name} has no $label environment, profile '
              '${scope.profile} or operation $operationId.',
        ),
      );
    }
    final checked = operation.validateArguments(arguments);
    if (checked.errorOrNull case final failure?) return Err(failure);
    final credential = await _store.readCredential(scope);
    if (credential.errorOrNull case final failure?) return Err(failure);
    final token = credential.data;
    if (token == null || token.isEmpty) {
      return Err(
        BusinessFailure(
          .noSession,
          message: 'There is no saved session for ${contract.name} $label.',
        ),
      );
    }
    final endpointHeaders = await _store.readPrivateHeaders(
      scope,
      endpoint.privateHeaders,
    );
    if (endpointHeaders.errorOrNull case final failure?) return Err(failure);
    final operationHeaders = await _store.readPrivateHeaders(
      scope,
      operation.privateHeaders,
    );
    if (operationHeaders.errorOrNull case final failure?) return Err(failure);
    final privateHeaders = {...endpointHeaders.data, ...operationHeaders.data};
    final privateValues = [
      token,
      ...privateHeaders.values,
      for (final name in operation.secretFieldNames)
        if (arguments[name] case final String value) value,
    ];
    BusinessHttpRequest requestWith(String credential) => _request(
      endpoint: endpoint,
      operation: operation,
      arguments: arguments,
      credential: credential,
      endpointHeaders: endpointHeaders.data,
      operationHeaders: operationHeaders.data,
      idempotencyKey: idempotencyKey,
    );
    final request = requestWith(token);
    final sent = await _http.send(request);
    if (sent.errorOrNull case final failure?) return Err(failure);
    if (sent.data.statusCode != 401) {
      return _answer(request, sent.data, privateValues);
    }
    final renewed = await _renew(endpoint, scope);
    if (renewed.errorOrNull case final failure?) return Err(failure);
    final retry = requestWith(renewed.data);
    final resent = await _http.send(retry);
    if (resent.errorOrNull case final failure?) return Err(failure);
    if (resent.data.statusCode == 401) return _expire(scope);
    return _answer(retry, resent.data, [...privateValues, renewed.data]);
  }

  /// The renewed credential, or the failure that ends the session.
  Future<Result<String, BusinessFailure>> _renew(
    BusinessEndpoint endpoint,
    BusinessCredentialScope scope,
  ) async {
    final renewed = await _signIn.refresh(endpoint: endpoint, scope: scope);
    if (renewed.errorOrNull case final failure?) {
      return failure.code == BusinessFailureCode.sessionExpired
          ? _expire(scope)
          : Err(
              failure.copyWith(
                message: 'The session could not be renewed: ${failure.message}',
              ),
            );
    }
    final token = renewed.data;
    if (token == null || token.isEmpty) return _expire(scope);
    return Ok(token);
  }

  /// Clears the session of [scope] and says to sign in again.
  Future<Result<T, BusinessFailure>> _expire<T>(
    BusinessCredentialScope scope,
  ) async {
    // The expired session is what the person must act on; a failed clear
    // only leaves a credential the API already refuses.
    await _store.clearSession(scope);
    return Err(
      const BusinessFailure(
        .sessionExpired,
        message: 'The session expired. Sign in to this environment again.',
        statusCode: 401,
      ),
    );
  }

  static Result<BusinessOperationResponse, BusinessFailure> _answer(
    BusinessHttpRequest request,
    BusinessHttpResponse response,
    List<String> privateValues,
  ) => response.isSuccess
      ? Ok(
          BusinessOperationResponse(
            statusCode: response.statusCode,
            body: response.body.toRedacted(privateValues),
          ),
        )
      : Err(
          response.toRejection(
            request,
            quotesBody: true,
            privateValues: privateValues,
          ),
        );

  static BusinessHttpRequest _request({
    required BusinessEndpoint endpoint,
    required BusinessOperation operation,
    required Map<String, Object?> arguments,
    required String credential,
    required Map<String, String> endpointHeaders,
    required Map<String, String> operationHeaders,
    required String? idempotencyKey,
  }) {
    var path = operation.path;
    final query = <String, Object>{};
    final body = <String, Object?>{};
    final argumentHeaders = <String, String>{};
    for (final field in operation.fields) {
      final value = arguments[field.name];
      if (value == null) continue;
      switch (field.location) {
        case .path:
          path = path.replaceAll(
            '{${field.name}}',
            Uri.encodeComponent('$value'),
          );
        case .query:
          query[field.name] = switch (value) {
            final List<Object?> values => [
              for (final entry in values) '$entry',
            ],
            _ => '$value',
          };
        case .body:
          body[field.name] = value;
        case .header:
          argumentHeaders[field.name] = '$value';
      }
    }
    final auth = endpoint.auth;
    final headers = <String, String>{
      'Accept': 'application/json',
      if (!operation.isRead) 'Idempotency-Key': ?idempotencyKey,
      ...switch (auth.scheme) {
        BusinessAuthScheme.bearer => {'Authorization': 'Bearer $credential'},
        BusinessAuthScheme.apiKey => {auth.apiKeyHeader: credential},
      },
    };
    for (final layer in [
      endpoint.headers,
      endpointHeaders,
      operation.headers,
      operationHeaders,
      argumentHeaders,
    ]) {
      for (final MapEntry(key: name, :value) in layer.entries) {
        headers
          ..removeWhere((key, _) => key.toLowerCase() == name.toLowerCase())
          ..[name] = value;
      }
    }
    final base = endpoint.baseUrl.endsWith('/')
        ? endpoint.baseUrl.substring(0, endpoint.baseUrl.length - 1)
        : endpoint.baseUrl;
    final uri = Uri.parse('$base$path');
    return BusinessHttpRequest(
      method: operation.method,
      uri: query.isEmpty ? uri : uri.replace(queryParameters: query),
      headers: headers,
      body: body.isEmpty ? null : body,
    );
  }
}

import 'package:collection/collection.dart';
import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/business/business_auth_flow.dart';
import 'package:asystant_core/src/business/business_auth_input.dart';
import 'package:asystant_core/src/business/business_auth_input_kind.dart';
import 'package:asystant_core/src/business/business_auth_step.dart';
import 'package:asystant_core/src/business/business_auth_step_kind.dart';
import 'package:asystant_core/src/business/business_credential_scope.dart';
import 'package:asystant_core/src/business/business_credential_store.dart';
import 'package:asystant_core/src/business/business_endpoint.dart';
import 'package:asystant_core/src/business/business_failure.dart';
import 'package:asystant_core/src/business/business_failure_code.dart';
import 'package:asystant_core/src/business/business_http.dart';
import 'package:asystant_core/src/business/business_http_rejection.dart';
import 'package:asystant_core/src/business/business_http_request.dart';
import 'package:asystant_core/src/business/business_json_path.dart';
import 'package:asystant_core/src/business/business_private_headers.dart';
import 'package:asystant_core/src/business/business_sign_in_outcome.dart';
import 'package:asystant_core/src/business/business_sign_in_request.dart';
import 'package:asystant_core/src/business/business_totp_enrollment.dart';

/// Runs the [BusinessAuthFlow] of an environment: asks the person for each
/// step's values through a [BusinessSignInPrompter], posts the steps in
/// order and saves the session in the [BusinessCredentialStore]. It also
/// renews a session with the flow's refresh step.
///
/// Codes and passwords live only in memory for the sign-in that asked for
/// them. Share one instance per app: [refresh] runs once at a time per
/// scope, and concurrent callers wait for the same renewal.
class BusinessSignIn {
  BusinessSignIn({
    required BusinessHttp http,
    required BusinessCredentialStore store,
  }) : _http = http,
       _store = store;

  final BusinessHttp _http;
  final BusinessCredentialStore _store;

  final Map<BusinessCredentialScope, Future<Result<String?, BusinessFailure>>>
  _refreshing = {};

  /// Signs [scope] in to [endpoint], asking the person through [prompter].
  ///
  /// [email] pre-fills the email input; when empty, the last email of the
  /// scope does. The first form also carries the flow's parameters for the
  /// person to confirm; the outcome returns them so the host can keep a
  /// correction.
  Future<Result<BusinessSignInOutcome, BusinessFailure>> signIn({
    required BusinessEndpoint endpoint,
    required BusinessCredentialScope scope,
    required BusinessSignInPrompter prompter,
    String email = '',
  }) async {
    final flow = endpoint.auth;
    final steps = flow.signInSteps;
    if (steps.isEmpty) {
      return Err(
        const BusinessFailure(
          .notConfigured,
          message:
              'This environment has no sign-in steps: its credential is '
              'configured directly.',
        ),
      );
    }
    final headers = await _headers(endpoint, scope);
    if (headers.errorOrNull case final failure?) return Err(failure);
    final suggestedEmail = email.trim().isNotEmpty
        ? email.trim()
        : await _lastEmail(scope);
    final values = <String, String>{};
    var parameters = flow.parameters;
    Object? previousAnswer;
    BusinessAuthStepKind? previousStep;
    for (final (index, step) in steps.indexed) {
      // What the step carries from the previous answer is checked before
      // the person is asked for anything this step needs.
      final carried = _carried(step, previousAnswer);
      if (carried.errorOrNull case final failure?) return Err(failure);
      final asked = await _ask(
        step: step,
        flow: flow,
        values: values,
        parameters: index == 0 ? parameters : const {},
        suggestedEmail: suggestedEmail,
        previousStep: previousStep,
        enrollment: _enrollment(flow, previousAnswer),
        prompter: prompter,
      );
      if (asked.errorOrNull case final failure?) return Err(failure);
      if (index == 0) parameters = {...parameters, ...asked.data};
      final request = _post(flow, endpoint, step.path, headers.data, {
        if (step.sendsParameters) ...parameters,
        for (final input in step.inputs) input.field: values[input.name],
        ...carried.data,
      });
      final sent = await _http.send(request);
      if (sent.errorOrNull case final failure?) return Err(failure);
      final response = sent.data;
      final answer = response.body.withoutDataEnvelope;
      final next = steps.elementAtOrNull(index + 1);
      if (!response.isSuccess &&
          !_isChallenge(next, answer, response.statusCode)) {
        return Err(response.toRejection(request));
      }
      final token = answer.textAtPath(flow.tokenPath);
      final continues =
          step.continueFlag.isNotEmpty &&
          answer.valueAtPath(step.continueFlag) == true;
      final completes =
          next == null ||
          (step.completesWithToken && token != null && !continues);
      if (completes) {
        return _complete(
          flow: flow,
          scope: scope,
          answer: answer,
          token: token,
          email: _typedEmail(flow, values),
          parameters: parameters,
        );
      }
      previousAnswer = answer;
      previousStep = step.kind;
    }
    return Err(
      const BusinessFailure(
        .unexpectedResponse,
        message: 'The sign-in ended without a token.',
      ),
    );
  }

  /// Renews the session of [scope] with the flow's refresh step and answers
  /// the new credential.
  ///
  /// `Ok(null)` when it cannot be renewed (no refresh step, or no refresh
  /// token saved); an `Err` with [BusinessFailureCode.sessionExpired] when
  /// the API rejects the renewal with 401 or 403. Concurrent calls for the
  /// same scope share one request.
  Future<Result<String?, BusinessFailure>> refresh({
    required BusinessEndpoint endpoint,
    required BusinessCredentialScope scope,
  }) {
    final running = _refreshing[scope];
    if (running != null) return running;
    final next = _refresh(endpoint, scope);
    _refreshing[scope] = next;
    return next.whenComplete(() {
      if (identical(_refreshing[scope], next)) _refreshing.remove(scope);
    });
  }

  Future<Result<String?, BusinessFailure>> _refresh(
    BusinessEndpoint endpoint,
    BusinessCredentialScope scope,
  ) async {
    final flow = endpoint.auth;
    final step = flow.refreshStep;
    if (step == null) return Ok(null);
    final refreshToken = await _store.readSessionValue(scope, .refreshToken);
    if (refreshToken.errorOrNull case final failure?) return Err(failure);
    final token = refreshToken.data;
    if (token == null || token.isEmpty) return Ok(null);
    final sessionId = await _store.readSessionValue(scope, .sessionId);
    if (sessionId.errorOrNull case final failure?) return Err(failure);
    final headers = await _headers(endpoint, scope);
    if (headers.errorOrNull case final failure?) return Err(failure);
    final request = _post(flow, endpoint, step.path, headers.data, {
      if (step.sendsParameters) ...flow.parameters,
      flow.refreshTokenField: token,
      if (sessionId.data case final id? when id.isNotEmpty)
        flow.sessionIdField: id,
    });
    final sent = await _http.send(request);
    if (sent.errorOrNull case final failure?) return Err(failure);
    final response = sent.data;
    if (response.statusCode == 401 || response.statusCode == 403) {
      return Err(
        BusinessFailure(
          .sessionExpired,
          message: 'The session expired. Sign in to this environment again.',
          statusCode: response.statusCode,
          address: request.address,
        ),
      );
    }
    if (!response.isSuccess) return Err(response.toRejection(request));
    final answer = response.body.withoutDataEnvelope;
    final renewed = answer.textAtPath(flow.tokenPath);
    if (renewed == null) {
      return Err(
        BusinessFailure(
          .unexpectedResponse,
          message: 'The renewal did not return ${flow.tokenPath}.',
          address: request.address,
        ),
      );
    }
    final saved = await _saveSession(
      flow,
      scope,
      answer,
      renewed,
      checksRole: false,
    );
    if (saved.errorOrNull case final failure?) return Err(failure);
    return Ok(renewed);
  }

  /// Asks for what [step] needs that is not known yet, and for the
  /// [parameters] on the first form. Records the typed values in [values]
  /// and answers the confirmed parameters.
  Future<Result<Map<String, String>, BusinessFailure>> _ask({
    required BusinessAuthStep step,
    required BusinessAuthFlow flow,
    required Map<String, String> values,
    required Map<String, String> parameters,
    required String suggestedEmail,
    required BusinessAuthStepKind? previousStep,
    required BusinessTotpEnrollment? enrollment,
    required BusinessSignInPrompter prompter,
  }) async {
    final pending = <BusinessAuthInput>[
      for (final input in step.inputs)
        if (!values.containsKey(input.name)) input,
    ];
    if (pending.isEmpty && parameters.isEmpty) return Ok(const {});
    final answer = await prompter(
      BusinessSignInRequest(
        step: step.kind,
        inputs: pending,
        parameters: parameters,
        requiredParameters: parameters.isEmpty
            ? const []
            : flow.requiredParameters,
        initialValues: {
          for (final input in pending)
            if (input.kind == BusinessAuthInputKind.email &&
                suggestedEmail.isNotEmpty)
              input.name: suggestedEmail,
        },
        previousStep: previousStep,
        enrollment: enrollment,
      ),
    );
    if (answer == null) {
      return Err(
        const BusinessFailure(.canceled, message: 'The sign-in was canceled.'),
      );
    }
    for (final input in pending) {
      final typed = answer[input.name] ?? '';
      final value = input.kind == BusinessAuthInputKind.password
          ? typed
          : typed.trim();
      if (value.isEmpty) {
        return Err(
          BusinessFailure(.invalidInput, message: 'Enter the ${input.name}.'),
        );
      }
      values[input.name] = value;
    }
    final confirmed = {
      for (final MapEntry(key: name, :value) in parameters.entries)
        name: answer[BusinessSignInRequest.parameterKey(name)]?.trim() ?? value,
    };
    final missing = flow.requiredParameters.where(
      (name) => parameters.containsKey(name) && (confirmed[name] ?? '').isEmpty,
    );
    if (missing.isNotEmpty) {
      return Err(
        BusinessFailure(
          .invalidInput,
          message: 'Enter the sign-in parameters ${missing.join(', ')}.',
        ),
      );
    }
    return Ok(confirmed);
  }

  /// The values [step] carries from [previousAnswer], by body member.
  static Result<Map<String, Object?>, BusinessFailure> _carried(
    BusinessAuthStep step,
    Object? previousAnswer,
  ) {
    final carried = <String, Object?>{};
    for (final MapEntry(key: member, value: path) in step.carry.entries) {
      final value = previousAnswer.valueAtPath(path);
      if (value == null) {
        return Err(
          BusinessFailure(
            .unexpectedResponse,
            message: 'The API did not return $path for the next sign-in step.',
          ),
        );
      }
      carried[member] = value;
    }
    return Ok(carried);
  }

  /// A 4xx answer that carries every value the [next] step needs is a
  /// second-factor challenge, not a rejection.
  static bool _isChallenge(
    BusinessAuthStep? next,
    Object? answer,
    int statusCode,
  ) =>
      next != null &&
      statusCode < 500 &&
      next.carry.isNotEmpty &&
      next.carry.values.every((path) => answer.valueAtPath(path) != null);

  Future<Result<BusinessSignInOutcome, BusinessFailure>> _complete({
    required BusinessAuthFlow flow,
    required BusinessCredentialScope scope,
    required Object? answer,
    required String? token,
    required String email,
    required Map<String, String> parameters,
  }) async {
    if (token == null) {
      return Err(
        BusinessFailure(
          .unexpectedResponse,
          message: 'The API did not return ${flow.tokenPath}.',
        ),
      );
    }
    final saved = await _saveSession(
      flow,
      scope,
      answer,
      token,
      checksRole: true,
    );
    if (saved.errorOrNull case final failure?) return Err(failure);
    if (email.isNotEmpty) {
      // Only pre-fills the next sign-in: a failed write does not undo the
      // session just saved, so it does not fail the sign-in.
      await _store.writeLastEmail(scope, email);
    }
    return Ok(
      BusinessSignInOutcome(
        email: email,
        parameters: parameters,
        hasChangedParameters: !const MapEquality<String, String>().equals(
          parameters,
          flow.parameters,
        ),
      ),
    );
  }

  Future<Result<void, BusinessFailure>> _saveSession(
    BusinessAuthFlow flow,
    BusinessCredentialScope scope,
    Object? answer,
    String token, {
    required bool checksRole,
  }) async {
    if (checksRole &&
        flow.requiredRole.isNotEmpty &&
        '${answer.valueAtPath(flow.rolePath)}'.toLowerCase() !=
            flow.requiredRole.toLowerCase()) {
      return Err(
        const BusinessFailure(
          .rejected,
          message: 'This account does not have the required role.',
        ),
      );
    }
    final written = await _store.writeCredential(scope, token);
    if (written.errorOrNull case final failure?) return Err(failure);
    if (flow.refreshStep == null) return Ok(null);
    final refreshToken =
        answer.textAtPath(flow.refreshTokenField) ??
        (flow.reusesTokenForRefresh ? token : null);
    if (refreshToken != null) {
      final kept = await _store.writeSessionValue(
        scope,
        .refreshToken,
        refreshToken,
      );
      if (kept.errorOrNull case final failure?) return Err(failure);
    }
    if (answer.textAtPath(flow.sessionIdPath) case final sessionId?) {
      final kept = await _store.writeSessionValue(scope, .sessionId, sessionId);
      if (kept.errorOrNull case final failure?) return Err(failure);
    }
    return Ok(null);
  }

  Future<String> _lastEmail(BusinessCredentialScope scope) async =>
      (await _store.readLastEmail(scope)).when(
        ok: (email) => email ?? '',
        // A missing pre-fill only means the person types the email.
        err: (_) => '',
      );

  Future<Result<Map<String, String>, BusinessFailure>> _headers(
    BusinessEndpoint endpoint,
    BusinessCredentialScope scope,
  ) async =>
      (await _store.readPrivateHeaders(scope, endpoint.privateHeaders)).map(
        (private) => {
          'Accept': 'application/json',
          ...endpoint.headers,
          ...endpoint.auth.headers,
          ...private,
        },
      );

  static BusinessHttpRequest _post(
    BusinessAuthFlow flow,
    BusinessEndpoint endpoint,
    String path,
    Map<String, String> headers,
    Map<String, Object?> body,
  ) {
    final address = flow.baseUrl.isEmpty ? endpoint.baseUrl : flow.baseUrl;
    final base = address.endsWith('/')
        ? address.substring(0, address.length - 1)
        : address;
    return BusinessHttpRequest(
      method: 'POST',
      uri: Uri.parse('$base$path'),
      headers: headers,
      body: body,
    );
  }

  static BusinessTotpEnrollment? _enrollment(
    BusinessAuthFlow flow,
    Object? answer,
  ) => switch (answer.textAtPath(flow.enrollmentUriPath)) {
    final String uri => BusinessTotpEnrollment(
      uri: uri,
      secret: answer.textAtPath(flow.enrollmentSecretPath) ?? '',
    ),
    null => null,
  };

  /// The value typed in the flow's first email input, or empty.
  static String _typedEmail(BusinessAuthFlow flow, Map<String, String> values) {
    final input = flow.inputs.firstWhereOrNull(
      (input) => input.kind == BusinessAuthInputKind.email,
    );
    return input == null ? '' : values[input.name] ?? '';
  }
}

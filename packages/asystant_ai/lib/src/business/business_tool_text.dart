import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/business/business_tool_names.dart';

/// `DEV` and `PROD`, as the tools and the model name the environments.
extension BusinessEnvironmentLabel on BusinessEnvironment {
  String toLabel() => name.toUpperCase();
}

/// Reads `DEV` or `PROD` (any case) from a tool argument.
extension BusinessEnvironmentParsing on String {
  BusinessEnvironment? toBusinessEnvironment() => switch (toUpperCase()) {
    'DEV' => BusinessEnvironment.dev,
    'PROD' => BusinessEnvironment.prod,
    _ => null,
  };
}

/// A [BusinessFailure] as the failure of a tool call, whose detail the
/// model reads to correct itself.
extension BusinessFailureForTools on BusinessFailure {
  /// [hint] is appended to the message: what the model should do next.
  AssistantFailure toAssistantFailure({String hint = ''}) =>
      AssistantFailure(switch (code) {
        .invalidContract ||
        .invalidInput ||
        .notConfigured ||
        .missingPrivateHeader => FailureCode.invalidTool,
        .noSession || .sessionExpired => FailureCode.authentication,
        .rejected || .unexpectedResponse || .storage => FailureCode.toolFailed,
        .unreachable => FailureCode.network,
        .canceled => FailureCode.canceled,
      }, detail: [message, if (hint.isNotEmpty) hint].join(' '));
}

/// How an environment signs in, said for the model: what the sign-in tool
/// will do. Parameter names only; their values never reach the model.
extension BusinessSignInSummary on BusinessEndpoint {
  String toSignInSummary(BusinessToolNames names) {
    final flow = auth;
    if (!flow.signsIn) {
      return switch (flow.scheme) {
        .bearer =>
          'Bearer token configured on the device with '
              '${names.configureEnvironment}; no sign-in step',
        .apiKey =>
          'API key (${flow.apiKeyHeader}) configured on the device with '
              '${names.configureEnvironment}; no sign-in step',
      };
    }
    final steps = flow.signInSteps.map((step) => step.kind.name).join(' → ');
    final inputs = flow.inputs.map((input) => input.name).join(', ');
    return [
      '${names.connect} runs $steps; the person types $inputs in secure '
          'forms',
      if (flow.parameters.isNotEmpty)
        'parameters ${flow.parameters.keys.join(', ')} are configured',
      if (flow.refreshStep != null) 'the session renews itself',
      if (profiles.isNotEmpty)
        'profiles ${profiles.map((profile) => profile.id).join(', ')}',
    ].join('; ');
  }
}

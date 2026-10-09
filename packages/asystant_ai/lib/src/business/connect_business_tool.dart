import 'dart:convert';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/business/business_call_target.dart';
import 'package:asystant_ai/src/business/business_tool_text.dart';
import 'package:asystant_ai/src/business/business_toolkit.dart';
import 'package:asystant_ai/src/model/asystant_action_policy.dart';

/// Signs in to one environment and profile of a registered business by
/// running its sign-in flow: every value the person types (email,
/// password, codes, sign-in parameters, missing private headers) goes
/// through secure forms in the chat and never reaches the model.
///
/// Because it uses private input, the chat withholds its outcome from the
/// model; that is why operations run in a separate tool.
class ConnectBusinessTool extends TypedAsystantTool<BusinessCallTarget>
    implements AsystantActionPolicyProvider {
  const ConnectBusinessTool(this.toolkit);

  final BusinessToolkit toolkit;

  @override
  ToolDefinition get definition => ToolDefinition(
    name: toolkit.names.connect,
    description:
        "Starts or renews a business session with that business's own "
        'sign-in. Omit environment and email when they resolve on their own '
        '(one environment configured or with a session, and the last email '
        'used). The device opens secure forms for the email, the sign-in '
        'parameters (such as company_id and application_id, pre-filled), '
        'the password, the email code and the authenticator code; never ask '
        'for them in chat.',
    fields: const [
      ToolField(name: 'business', description: 'Business id.', kind: .string),
      ToolField(
        name: 'environment',
        description: 'DEV or PROD; omit it to resolve it when possible.',
        kind: .string,
        options: ['DEV', 'PROD'],
        isRequired: false,
      ),
      ToolField(
        name: 'profile',
        description:
            'Credential profile, such as admin or guest; omit it for the '
            'first one.',
        kind: .string,
        isRequired: false,
      ),
      ToolField(
        name: 'email',
        description:
            'Email to sign in with; omit it to reuse the last one for that '
            'environment and profile.',
        kind: .string,
        isRequired: false,
      ),
    ],
  );

  @override
  bool get requiresConfirmation => false;

  @override
  AsystantActionPolicy actionPolicy(ToolArguments arguments) =>
      const AsystantActionPolicy(level: .low, allowSessionApproval: false);

  @override
  Result<BusinessCallTarget, AssistantFailure> decode(ToolArguments arguments) {
    final input = arguments.toJson();
    final business = toolkit.business('${input['business']}');
    final environment = input['environment'];
    final email = input['email'];
    if (business == null ||
        (environment is String &&
            environment.toBusinessEnvironment() == null) ||
        (email is String && email.trim().isEmpty)) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail:
              'Pass a registered business and, optionally, DEV or PROD, a '
              'profile and an email.',
        ),
      );
    }
    return Ok(
      BusinessCallTarget(
        business: business,
        environment: environment as String?,
        profile: input['profile'] as String?,
        email: (email as String?)?.trim() ?? '',
      ),
    );
  }

  @override
  Future<Result<AssistantCard, AssistantFailure>> previewInput(
    BusinessCallTarget input,
  ) async {
    final account = toolkit.requireAccount();
    if (account.errorOrNull case final failure?) return Err(failure);
    final environment = await toolkit.resolveEnvironment(
      account.data,
      input.business,
      label: input.environment,
      profile: input.profile,
    );
    if (environment.errorOrNull case final failure?) return Err(failure);
    return Ok(
      AssistantCard(
        title: toolkit.strings.businessConnectTitle(input.business.name),
        body: [
          [
            environment.data.toLabel(),
            ?input.profile,
            if (input.email.isNotEmpty) input.email,
          ].join(' · '),
          toolkit.strings.businessConnectNote,
        ].join('\n'),
        kind: .summary,
      ),
    );
  }

  @override
  Future<Result<ToolOutcome, AssistantFailure>> executeInput(
    BusinessCallTarget input,
    ToolContext context,
  ) async {
    context.checkCanceled();
    final account = toolkit.requireAccount();
    if (account.errorOrNull case final failure?) return Err(failure);
    if (!context.supportsPrivateInput) {
      return Err(
        const AssistantFailure(
          .unavailable,
          detail: 'This chat cannot open secure forms to sign in.',
        ),
      );
    }
    final business = input.business;
    final environment = await toolkit.resolveEnvironment(
      account.data,
      business,
      label: input.environment,
      profile: input.profile,
    );
    if (environment.errorOrNull case final failure?) return Err(failure);
    final endpoint = business.endpoint(environment.data);
    if (endpoint == null) {
      return Err(const AssistantFailure(.invalidTool, detail: 'No endpoint.'));
    }
    if (!endpoint.auth.signsIn) {
      return Err(
        AssistantFailure(
          .invalidTool,
          detail:
              '${environment.data.toLabel()} uses an API key or Bearer token '
              'saved with ${toolkit.names.configureEnvironment}; there is no '
              'sign-in to run.',
        ),
      );
    }
    final profile = toolkit.resolveProfile(business, endpoint, input.profile);
    if (profile.errorOrNull case final failure?) return Err(failure);
    final scope = toolkit.scope(
      account.data,
      business,
      environment.data,
      profile.data,
    );
    final place = _place(business, environment.data, endpoint, profile.data);
    final headers = await _enterMissingHeaders(endpoint, scope, place, context);
    if (headers.errorOrNull case final failure?) return Err(failure);
    var typedEmail = input.email;
    final signedIn = await toolkit.signIn.signIn(
      endpoint: endpoint,
      scope: scope,
      email: input.email,
      prompter: (request) async {
        final answer = await _prompt(
          request,
          business,
          endpoint,
          place,
          typedEmail,
          context,
        );
        for (final field in request.inputs) {
          if (field.kind == BusinessAuthInputKind.email) {
            typedEmail = answer?[field.name]?.trim() ?? typedEmail;
          }
        }
        return answer;
      },
    );
    if (signedIn.errorOrNull case final failure?) {
      return Err(failure.toAssistantFailure());
    }
    final outcome = signedIn.data;
    final parametersSaved =
        !outcome.hasChangedParameters ||
        (await toolkit.saveContract(
          account.data,
          business.withEndpoint(
            environment.data,
            endpoint.copyWith(
              auth: endpoint.auth.copyWith(parameters: outcome.parameters),
            ),
          ),
          signedIn: environment.data,
        )).isOk;
    return Ok(
      ToolOutcome(
        modelContent: jsonEncode({
          'business': business.id,
          'environment': environment.data.toLabel(),
          'profile': profile.data,
          'connected': true,
          if (outcome.hasChangedParameters) 'parameters_saved': parametersSaved,
        }),
        summary: toolkit.strings.businessSignedIn(place),
      ),
    );
  }

  /// `Business · DEV`, plus the profile when the environment declares any.
  String _place(
    BusinessContract business,
    BusinessEnvironment environment,
    BusinessEndpoint endpoint,
    String profile,
  ) => [
    business.name,
    environment.toLabel(),
    if (endpoint.profiles.isNotEmpty)
      switch (endpoint.profile(profile)) {
        final BusinessCredentialProfile declared
            when declared.label.isNotEmpty =>
          declared.label,
        _ => profile,
      },
  ].join(' · ');

  /// Asks for the private headers the sign-in needs that have no value yet.
  Future<Result<void, AssistantFailure>> _enterMissingHeaders(
    BusinessEndpoint endpoint,
    BusinessCredentialScope scope,
    String place,
    ToolContext context,
  ) async {
    final missing = await toolkit.credentialStore.missingPrivateHeaders(
      scope,
      endpoint.privateHeaders,
    );
    if (missing.errorOrNull case final failure?) {
      return Err(failure.toAssistantFailure());
    }
    if (missing.data.isEmpty) return Ok(null);
    final values = await context.requestPrivateInput(
      toolkit.strings.businessPrivateHeadersTitle(place),
      [
        for (final name in missing.data)
          PrivateInputField(name: name, label: name),
      ],
    );
    if (values == null) return Err(const AssistantFailure(.canceled));
    for (final name in missing.data) {
      context.checkCanceled();
      final written = await toolkit.credentialStore.writePrivateHeader(
        scope,
        name,
        values[name] ?? '',
      );
      if (written.errorOrNull case final failure?) {
        return Err(failure.toAssistantFailure());
      }
    }
    return Ok(null);
  }

  /// One secure form for [request]: its inputs and, on the first one, the
  /// sign-in parameters pre-filled with the saved values.
  Future<Map<String, String>?> _prompt(
    BusinessSignInRequest request,
    BusinessContract business,
    BusinessEndpoint endpoint,
    String place,
    String email,
    ToolContext context,
  ) async {
    final strings = toolkit.strings;
    if (request.enrollment case final enrollment?) {
      if (toolkit.onTotpEnrollment case final enroll?) {
        if (!await enroll(enrollment)) return null;
      }
    }
    final parameters = endpoint.auth.parameters.keys
        .map((name) => strings.businessParameterLabel(name, isRequired: true))
        .join(', ');
    final title = switch (request) {
      BusinessSignInRequest(previousStep: BusinessAuthStepKind.request) => [
        strings.businessCodeSentTitle(place, email),
        if (parameters.isNotEmpty)
          strings.businessMissingCodeHint(business.name, parameters),
      ].join('\n'),
      BusinessSignInRequest(step: BusinessAuthStepKind.totp) => [
        strings.businessTotpTitle(place),
        if (request.enrollment case final enrollment?
            when toolkit.onTotpEnrollment == null &&
                enrollment.secret.isNotEmpty)
          strings.businessTotpEnrollment(enrollment.secret),
      ].join('\n'),
      _ => place,
    };
    return context.requestPrivateInput(title, [
      for (final input in request.inputs)
        PrivateInputField(
          name: input.name,
          label: input.label.isNotEmpty
              ? input.label
              : strings.businessInputLabel(input.kind),
          kind: switch (input.kind) {
            .email => PrivateInputKind.email,
            .password => PrivateInputKind.password,
            .code => PrivateInputKind.code,
            .totp => PrivateInputKind.totp,
            .text => PrivateInputKind.text,
          },
          initialValue: request.initialValues[input.name],
        ),
      for (final MapEntry(key: name, :value) in request.parameters.entries)
        PrivateInputField(
          name: BusinessSignInRequest.parameterKey(name),
          label: strings.businessParameterLabel(
            name,
            isRequired: request.requiredParameters.contains(name),
          ),
          kind: .text,
          required: request.requiredParameters.contains(name),
          initialValue: value,
        ),
    ]);
  }
}

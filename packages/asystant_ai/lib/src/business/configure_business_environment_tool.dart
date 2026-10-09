import 'dart:convert';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/business/business_environment_change.dart';
import 'package:asystant_ai/src/business/business_tool_text.dart';
import 'package:asystant_ai/src/business/business_toolkit.dart';

/// Saves the API address of one environment and, when the person gave one
/// in the chat as a private value, its API key or Bearer token. The
/// credential goes to the device vault; the model only passes its
/// `[secret:…]` reference. Saving again replaces the value, so it runs
/// without an approval card.
class ConfigureBusinessEnvironmentTool
    extends TypedAsystantTool<BusinessEnvironmentChange> {
  const ConfigureBusinessEnvironmentTool(this.toolkit);

  final BusinessToolkit toolkit;

  static final RegExp _privateReference = RegExp(r'^\[secret:[a-f0-9]{32}\]$');

  @override
  ToolDefinition get definition => ToolDefinition(
    name: toolkit.names.configureEnvironment,
    description:
        'Saves an API base URL and/or an API key or Bearer token that the '
        'person gave in this chat for a registered business. Ask DEV or '
        'PROD when it was not said. Never repeat the key. To change how the '
        'business signs in (email and code, password, TOTP, routes or '
        'parameters) use ${toolkit.names.update}; for passwords and codes '
        'use ${toolkit.names.connect}.',
    fields: const [
      ToolField(
        name: 'business',
        description: 'Exact id of the registered business.',
        kind: .string,
      ),
      ToolField(
        name: 'environment',
        description: 'Environment the person chose.',
        kind: .string,
        options: ['DEV', 'PROD'],
      ),
      ToolField(
        name: 'profile',
        description:
            'Credential profile the key belongs to; omit it for the first '
            'one.',
        kind: .string,
        isRequired: false,
      ),
      ToolField(
        name: 'base_url',
        description:
            'Exact base URL the person gave, or its [secret:…] reference.',
        kind: .string,
        isRequired: false,
        acceptsSecret: true,
      ),
      ToolField(
        name: 'scheme',
        description: 'How the credential is sent.',
        kind: .string,
        options: ['bearer', 'apiKey'],
        isRequired: false,
      ),
      ToolField(
        name: 'api_key_header',
        description: 'Exact name of the API key header.',
        kind: .string,
        isRequired: false,
      ),
      ToolField(
        name: 'credential',
        description:
            'The [secret:…] reference that replaced the API key or token the '
            'person marked as private. Pass it literally; the value is '
            'inserted only when the tool runs.',
        kind: .string,
        isRequired: false,
        acceptsSecret: true,
      ),
    ],
  );

  @override
  bool get requiresConfirmation => false;

  @override
  Result<BusinessEnvironmentChange, AssistantFailure> decode(
    ToolArguments arguments,
  ) {
    final input = arguments.toJson();
    final business = toolkit.business('${input['business']}');
    final environment = '${input['environment']}'.toBusinessEnvironment();
    if (business == null || environment == null) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail: 'Pass a registered business and DEV or PROD.',
        ),
      );
    }
    final values = <String, String>{};
    for (final name in ['base_url', 'scheme', 'api_key_header', 'credential']) {
      final value = input[name];
      if (value == null) continue;
      if (value is! String ||
          value.trim().isEmpty ||
          value.length > 8192 ||
          value.contains('\n') ||
          value.contains('\r')) {
        return Err(
          AssistantFailure(
            .invalidTool,
            detail: '$name must be a single non-empty line.',
          ),
        );
      }
      values[name] = value.trim();
    }
    final change = BusinessEnvironmentChange(
      business: business,
      environment: environment,
      profile: input['profile'] as String?,
      baseUrl: values['base_url'],
      scheme: switch (values['scheme']) {
        'apiKey' => BusinessAuthScheme.apiKey,
        'bearer' => BusinessAuthScheme.bearer,
        _ => null,
      },
      apiKeyHeader: values['api_key_header'],
      credential: values['credential'],
    );
    final problem = _problem(change);
    return problem == null
        ? Ok(change)
        : Err(AssistantFailure(.invalidTool, detail: problem));
  }

  /// What is wrong with [change] for the model to fix, or null.
  String? _problem(BusinessEnvironmentChange change) {
    final current = change.business.endpoint(change.environment);
    final address = change.baseUrl;
    if (address == null &&
        change.scheme == null &&
        change.apiKeyHeader == null &&
        change.credential == null) {
      return 'Pass the URL or the credential to save.';
    }
    if (address != null &&
        !_privateReference.hasMatch(address) &&
        !_isAddress(address, change.environment)) {
      return 'Pass a valid base URL without keys in it; PROD needs https.';
    }
    if (change.apiKeyHeader case final header?
        when !header.isBusinessHeaderName) {
      return 'Pass a valid API key header name.';
    }
    if (current == null && (address == null || change.scheme == null)) {
      return 'A new environment needs base_url and scheme.';
    }
    final scheme = change.scheme ?? current?.auth.scheme;
    if (scheme == BusinessAuthScheme.bearer && change.apiKeyHeader != null) {
      return 'A Bearer token does not use an API key header.';
    }
    if ((current?.auth.signsIn ?? false) &&
        (change.credential != null || change.scheme != null)) {
      return 'This environment signs in with steps: use '
          '${toolkit.names.connect}, or ${toolkit.names.update} to change '
          'its sign-in.';
    }
    if (scheme == BusinessAuthScheme.apiKey &&
        change.apiKeyHeader == null &&
        current?.auth.scheme != BusinessAuthScheme.apiKey) {
      return 'Pass the exact api_key_header.';
    }
    return null;
  }

  static bool _isAddress(String address, BusinessEnvironment environment) {
    final uri = Uri.tryParse(address);
    return uri != null &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        uri.query.isEmpty &&
        uri.fragment.isEmpty &&
        switch (environment) {
          .prod => uri.scheme == 'https',
          .dev => uri.scheme == 'http' || uri.scheme == 'https',
        };
  }

  @override
  Future<Result<AssistantCard, AssistantFailure>> previewInput(
    BusinessEnvironmentChange input,
  ) async {
    final strings = toolkit.strings;
    final current = input.business.endpoint(input.environment);
    final address = switch (input.baseUrl) {
      final String url when _privateReference.hasMatch(url) => '••••',
      final String url => url,
      null => current?.baseUrl ?? strings.businessNotConfigured,
    };
    return Ok(
      AssistantCard(
        title: strings.businessEnvironmentTitle(
          input.business.name,
          input.environment.toLabel(),
        ),
        body: [
          'URL: $address',
          ?input.scheme?.name,
          ?input.apiKeyHeader,
          if (input.credential != null) strings.businessCredentialNote,
          strings.businessSessionResetNote,
        ].join('\n'),
        kind: .summary,
      ),
    );
  }

  @override
  Future<Result<ToolOutcome, AssistantFailure>> executeInput(
    BusinessEnvironmentChange input,
    ToolContext context,
  ) async {
    context.checkCanceled();
    final account = toolkit.requireAccount();
    if (account.errorOrNull case final failure?) return Err(failure);
    final current = input.business.endpoint(input.environment);
    final address = input.baseUrl ?? current?.baseUrl;
    if (address == null) {
      return Err(
        const AssistantFailure(.invalidTool, detail: 'base_url is missing.'),
      );
    }
    final endpoint = (current ?? BusinessEndpoint(baseUrl: address)).copyWith(
      baseUrl: address,
      auth: _auth(input, current?.auth),
    );
    final saved = await toolkit.saveContract(
      account.data,
      input.business.withEndpoint(input.environment, endpoint),
    );
    if (saved.errorOrNull case final failure?) return Err(failure);
    final profile = toolkit.resolveProfile(saved.data, endpoint, input.profile);
    if (profile.errorOrNull case final failure?) return Err(failure);
    if (input.credential case final credential?) {
      context.checkCanceled();
      final isBearer = endpoint.auth.scheme == BusinessAuthScheme.bearer;
      final written = await toolkit.credentialStore.writeCredential(
        toolkit.scope(
          account.data,
          saved.data,
          input.environment,
          profile.data,
        ),
        isBearer && credential.toLowerCase().startsWith('bearer ')
            ? credential.substring(7).trim()
            : credential,
      );
      if (written.errorOrNull case final failure?) {
        return Err(failure.toAssistantFailure());
      }
    }
    final place = '${saved.data.name} · ${input.environment.toLabel()}';
    return Ok(
      ToolOutcome(
        modelContent: jsonEncode({
          'business': saved.data.id,
          'environment': input.environment.toLabel(),
          'base_url': endpoint.baseUrl,
          'credential_saved': input.credential != null,
        }),
        summary: toolkit.strings.businessEnvironmentConfigured(place),
      ),
    );
  }

  /// The sign-in after [input]: [current] when the scheme stays, with a new
  /// API key header when given; a fresh API key or Bearer flow otherwise.
  static BusinessAuthFlow _auth(
    BusinessEnvironmentChange input,
    BusinessAuthFlow? current,
  ) {
    final header = input.apiKeyHeader;
    final scheme = input.scheme;
    final base = current != null && (scheme == null || scheme == current.scheme)
        ? current
        : switch (scheme) {
            BusinessAuthScheme.apiKey => const BusinessAuthFlow.apiKey(),
            BusinessAuthScheme.bearer ||
            null => const BusinessAuthFlow.bearer(),
          };
    return header == null ? base : base.copyWith(apiKeyHeader: header);
  }
}

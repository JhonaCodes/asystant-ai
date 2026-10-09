import 'dart:convert';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/business/business_operation_call.dart';
import 'package:asystant_ai/src/business/business_tool_text.dart';
import 'package:asystant_ai/src/business/business_toolkit.dart';
import 'package:asystant_ai/src/model/asystant_action_policy.dart';

/// Runs a registered operation of a business against one environment and
/// profile, with the saved session, and gives the redacted answer to the
/// model.
///
/// It never opens a secure form: a missing session, private header or
/// secret field fails with the tool to call first. That keeps the answer
/// visible to the model, which the chat withholds from any tool that used
/// private input. Only what `BusinessToolkit.approval` marks destructive
/// (a `DELETE` by default) asks for approval.
class OperateBusinessTool extends TypedAsystantTool<BusinessOperationCall>
    implements AsystantActionPolicyProvider {
  const OperateBusinessTool(this.toolkit);

  final BusinessToolkit toolkit;

  @override
  ToolDefinition get definition => ToolDefinition(
    name: toolkit.names.operate,
    description:
        'Runs a registered operation of a business from the device and '
        'returns its answer. Omit environment when it resolves on its own '
        '(one environment configured or with a session); otherwise ask the '
        'person DEV or PROD. Without a session call '
        '${toolkit.names.connect} first; for secret parameters call '
        '${toolkit.names.enterSecrets} first.',
    fields: const [
      ToolField(
        name: 'business',
        description: 'Id of the registered business.',
        kind: .string,
      ),
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
        name: 'operation',
        description: 'Id of the registered operation.',
        kind: .string,
      ),
      ToolField(
        name: 'arguments_json',
        description:
            'JSON object with the operation parameters, validated by the '
            'contract. Never include secret parameters.',
        kind: .string,
        isRequired: false,
      ),
    ],
  );

  @override
  bool get requiresConfirmation => false;

  @override
  AsystantActionPolicy actionPolicy(ToolArguments arguments) {
    final input = arguments.toJson();
    final operation = toolkit
        .business('${input['business']}')
        ?.operation('${input['operation']}');
    return operation == null
        ? const AsystantActionPolicy()
        : toolkit.approval.forOperation(operation);
  }

  @override
  Result<BusinessOperationCall, AssistantFailure> decode(
    ToolArguments arguments,
  ) {
    final input = arguments.toJson();
    final business = toolkit.business('${input['business']}');
    final operation = business?.operation('${input['operation']}');
    if (business == null || operation == null) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail: 'Unknown business or operation; see the registered list.',
        ),
      );
    }
    final environment = input['environment'];
    if (environment is String && environment.toBusinessEnvironment() == null) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail: 'environment must be DEV or PROD, or be omitted.',
        ),
      );
    }
    final Object? decoded;
    try {
      decoded = switch (input['arguments_json']) {
        final String raw => jsonDecode(raw),
        _ => const <String, Object?>{},
      };
    } on FormatException catch (error) {
      return Err(
        AssistantFailure(
          .invalidTool,
          detail: 'arguments_json is not JSON: ${error.message}',
        ),
      );
    }
    if (decoded is! Map) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail: 'arguments_json must be a JSON object.',
        ),
      );
    }
    final values = decoded.cast<String, Object?>();
    final checked = operation.validateArguments(
      values,
      allowsMissingSecrets: true,
    );
    if (checked.errorOrNull case final failure?) {
      return Err(failure.toAssistantFailure());
    }
    return Ok(
      BusinessOperationCall(
        business: business,
        operation: operation,
        environment: environment as String?,
        profile: input['profile'] as String?,
        arguments: values,
      ),
    );
  }

  @override
  Future<Result<AssistantCard, AssistantFailure>> previewInput(
    BusinessOperationCall input,
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
    final operation = input.operation;
    return Ok(
      AssistantCard(
        title: [
          input.business.name,
          environment.data.toLabel(),
          ?input.profile,
          operation.name,
        ].join(' · '),
        body:
            '${operation.method} ${operation.path}\n'
            '${jsonEncode(input.arguments)}',
        kind: toolkit.approval.forOperation(operation).requiresApproval
            ? .permission
            : .summary,
      ),
    );
  }

  @override
  Future<Result<ToolOutcome, AssistantFailure>> executeInput(
    BusinessOperationCall input,
    ToolContext context,
  ) async {
    context.checkCanceled();
    final account = toolkit.requireAccount();
    if (account.errorOrNull case final failure?) return Err(failure);
    final business = input.business;
    final operation = input.operation;
    final environment = await toolkit.resolveEnvironment(
      account.data,
      business,
      label: input.environment,
      profile: input.profile,
    );
    if (environment.errorOrNull case final failure?) return Err(failure);
    final label = environment.data.toLabel();
    final endpoint = business.endpoint(environment.data);
    if (endpoint == null) {
      return Err(
        AssistantFailure(.invalidTool, detail: '$label is not configured.'),
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
    // Every gate runs before the secret values are taken, so a call that
    // fails here keeps them for the retry.
    final gate = await _gate(business, endpoint, operation, scope, label);
    if (gate.errorOrNull case final failure?) return Err(failure);
    final secrets = operation.secretFieldNames.isEmpty
        ? const <String, String>{}
        : toolkit.takeSecrets(business.id, operation.id);
    if (secrets == null) {
      return Err(
        AssistantFailure(
          .invalidTool,
          detail:
              '${operation.id} has secret parameters '
              '(${operation.secretFieldNames.join(', ')}): call '
              '${toolkit.names.enterSecrets} for it first.',
        ),
      );
    }
    context.checkCanceled();
    final executed = await toolkit.executor.execute(
      contract: business,
      scope: scope,
      operationId: operation.id,
      arguments: {...input.arguments, ...secrets},
      idempotencyKey: context.idempotencyKey,
    );
    if (executed.errorOrNull case final failure?) {
      return Err(
        failure.toAssistantFailure(
          hint: switch (failure.code) {
            .noSession || .sessionExpired => 'Call ${toolkit.names.connect}.',
            .missingPrivateHeader =>
              'Call ${toolkit.names.configurePrivateHeader}.',
            _ => '',
          },
        ),
      );
    }
    return Ok(
      ToolOutcome(
        modelContent: jsonEncode({
          'business': business.id,
          'environment': label,
          'profile': profile.data,
          'operation': operation.id,
          'status': executed.data.statusCode,
          'response': executed.data.body,
        }),
        summary: '${business.name} · $label · ${operation.name}',
      ),
    );
  }

  /// The session and every private header the call needs, checked before
  /// anything is sent.
  Future<Result<void, AssistantFailure>> _gate(
    BusinessContract business,
    BusinessEndpoint endpoint,
    BusinessOperation operation,
    BusinessCredentialScope scope,
    String label,
  ) async {
    final session = await toolkit.credentialStore.hasSession(scope);
    if (session.errorOrNull case final failure?) {
      return Err(failure.toAssistantFailure());
    }
    if (!session.data) {
      return Err(
        AssistantFailure(
          .authentication,
          detail:
              'There is no saved session for ${business.id} $label '
              '(${scope.profile}). Call ${toolkit.names.connect}.',
        ),
      );
    }
    final missing = await toolkit.credentialStore.missingPrivateHeaders(scope, {
      ...endpoint.privateHeaders,
      ...operation.privateHeaders,
    });
    if (missing.errorOrNull case final failure?) {
      return Err(failure.toAssistantFailure());
    }
    if (missing.data.isNotEmpty) {
      return Err(
        AssistantFailure(
          .invalidTool,
          detail:
              'Private headers without a value: ${missing.data.join(', ')}. '
              'Call ${toolkit.names.configurePrivateHeader} for each.',
        ),
      );
    }
    return Ok(null);
  }
}

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/business/business_operation_call.dart';
import 'package:asystant_ai/src/business/business_toolkit.dart';

/// Asks the person, in a secure form, for the secret fields of an
/// operation (a new user's password, say) and holds them in memory for the
/// next call to it, which takes them once.
///
/// Secrets are entered here, apart from `OperateBusinessTool`, because the
/// chat withholds the outcome of any tool that used private input: this
/// way the operation's answer still reaches the model.
class EnterBusinessSecretsTool
    extends TypedAsystantTool<BusinessOperationCall> {
  const EnterBusinessSecretsTool(this.toolkit);

  final BusinessToolkit toolkit;

  @override
  ToolDefinition get definition => ToolDefinition(
    name: toolkit.names.enterSecrets,
    description:
        'Opens a secure form on the device for the secret parameters of a '
        'registered operation and keeps them for the next '
        '${toolkit.names.operate} call of that operation, which uses them '
        'once. Call it right before that operation; never ask for those '
        'values in chat.',
    fields: const [
      ToolField(
        name: 'business',
        description: 'Id of the registered business.',
        kind: .string,
      ),
      ToolField(
        name: 'operation',
        description: 'Id of the operation with secret parameters.',
        kind: .string,
      ),
    ],
  );

  @override
  bool get requiresConfirmation => false;

  @override
  Result<BusinessOperationCall, AssistantFailure> decode(
    ToolArguments arguments,
  ) {
    final input = arguments.toJson();
    final business = toolkit.business('${input['business']}');
    final operation = business?.operation('${input['operation']}');
    if (business == null ||
        operation == null ||
        operation.secretFieldNames.isEmpty) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail: 'Pass a registered operation that has secret parameters.',
        ),
      );
    }
    return Ok(BusinessOperationCall(business: business, operation: operation));
  }

  @override
  Future<Result<AssistantCard, AssistantFailure>> previewInput(
    BusinessOperationCall input,
  ) async => Ok(
    AssistantCard(
      title: toolkit.strings.businessSecretsTitle,
      body:
          '${input.business.name} · ${input.operation.name}: '
          '${input.operation.secretFieldNames.join(', ')}',
      kind: .summary,
    ),
  );

  @override
  Future<Result<ToolOutcome, AssistantFailure>> executeInput(
    BusinessOperationCall input,
    ToolContext context,
  ) async {
    if (!context.supportsPrivateInput) {
      return Err(
        const AssistantFailure(
          .unavailable,
          detail: 'This chat cannot open secure forms.',
        ),
      );
    }
    final names = input.operation.secretFieldNames;
    final values = await context.requestPrivateInput(
      '${input.business.name} · ${input.operation.name}',
      [for (final name in names) PrivateInputField(name: name, label: name)],
    );
    if (values == null) return Err(const AssistantFailure(.canceled));
    final missing = names.where((name) => (values[name] ?? '').isEmpty);
    if (missing.isNotEmpty) {
      return Err(
        AssistantFailure(
          .invalidTool,
          detail: 'Missing values: ${missing.join(', ')}.',
        ),
      );
    }
    toolkit.holdSecrets(input.business.id, input.operation.id, {
      for (final name in names) name: values[name] ?? '',
    });
    return Ok(
      ToolOutcome(
        modelContent:
            'The secret values of ${input.operation.id} are held for the '
            'next ${toolkit.names.operate} call of it; call it now.',
        summary: toolkit.strings.businessSecretsHeld,
      ),
    );
  }
}

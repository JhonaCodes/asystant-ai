import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/business/business_private_header_value.dart';
import 'package:asystant_ai/src/business/business_tool_text.dart';
import 'package:asystant_ai/src/business/business_toolkit.dart';

/// Saves the value of a private header declared by a business contract, for
/// one environment and profile, in the device vault. The value comes from
/// a `[secret:…]` reference or a secure form; the model never receives it.
/// Saving again replaces it, so it runs without an approval card.
class ConfigureBusinessPrivateHeaderTool
    extends TypedAsystantTool<BusinessPrivateHeaderValue> {
  const ConfigureBusinessPrivateHeaderTool(this.toolkit);

  final BusinessToolkit toolkit;

  static final RegExp _privateReference = RegExp(r'^\[secret:[a-f0-9]{32}\]$');

  @override
  ToolDefinition get definition => ToolDefinition(
    name: toolkit.names.configurePrivateHeader,
    description:
        "Saves the value of a private header declared in a business's "
        'contract, for DEV or PROD. When the value is missing, the device '
        'asks for it in a secure form. The model never receives the value.',
    fields: const [
      ToolField(
        name: 'business',
        description: 'Id of the registered business.',
        kind: .string,
      ),
      ToolField(
        name: 'environment',
        description: 'DEV or PROD.',
        kind: .string,
        options: ['DEV', 'PROD'],
      ),
      ToolField(
        name: 'profile',
        description: 'Credential profile; omit it for the first one.',
        kind: .string,
        isRequired: false,
      ),
      ToolField(
        name: 'header',
        description:
            'Exact name of a private header declared by the environment or '
            'by an operation.',
        kind: .string,
      ),
      ToolField(
        name: 'value',
        description:
            'Private reference, when the person already gave the value; '
            'omit it to ask for it in a secure form.',
        kind: .string,
        isRequired: false,
        acceptsSecret: true,
      ),
    ],
  );

  @override
  bool get requiresConfirmation => false;

  @override
  Result<BusinessPrivateHeaderValue, AssistantFailure> decode(
    ToolArguments arguments,
  ) {
    final input = arguments.toJson();
    final business = toolkit.business('${input['business']}');
    final environment = '${input['environment']}'.toBusinessEnvironment();
    final header = '${input['header']}';
    final endpoint = environment == null
        ? null
        : business?.endpoint(environment);
    final declared = {
      ...?endpoint?.privateHeaders,
      ...?business?.operations.expand((operation) => operation.privateHeaders),
    }.any((name) => name.toLowerCase() == header.toLowerCase());
    if (business == null ||
        environment == null ||
        endpoint == null ||
        !declared) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail:
              'The private header is not declared for a registered business '
              'and configured environment.',
        ),
      );
    }
    final value = input['value'];
    if (value != null && value is! String) {
      return Err(
        const AssistantFailure(.invalidTool, detail: 'value must be text.'),
      );
    }
    return Ok(
      BusinessPrivateHeaderValue(
        business: business,
        environment: environment,
        profile: input['profile'] as String?,
        header: header,
        value: value as String?,
      ),
    );
  }

  @override
  Future<Result<AssistantCard, AssistantFailure>> previewInput(
    BusinessPrivateHeaderValue input,
  ) async {
    final value = input.value;
    if (value != null && !_privateReference.hasMatch(value)) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail:
              'Pass the value as a private reference, or omit it to ask for '
              'it in a secure form.',
        ),
      );
    }
    return Ok(
      AssistantCard(
        title: toolkit.strings.businessPrivateHeaderTitle,
        body:
            '${input.business.name} · ${input.environment.toLabel()} · '
            '${input.header}\n${toolkit.strings.businessVaultNote}',
        kind: .summary,
      ),
    );
  }

  @override
  Future<Result<ToolOutcome, AssistantFailure>> executeInput(
    BusinessPrivateHeaderValue input,
    ToolContext context,
  ) async {
    final account = toolkit.requireAccount();
    if (account.errorOrNull case final failure?) return Err(failure);
    final endpoint = input.business.endpoint(input.environment);
    if (endpoint == null) {
      return Err(
        const AssistantFailure(.invalidTool, detail: 'No such environment.'),
      );
    }
    final profile = toolkit.resolveProfile(
      input.business,
      endpoint,
      input.profile,
    );
    if (profile.errorOrNull case final failure?) return Err(failure);
    final place =
        '${input.business.name} · ${input.environment.toLabel()} · '
        '${input.header}';
    final value =
        input.value ??
        (await context.requestPrivateInput(place, [
          PrivateInputField(name: 'value', label: input.header),
        ]))?['value'];
    if (value == null) return Err(const AssistantFailure(.canceled));
    context.checkCanceled();
    final written = await toolkit.credentialStore.writePrivateHeader(
      toolkit.scope(
        account.data,
        input.business,
        input.environment,
        profile.data,
      ),
      input.header,
      value,
    );
    if (written.errorOrNull case final failure?) {
      return Err(failure.toAssistantFailure());
    }
    return Ok(
      ToolOutcome(
        modelContent:
            'Private header ${input.header} saved for ${input.business.id} '
            '${input.environment.toLabel()}.',
        summary: toolkit.strings.businessPrivateHeaderSaved,
      ),
    );
  }
}

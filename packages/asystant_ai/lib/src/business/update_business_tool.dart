import 'dart:convert';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/business/business_contract_submission.dart';
import 'package:asystant_ai/src/business/business_tool_text.dart';
import 'package:asystant_ai/src/business/business_toolkit.dart';

/// Corrects a registered business in place: how it signs in, its
/// addresses, headers, profiles and operations (added or replaced by id, or
/// removed).
///
/// The patched contract is validated as a whole and saved through
/// `BusinessToolkit.saveContract`, so a saved session survives unless the
/// address or the sign-in itself changed. A correction is not
/// irreversible, so it runs without an approval card.
class UpdateBusinessTool extends TypedAsystantTool<BusinessContractSubmission> {
  const UpdateBusinessTool(this.toolkit);

  final BusinessToolkit toolkit;

  /// Members of an environment that `endpoint_json` may change.
  static const Set<String> _endpointKeys = {
    'base_url',
    'headers',
    'private_headers',
    'profiles',
    'auth',
  };

  /// The flat sign-in members of the first contract format; accepted only
  /// together with `auth_kind`, which replaces the whole sign-in.
  static const Set<String> _legacyAuthKeys = {
    'auth_kind',
    'api_key_header',
    'auth_base_url',
    'request_path',
    'verify_path',
    'totp_path',
    'login_path',
    'refresh_path',
    'token_field',
    'email_field',
    'password_field',
    'code_field',
    'challenge_field',
    'challenge_request_field',
    'auth_parameters',
    'refresh_token_field',
    'session_id_field',
    'session_id_request_field',
    'required_role',
    'role_field',
  };

  /// Objects merged member by member, where a `null` member is removed.
  static const Set<String> _mergedKeys = {'headers', 'parameters'};

  @override
  ToolDefinition get definition => ToolDefinition(
    name: toolkit.names.update,
    description:
        'Corrects a registered business without registering it again: how '
        'it signs in (auth steps, routes, response paths, parameters such '
        'as company_id or application_id), public headers, profiles, the '
        'base URL of each environment, and its operations (add or replace '
        'by id, or remove). Use it when the person says the business signs '
        'in another way or an endpoint is different. Saved sessions are '
        'kept unless the address or sign-in changed; then sign in again '
        'with ${toolkit.names.connect}. Never put keys, tokens or passwords '
        'in the JSON.',
    fields: [
      ToolField(
        name: 'business',
        description: 'Exact id of the registered business.',
        kind: .string,
      ),
      ToolField(
        name: 'environment',
        description:
            'DEV or PROD. Omit it to apply endpoint_json to every '
            'configured environment; required to change base_url or to '
            'configure a new environment.',
        kind: .string,
        options: ['DEV', 'PROD'],
        isRequired: false,
      ),
      ToolField(
        name: 'endpoint_json',
        description:
            'Partial JSON object of the environment with only what changes: '
            'base_url, headers, private_headers, profiles and auth (same '
            'members as in the contract). headers, auth.headers and '
            'auth.parameters merge with the current ones and a null member '
            'is removed; auth.steps replaces the whole list; any other null '
            'member returns to its default. A flat auth_kind with its '
            'routes replaces the whole sign-in.',
        kind: .string,
        isRequired: false,
      ),
      ToolField(
        name: 'operations_json',
        description:
            'JSON list of complete operations added or replaced by id, in '
            'the contract format.',
        kind: .string,
        isRequired: false,
      ),
      ToolField(
        name: 'remove_operations',
        description: 'Ids of the operations to remove.',
        kind: .strings,
        isRequired: false,
      ),
      ...toolkit.documentFields,
    ],
  );

  @override
  bool get requiresConfirmation => false;

  @override
  Result<BusinessContractSubmission, AssistantFailure> decode(
    ToolArguments arguments,
  ) => _decodeContract(arguments)
      .flatMap((contract) => BusinessToolkit.submission(contract, arguments));

  Result<BusinessContract, AssistantFailure> _decodeContract(
    ToolArguments arguments,
  ) {
    final input = arguments.toJson();
    final current = toolkit.business('${input['business']}');
    if (current == null) {
      return Err(
        AssistantFailure(
          .invalidTool,
          detail:
              'The business is not registered; use ${toolkit.names.register}.',
        ),
      );
    }
    final BusinessContract next;
    try {
      next = _patched(current, input);
    } on FormatException catch (error) {
      return Err(AssistantFailure(.invalidTool, detail: error.message));
    } on TypeError {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail:
              'A member of endpoint_json or operations_json has the '
              'wrong type.',
        ),
      );
    }
    return next
        .validateContract(
          allowsOpenObjects: toolkit.allowsOpenObjects?.call(next.id) ?? false,
        )
        .mapError((failure) => failure.toAssistantFailure());
  }

  /// [current] with every change of [input] applied. Throws a
  /// [FormatException] naming what the model must fix.
  BusinessContract _patched(
    BusinessContract current,
    Map<String, Object?> input,
  ) {
    final endpointPatch = _decodePatch(input['endpoint_json']);
    final upserts = _decodeOperations(input['operations_json']);
    final removals = [
      for (final id in input['remove_operations'] as List<Object?>? ?? const [])
        '$id'.trim(),
    ];
    final hasDocument =
        input['document_attachment_id'] != null || input['document'] != null;
    if (endpointPatch == null &&
        upserts.isEmpty &&
        removals.isEmpty &&
        !hasDocument) {
      throw const FormatException(
        'Pass endpoint_json, operations_json, remove_operations or a '
        'document.',
      );
    }
    final withEndpoints = endpointPatch == null
        ? current
        : _withEndpointPatch(
            current,
            endpointPatch,
            input['environment'] as String?,
          );
    return withEndpoints.copyWith(
      operations: _withOperations(withEndpoints, upserts, removals),
    );
  }

  Map<String, Object?>? _decodePatch(Object? raw) {
    if (raw == null) return null;
    final decoded = jsonDecode(raw as String);
    if (decoded is! Map) {
      throw const FormatException('endpoint_json must be a JSON object.');
    }
    final patch = decoded.cast<String, Object?>();
    if (patch.containsBusinessCredential) {
      throw FormatException(
        'Credentials do not go in the contract; save them with '
        '${toolkit.names.configureEnvironment} or sign in with '
        '${toolkit.names.connect}.',
      );
    }
    final isLegacy = patch.containsKey('auth_kind');
    final unknown = patch.keys.where(
      (key) =>
          !_endpointKeys.contains(key) &&
          !(isLegacy && _legacyAuthKeys.contains(key)),
    );
    if (unknown.isNotEmpty) {
      throw FormatException(
        'Unknown members in endpoint_json: ${unknown.join(', ')}.',
      );
    }
    if (isLegacy && patch.containsKey('auth')) {
      throw const FormatException('Pass either auth or auth_kind, not both.');
    }
    return patch;
  }

  static List<BusinessOperation> _decodeOperations(Object? raw) {
    if (raw == null) return const [];
    final decoded = jsonDecode(raw as String);
    if (decoded is! List) {
      throw const FormatException('operations_json must be a JSON list.');
    }
    if (decoded.containsBusinessCredential) {
      throw const FormatException('Credentials do not go in the contract.');
    }
    return [
      for (final operation in decoded)
        if (operation is Map)
          BusinessOperation.fromJson(operation.cast<String, Object?>())
        else
          throw const FormatException(
            'Each entry of operations_json must be an object.',
          ),
    ];
  }

  /// Applies [patch] to [label]'s environment, or to every configured
  /// environment when it is omitted.
  static BusinessContract _withEndpointPatch(
    BusinessContract contract,
    Map<String, Object?> patch,
    String? label,
  ) {
    final explicit = label?.toBusinessEnvironment();
    if (label != null && explicit == null) {
      throw const FormatException('environment must be DEV or PROD.');
    }
    final targets = explicit == null ? contract.environments : [explicit];
    if (targets.isEmpty) {
      throw const FormatException(
        'The business has no environment yet: pass environment DEV or PROD '
        'with base_url.',
      );
    }
    final movesAddress =
        patch.containsKey('base_url') ||
        patch.containsKey('auth_base_url') ||
        (patch['auth'] is Map &&
            (patch['auth'] as Map).containsKey('base_url'));
    if (explicit == null && targets.length > 1 && movesAddress) {
      throw const FormatException(
        'To change an address pass environment DEV or PROD.',
      );
    }
    var next = contract;
    for (final environment in targets) {
      final merged = _merged(
        contract.endpoint(environment)?.toJson() ?? const {},
        {
          for (final entry in patch.entries)
            if (_endpointKeys.contains(entry.key) && entry.key != 'auth')
              entry.key: entry.value,
        },
        mergedKeys: const {'headers'},
      );
      if (patch.containsKey('auth')) {
        merged['auth'] = switch (patch['auth']) {
          null => const BusinessAuthFlow().toJson(),
          final Map<Object?, Object?> auth => _merged(
            (merged['auth'] as Map<Object?, Object?>?)
                    ?.cast<String, Object?>() ??
                const {},
            auth.cast<String, Object?>(),
            mergedKeys: _mergedKeys,
          ),
          _ => throw const FormatException('auth must be an object.'),
        };
      }
      if (patch.containsKey('auth_kind')) {
        merged['auth'] = BusinessAuthFlow.fromLegacyJson({
          for (final entry in patch.entries)
            if (_legacyAuthKeys.contains(entry.key)) entry.key: entry.value,
        }, businessId: contract.id).toJson();
      }
      if (merged['base_url'] is! String) {
        throw FormatException('${environment.toLabel()} needs base_url.');
      }
      next = next.withEndpoint(
        environment,
        BusinessEndpoint.fromJson(merged, businessId: contract.id),
      );
    }
    return next;
  }

  /// [current] with [patch] applied: members of [mergedKeys] merge member
  /// by member (a null member is removed), a null member returns to its
  /// default, any other member is replaced.
  static Map<String, Object?> _merged(
    Map<String, Object?> current,
    Map<String, Object?> patch, {
    required Set<String> mergedKeys,
  }) {
    final merged = {...current};
    for (final MapEntry(:key, :value) in patch.entries) {
      if (mergedKeys.contains(key)) {
        if (value != null && value is! Map) {
          throw FormatException('$key must be an object.');
        }
        final members = <String, Object?>{
          ...?(merged[key] as Map<Object?, Object?>?)?.cast<String, Object?>(),
        };
        for (final member
            in (value as Map<Object?, Object?>? ?? const {}).entries) {
          if (member.value == null) {
            members.remove('${member.key}');
          } else {
            members['${member.key}'] = '${member.value}';
          }
        }
        merged[key] = members;
      } else if (value == null) {
        merged.remove(key);
      } else {
        merged[key] = value;
      }
    }
    return merged;
  }

  /// [contract]'s operations with [upserts] replacing the same id in place
  /// or appended, and [removals] dropped. Operations that ship with the app
  /// (`BusinessToolkit.builtInOperations`) are rejected instead of
  /// silently coming back.
  List<BusinessOperation> _withOperations(
    BusinessContract contract,
    List<BusinessOperation> upserts,
    List<String> removals,
  ) {
    final builtIn = toolkit.builtInOperations?.call(contract.id) ?? const {};
    final touched = {
      ...upserts.map((operation) => operation.id),
      ...removals,
    }.where(builtIn.contains);
    if (touched.isNotEmpty) {
      throw FormatException(
        'Built-in operations cannot be changed or removed: '
        '${touched.join(', ')}.',
      );
    }
    final missing = removals.where((id) => contract.operation(id) == null);
    if (missing.isNotEmpty) {
      throw FormatException('No such operations: ${missing.join(', ')}.');
    }
    final pending = {for (final operation in upserts) operation.id: operation};
    return [
      for (final operation in contract.operations)
        if (!removals.contains(operation.id))
          pending.remove(operation.id) ?? operation,
      ...pending.values,
    ];
  }

  @override
  Future<Result<AssistantCard, AssistantFailure>> previewInput(
    BusinessContractSubmission submission,
  ) async {
    final input = submission.contract;
    final strings = toolkit.strings;
    final previous = toolkit.business(input.id);
    final previousIds = {
      ...?previous?.operations.map((operation) => operation.id),
    };
    final nextIds = input.operations.map((operation) => operation.id).toSet();
    final added = nextIds.difference(previousIds);
    final removed = previousIds.difference(nextIds);
    return Ok(
      AssistantCard(
        title: strings.businessUpdateTitle(input.name),
        body: [
          for (final environment in BusinessEnvironment.values)
            if (input.endpoint(environment) case final endpoint?
                when endpoint != previous?.endpoint(environment))
              '${environment.toLabel()}: ${endpoint.baseUrl}',
          if (added.isNotEmpty)
            strings.businessAddedOperations(added.join(', ')),
          if (removed.isNotEmpty)
            strings.businessRemovedOperations(removed.join(', ')),
          strings.businessSessionResetNote,
        ].join('\n'),
        kind: .summary,
      ),
    );
  }

  @override
  Future<Result<ToolOutcome, AssistantFailure>> executeInput(
    BusinessContractSubmission submission,
    ToolContext context,
  ) async {
    context.checkCanceled();
    final account = toolkit.requireAccount();
    if (account.errorOrNull case final failure?) return Err(failure);
    final input = submission.contract;
    final document = toolkit.documentOf(submission, context);
    if (document.errorOrNull case final failure?) return Err(failure);
    final saved = await toolkit.saveContract(account.data, input);
    if (saved.errorOrNull case final failure?) return Err(failure);
    final contract = saved.data;
    final documentState = await toolkit.keepDocument(
      account.data,
      document.data,
    );
    final environments = <String, Object?>{};
    for (final environment in contract.environments) {
      final endpoint = contract.endpoint(environment);
      if (endpoint == null) continue;
      final sessions = <String, String>{};
      for (final profile in endpoint.credentialProfiles) {
        final has = await toolkit.credentialStore.hasSession(
          toolkit.scope(account.data, contract, environment, profile.id),
        );
        if (has.errorOrNull case final failure?) {
          return Err(failure.toAssistantFailure());
        }
        sessions[profile.id] = has.data
            ? 'saved'
            : 'none: call ${toolkit.names.connect} before operating';
      }
      environments[environment.toLabel()] = {
        'base_url': endpoint.baseUrl,
        'sign_in': endpoint.toSignInSummary(toolkit.names),
        'sessions': sessions,
      };
    }
    return Ok(
      ToolOutcome(
        modelContent: jsonEncode({
          'business': contract.id,
          'document': ?documentState,
          'environments': environments,
          'operations': contract.operations
              .map((operation) => operation.id)
              .toList(),
        }),
        summary: toolkit.strings.businessUpdated(contract.name),
      ),
    );
  }
}

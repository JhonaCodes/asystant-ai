import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/business/business_approval_policy.dart';
import 'package:asystant_ai/src/business/business_contract_submission.dart';
import 'package:asystant_ai/src/business/business_context_prompt.dart';
import 'package:asystant_ai/src/business/business_tool_names.dart';
import 'package:asystant_ai/src/business/business_tool_text.dart';
import 'package:asystant_ai/src/business/configure_business_environment_tool.dart';
import 'package:asystant_ai/src/business/configure_business_private_header_tool.dart';
import 'package:asystant_ai/src/business/connect_business_tool.dart';
import 'package:asystant_ai/src/business/enter_business_secrets_tool.dart';
import 'package:asystant_ai/src/business/operate_business_tool.dart';
import 'package:asystant_ai/src/business/read_business_docs_tool.dart';
import 'package:asystant_ai/src/business/register_business_tool.dart';
import 'package:asystant_ai/src/business/update_business_tool.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';

/// Lets an assistant register business APIs, sign in to them and run their
/// operations: the business tools, the context prompt that tells the model
/// what is registered, and the state they share.
///
/// The host supplies where contracts live ([contractStore]), where secrets
/// live ([credentialStore], usually `SecureCredentialStore`) and who is
/// signed in ([accountId]). Return [tools] from `AsystantAI.tools` and
/// [contextPrompt] from `AsystantAI.contextPrompts`.
///
/// Sign-in values, private headers and secret operation fields are always
/// typed in secure forms, by a tool separate from [OperateBusinessTool], so
/// the answer of an operation is never withheld from the model.
class BusinessToolkit {
  BusinessToolkit({
    required this.contractStore,
    required this.credentialStore,
    required this.accountId,
    BusinessDocumentStore? documentStore,
    BusinessHttp? http,
    this.names = const BusinessToolNames(),
    this.strings = AsystantStrings.english,
    this.approval = const BusinessApprovalPolicy(),
    this.allowsOpenObjects,
    this.builtInOperations,
    this.onTotpEnrollment,
  }) : documentStore = documentStore ?? InMemoryBusinessDocumentStore(),
       http = http ?? BusinessHttpClient() {
    signIn = BusinessSignIn(http: this.http, store: credentialStore);
    executor = BusinessExecutor(
      http: this.http,
      store: credentialStore,
      signIn: signIn,
    );
  }

  final BusinessContractStore contractStore;
  final BusinessCredentialStore credentialStore;

  /// The source document of each business, consulted by
  /// [ReadBusinessDocsTool]; in memory unless the host passes one, such as
  /// `JsonBusinessDocumentStore`.
  final BusinessDocumentStore documentStore;

  /// The signed-in account of the host app; null while signed out, which
  /// makes every business tool fail with `FailureCode.authentication`.
  final String? Function() accountId;

  final BusinessHttp http;
  final BusinessToolNames names;

  /// What the person reads: card titles, form labels, step summaries.
  final AsystantStrings strings;

  final BusinessApprovalPolicy approval;

  /// Whether contracts of a business may declare object fields without
  /// typed members, such as contracts that ship with the app. Null rejects
  /// them for every business.
  final bool Function(String businessId)? allowsOpenObjects;

  /// Operation ids of a business that ship with the app and the update tool
  /// may not change or remove. Null allows every change.
  final Set<String> Function(String businessId)? builtInOperations;

  /// Shows a new authenticator (its QR) before the person types its code;
  /// answers whether to continue. Null shows the manual key in the code
  /// form's title instead.
  final Future<bool> Function(BusinessTotpEnrollment enrollment)?
  onTotpEnrollment;

  late final BusinessSignIn signIn;
  late final BusinessExecutor executor;

  List<BusinessContract> _businesses = const [];
  String? _loadedAccount;
  final Map<String, Map<String, String>> _heldSecrets = {};

  /// The contracts loaded for the signed-in account.
  List<BusinessContract> get businesses => _businesses;

  /// The loaded contract [businessId], if registered.
  BusinessContract? business(String businessId) {
    for (final contract in _businesses) {
      if (contract.id == businessId) return contract;
    }
    return null;
  }

  /// The business tools, named by [names].
  List<AsystantTool> get tools => [
    RegisterBusinessTool(this),
    UpdateBusinessTool(this),
    ConnectBusinessTool(this),
    OperateBusinessTool(this),
    ConfigureBusinessEnvironmentTool(this),
    ConfigureBusinessPrivateHeaderTool(this),
    EnterBusinessSecretsTool(this),
    ReadBusinessDocsTool(this),
  ];

  /// The fields that let the register and update tools keep the source
  /// document of a business.
  List<ToolField> get documentFields => [
    ToolField(
      name: 'document_attachment_id',
      description:
          'Id of the text file attached to the chat the contract comes '
          'from, such as the endpoints .md; it is kept for ${names.readDocs}.',
      kind: .string,
      isRequired: false,
    ),
    ToolField(
      name: 'document',
      description:
          'The source documentation as text, when it was not attached; kept '
          'for ${names.readDocs}. Never include credentials.',
      kind: .string,
      isRequired: false,
    ),
  ];

  /// [contract] with the source document named by [arguments]'
  /// [documentFields]; at most one of them.
  static Result<BusinessContractSubmission, AssistantFailure> submission(
    BusinessContract contract,
    ToolArguments arguments,
  ) {
    final input = arguments.toJson();
    final attachment = input['document_attachment_id'];
    final text = input['document'];
    if (attachment != null && text != null) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail: 'Pass document_attachment_id or document, not both.',
        ),
      );
    }
    return Ok(
      BusinessContractSubmission(
        contract: contract,
        documentAttachmentId: attachment is String ? attachment.trim() : null,
        documentText: text is String ? text : null,
      ),
    );
  }

  /// The source document of [submission], read from the attached file or
  /// the passed text; null when none comes with it.
  Result<BusinessDocument?, AssistantFailure> documentOf(
    BusinessContractSubmission submission,
    ToolContext context,
  ) {
    if (!submission.hasDocument) return Ok(null);
    final attachment = switch (submission.documentAttachmentId) {
      final String id => context.attachment(id),
      null => null,
    };
    if (submission.documentAttachmentId != null &&
        (attachment == null || !attachment.isText)) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail:
              'document_attachment_id is not a text file attached to this '
              'conversation.',
        ),
      );
    }
    final text = attachment?.text ?? submission.documentText ?? '';
    if (text.trim().isEmpty || text.length > BusinessDocument.maxLength) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail:
              'The document must be text of up to '
              '${BusinessDocument.maxLength} characters.',
        ),
      );
    }
    if (text.containsBusinessCredential) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail:
              'The document contains a credential; it cannot be kept. '
              'Register the contract without it.',
        ),
      );
    }
    return Ok(
      BusinessDocument(
        businessId: submission.contract.id,
        title: attachment?.filename ?? '',
        text: text,
      ),
    );
  }

  /// Saves [document] in [documentStore] and answers what the model reads
  /// about it; null when there is no document.
  Future<String?> keepDocument(
    String account,
    BusinessDocument? document,
  ) async => document == null
      ? null
      : (await documentStore.write(account, document)).when(
          ok: (_) => 'saved for ${names.readDocs}',
          err: (failure) => 'not saved: ${failure.message}',
        );

  /// What the model must know before calling a business tool: every
  /// registered business with its operations and, per environment and
  /// profile, how it signs in and whether a session is saved. Loads the
  /// contracts first when the signed-in account changed.
  Future<AsystantSystemPrompt> contextPrompt({
    String id = 'business_catalog',
  }) async {
    final loaded = _loadedAccount == accountId() ? null : await load();
    return BusinessContextPrompt(this)
        .build(id: id, loadProblem: loaded?.errorOrNull?.message ?? '');
  }

  /// Reads the contracts of the signed-in account from [contractStore].
  /// Call it after the host signs in; [contextPrompt] calls it when the
  /// account changed.
  Future<Result<List<BusinessContract>, BusinessFailure>> load() async {
    final account = accountId();
    if (account != _loadedAccount) _heldSecrets.clear();
    if (account == null) {
      _businesses = const [];
      _loadedAccount = null;
      return Ok(const []);
    }
    final listed = await contractStore.list(account);
    if (listed.errorOrNull case final failure?) return Err(failure);
    _businesses = List.unmodifiable(listed.data);
    _loadedAccount = account;
    return Ok(_businesses);
  }

  /// The signed-in account, or the failure every tool returns without one.
  Result<String, AssistantFailure> requireAccount() => switch (accountId()) {
    final String account => Ok(account),
    null => Err(
      const AssistantFailure(
        .authentication,
        detail: 'No account is signed in to the app.',
      ),
    ),
  };

  /// The credential scope of [business] for [environment] and [profile].
  BusinessCredentialScope scope(
    String account,
    BusinessContract business,
    BusinessEnvironment environment,
    String profile,
  ) => BusinessCredentialScope(
    accountId: account,
    businessId: business.id,
    environment: environment,
    profile: profile,
  );

  /// Validates and saves [next], then clears what it invalidates: the
  /// sessions of every environment whose address or sign-in changed (see
  /// `BusinessContractChange.sessionResetsFrom`; [signedIn] keeps the
  /// session that has just signed in with [next]'s parameters) and the
  /// values of private headers it no longer declares.
  Future<Result<BusinessContract, AssistantFailure>> saveContract(
    String account,
    BusinessContract next, {
    BusinessEnvironment? signedIn,
  }) async {
    final valid = next.validateContract(
      allowsOpenObjects: allowsOpenObjects?.call(next.id) ?? false,
    );
    if (valid.errorOrNull case final failure?) {
      return Err(failure.toAssistantFailure());
    }
    final previous = business(next.id);
    final saved = await contractStore.save(account, next);
    if (saved.errorOrNull case final failure?) {
      return Err(failure.toAssistantFailure());
    }
    final contract = saved.data;
    _businesses = List.unmodifiable([
      for (final current in _businesses)
        if (current.id != contract.id) current,
      contract,
    ]);
    final cleared = await _clearInvalidated(
      account,
      contract,
      previous,
      signedIn,
    );
    if (cleared.errorOrNull case final failure?) {
      return Err(
        failure.toAssistantFailure(
          hint:
              'The contract was saved, but an old session or private header '
              'could not be cleared.',
        ),
      );
    }
    return Ok(contract);
  }

  Future<Result<void, BusinessFailure>> _clearInvalidated(
    String account,
    BusinessContract contract,
    BusinessContract? previous,
    BusinessEnvironment? signedIn,
  ) async {
    for (final environment in BusinessEnvironment.values) {
      final resets = contract
          .sessionResetsFrom(previous, signedIn: signedIn)
          .contains(environment);
      final dropped = contract.droppedPrivateHeaders(previous, environment);
      if (!resets && dropped.isEmpty) continue;
      for (final profile in contract.profileIdsWith(previous, environment)) {
        final target = scope(account, contract, environment, profile);
        if (resets) {
          final done = await credentialStore.clearSession(target);
          if (done.errorOrNull case final failure?) return Err(failure);
        }
        for (final name in dropped) {
          final done = await credentialStore.deletePrivateHeader(target, name);
          if (done.errorOrNull case final failure?) return Err(failure);
        }
      }
    }
    return Ok(null);
  }

  /// The environment a call uses: [label] (`DEV` or `PROD`) when given;
  /// otherwise the only configured one, or the only one where [profile]
  /// has a session. Still ambiguous, the failure tells the model to ask.
  Future<Result<BusinessEnvironment, AssistantFailure>> resolveEnvironment(
    String account,
    BusinessContract business, {
    String? label,
    String? profile,
  }) async {
    if (label != null) {
      final explicit = label.toBusinessEnvironment();
      if (explicit == null || business.endpoint(explicit) == null) {
        return Err(
          AssistantFailure(
            .invalidTool,
            detail:
                '${business.name} has no $label environment. Configure it '
                'with ${names.configureEnvironment} or ${names.update}.',
          ),
        );
      }
      return Ok(explicit);
    }
    final configured = business.environments;
    if (configured.isEmpty) {
      return Err(
        AssistantFailure(
          .invalidTool,
          detail:
              '${business.name} has no environment with a URL. Configure DEV '
              'or PROD with ${names.configureEnvironment}.',
        ),
      );
    }
    if (configured.length == 1) return Ok(configured.single);
    final withSession = <BusinessEnvironment>[];
    for (final environment in configured) {
      final endpoint = business.endpoint(environment);
      final profileId = profile ?? endpoint?.credentialProfiles.first.id ?? '';
      final has = await credentialStore.hasSession(
        scope(account, business, environment, profileId),
      );
      if (has.errorOrNull case final failure?) {
        return Err(failure.toAssistantFailure());
      }
      if (has.data) withSession.add(environment);
    }
    if (withSession.length == 1) return Ok(withSession.single);
    return Err(
      AssistantFailure(
        .invalidTool,
        detail:
            'DEV and PROD are both configured for ${business.name}: ask the '
            'person which one to use and pass environment.',
      ),
    );
  }

  /// The profile a call uses: [requested] when declared, else the first one
  /// of [endpoint].
  Result<String, AssistantFailure> resolveProfile(
    BusinessContract business,
    BusinessEndpoint endpoint,
    String? requested,
  ) {
    if (requested == null) return Ok(endpoint.credentialProfiles.first.id);
    if (endpoint.profile(requested) != null) return Ok(requested);
    return Err(
      AssistantFailure(
        .invalidTool,
        detail:
            '${business.name} has no profile $requested. Profiles: '
            '${endpoint.credentialProfiles.map((profile) => profile.id).join(', ')}.',
      ),
    );
  }

  /// Keeps the secret fields the person typed for the next call to
  /// [operationId] of [businessId]; [takeSecrets] hands them over once.
  void holdSecrets(
    String businessId,
    String operationId,
    Map<String, String> values,
  ) => _heldSecrets['$businessId/$operationId'] = Map.unmodifiable(values);

  /// The secret fields held for [operationId] of [businessId], removed from
  /// memory as they are handed over; null when none are held.
  Map<String, String>? takeSecrets(String businessId, String operationId) =>
      _heldSecrets.remove('$businessId/$operationId');

  /// Whether secret fields are held for [operationId] of [businessId].
  bool holdsSecrets(String businessId, String operationId) =>
      _heldSecrets.containsKey('$businessId/$operationId');
}

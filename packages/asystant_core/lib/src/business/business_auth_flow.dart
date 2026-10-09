import 'package:collection/collection.dart';

import 'package:asystant_core/src/business/business_auth_input.dart';
import 'package:asystant_core/src/business/business_auth_scheme.dart';
import 'package:asystant_core/src/business/business_auth_step.dart';
import 'package:asystant_core/src/business/business_auth_step_kind.dart';
import 'package:asystant_core/src/business/business_json_reading.dart';

/// How one environment of a business signs in, described as data: the
/// steps that run in order, the values the person types for them, the fixed
/// parameters every step sends, where the token comes back and how the
/// session is renewed.
///
/// A flow without sign-in steps uses a credential configured directly on
/// the device (an API key or a Bearer token). The named constructors build
/// the common flows ([BusinessAuthFlow.emailCode],
/// [BusinessAuthFlow.emailPasswordTotp], ...); [copyWith] then sets the
/// address, parameters and response paths, and [withRefresh] adds renewal.
class BusinessAuthFlow {
  const BusinessAuthFlow({
    this.scheme = BusinessAuthScheme.bearer,
    this.apiKeyHeader = defaultApiKeyHeader,
    this.baseUrl = '',
    this.headers = const {},
    this.parameters = const {},
    this.requiredParameters = const [],
    this.steps = const [],
    this.tokenPath = 'access_token',
    this.refreshTokenField = 'refresh_token',
    this.reusesTokenForRefresh = false,
    this.sessionIdPath = 'session.id',
    this.sessionIdField = 'session_id',
    this.requiredRole = '',
    this.rolePath = 'user.role',
    this.enrollmentUriPath = 'totp_enrollment.otpauth_uri',
    this.enrollmentSecretPath = 'totp_enrollment.secret',
  });

  /// A Bearer token configured on the device; no sign-in step.
  const BusinessAuthFlow.bearer() : this();

  /// An API key configured on the device and sent as [header]; no sign-in
  /// step.
  const BusinessAuthFlow.apiKey({String header = defaultApiKeyHeader})
    : this(scheme: .apiKey, apiKeyHeader: header);

  /// The API sends a code to the email ([requestPath]) and the person types
  /// it back ([verifyPath]), which answers with the token.
  BusinessAuthFlow.emailCode({
    required String requestPath,
    required String verifyPath,
    String emailField = 'email',
    String codeField = 'code',
  }) : this(
         steps: [
           BusinessAuthStep(
             kind: .request,
             path: requestPath,
             inputs: [BusinessAuthInput.email(field: emailField)],
           ),
           BusinessAuthStep(
             kind: .verify,
             path: verifyPath,
             inputs: [
               BusinessAuthInput.email(field: emailField),
               BusinessAuthInput.code(field: codeField),
             ],
           ),
         ],
       );

  /// [BusinessAuthFlow.emailCode] followed by the authenticator code at
  /// [totpPath], sent with the email.
  BusinessAuthFlow.emailCodeTotp({
    required String requestPath,
    required String verifyPath,
    required String totpPath,
    String emailField = 'email',
    String codeField = 'code',
  }) : this(
         steps: [
           BusinessAuthStep(
             kind: .request,
             path: requestPath,
             inputs: [BusinessAuthInput.email(field: emailField)],
           ),
           BusinessAuthStep(
             kind: .verify,
             path: verifyPath,
             inputs: [
               BusinessAuthInput.email(field: emailField),
               BusinessAuthInput.code(field: codeField),
             ],
           ),
           BusinessAuthStep(
             kind: .totp,
             path: totpPath,
             inputs: [
               BusinessAuthInput.email(field: emailField),
               BusinessAuthInput.totp(field: codeField),
             ],
           ),
         ],
       );

  /// Email and password at [loginPath], which answers with the token.
  BusinessAuthFlow.emailPassword({
    required String loginPath,
    String emailField = 'email',
    String passwordField = 'password',
  }) : this(
         steps: [
           BusinessAuthStep(
             kind: .password,
             path: loginPath,
             inputs: [
               BusinessAuthInput.email(field: emailField),
               BusinessAuthInput.password(field: passwordField),
             ],
           ),
         ],
       );

  /// Email and password at [loginPath]. An account without a second factor
  /// gets the token right there; otherwise the answer carries a challenge
  /// at [challengeField] (and [secondFactorFlag] is true), sent back as
  /// [challengeRequestField] with the authenticator code to [totpPath].
  BusinessAuthFlow.emailPasswordTotp({
    required String loginPath,
    required String totpPath,
    String emailField = 'email',
    String passwordField = 'password',
    String codeField = 'code',
    String challengeField = 'totp_token',
    String challengeRequestField = 'totp_token',
    String secondFactorFlag = 'requires_2fa',
  }) : this(
         steps: [
           BusinessAuthStep(
             kind: .password,
             path: loginPath,
             inputs: [
               BusinessAuthInput.email(field: emailField),
               BusinessAuthInput.password(field: passwordField),
             ],
             completesWithToken: true,
             continueFlag: secondFactorFlag,
           ),
           BusinessAuthStep(
             kind: .totp,
             path: totpPath,
             inputs: [BusinessAuthInput.totp(field: codeField)],
             carry: {challengeRequestField: challengeField},
           ),
         ],
       );

  /// AulaMás operations panel: email code at `/auth/request` and
  /// `/auth/verify`, then the authenticator at `/auth/totp`.
  BusinessAuthFlow.aulaMasOperator({
    String emailField = 'email',
    String codeField = 'code',
  }) : this.emailCodeTotp(
         requestPath: '/auth/request',
         verifyPath: '/auth/verify',
         totpPath: '/auth/totp',
         emailField: emailField,
         codeField: codeField,
       );

  /// Standard SST operators: email code at `/operator/auth/request-code`
  /// and `/operator/auth/verify-code`, which answers with `token`.
  factory BusinessAuthFlow.sstOperator({
    String emailField = 'email',
    String codeField = 'code',
  }) => BusinessAuthFlow.emailCode(
    requestPath: '/operator/auth/request-code',
    verifyPath: '/operator/auth/verify-code',
    emailField: emailField,
    codeField: codeField,
  ).copyWith(tokenPath: 'token');

  /// The API key header used when a contract does not name one.
  static const String defaultApiKeyHeader = 'X-Admin-API-Key';

  final BusinessAuthScheme scheme;

  /// The header that carries the credential when [scheme] is
  /// [BusinessAuthScheme.apiKey].
  final String apiKeyHeader;

  /// Address of the sign-in steps when it differs from the environment's
  /// base URL; empty uses the base URL.
  final String baseUrl;

  /// Public headers added to every sign-in request.
  final Map<String, String> headers;

  /// Fixed parameters sent with every sign-in step, such as LoginFlow's
  /// `application_id` and `company_id`. The person can correct them in the
  /// first sign-in form.
  final Map<String, String> parameters;

  /// The [parameters] that cannot be empty.
  final List<String> requiredParameters;

  /// Sign-in steps in order, plus an optional [BusinessAuthStepKind.refresh]
  /// step that renews the session.
  final List<BusinessAuthStep> steps;

  /// Dotted path of the token in the sign-in answer, such as `jwt` or
  /// `data.access_token` (a top-level `data` envelope is unwrapped first).
  final String tokenPath;

  /// Member that carries the refresh token, in the sign-in answer and in
  /// the refresh request.
  final String refreshTokenField;

  /// Whether the access token itself renews the session when the answer has
  /// no refresh token (LoginFlow).
  final bool reusesTokenForRefresh;

  /// Dotted path of the server's session id in the sign-in answer.
  final String sessionIdPath;

  /// Member that sends the session id back with a refresh.
  final String sessionIdField;

  /// The role the signed-in account must have; empty accepts any.
  final String requiredRole;

  /// Dotted path of the account's role in the sign-in answer.
  final String rolePath;

  /// Dotted paths of a new authenticator's `otpauth://` URI and manual key,
  /// when the API enrolls the second factor during sign-in.
  final String enrollmentUriPath;
  final String enrollmentSecretPath;

  /// The steps that sign in, without the refresh step.
  List<BusinessAuthStep> get signInSteps => [
    for (final step in steps)
      if (step.kind != BusinessAuthStepKind.refresh) step,
  ];

  /// The step that renews a session, if any.
  BusinessAuthStep? get refreshStep =>
      steps.firstWhereOrNull((step) => step.kind == .refresh);

  /// Whether the person signs in with a form; false when the credential is
  /// configured directly.
  bool get signsIn => signInSteps.isNotEmpty;

  /// Every value the person types, once each, in the order first asked.
  List<BusinessAuthInput> get inputs {
    final seen = <String>{};
    return [
      for (final step in signInSteps)
        for (final input in step.inputs)
          if (seen.add(input.name)) input,
    ];
  }

  /// This flow with a refresh step at [path] that sends the refresh token
  /// and the session id; unchanged when [path] is empty.
  BusinessAuthFlow withRefresh(String path) => path.isEmpty
      ? this
      : copyWith(
          steps: [
            ...signInSteps,
            BusinessAuthStep(
              kind: .refresh,
              path: path,
              sendsParameters: false,
            ),
          ],
        );

  factory BusinessAuthFlow.fromJson(Map<String, Object?> json) =>
      BusinessAuthFlow(
        scheme: json.enumValue(
          BusinessAuthScheme.values,
          'scheme',
          fallback: BusinessAuthScheme.bearer,
        ),
        apiKeyHeader: json.optionalString(
          'api_key_header',
          defaultApiKeyHeader,
        ),
        baseUrl: json.optionalString('base_url', ''),
        headers: json.stringMap('headers'),
        parameters: json.stringMap('parameters'),
        requiredParameters: json.stringList('required_parameters'),
        steps: [
          for (final step in json.objectList('steps'))
            BusinessAuthStep.fromJson(step),
        ],
        tokenPath: json.optionalString('token_path', 'access_token'),
        refreshTokenField: json.optionalString(
          'refresh_token_field',
          'refresh_token',
        ),
        reusesTokenForRefresh: json.optionalBool(
          'reuses_token_for_refresh',
          fallback: false,
        ),
        sessionIdPath: json.optionalString('session_id_path', 'session.id'),
        sessionIdField: json.optionalString('session_id_field', 'session_id'),
        requiredRole: json.optionalString('required_role', ''),
        rolePath: json.optionalString('role_path', 'user.role'),
        enrollmentUriPath: json.optionalString(
          'enrollment_uri_path',
          'totp_enrollment.otpauth_uri',
        ),
        enrollmentSecretPath: json.optionalString(
          'enrollment_secret_path',
          'totp_enrollment.secret',
        ),
      );

  /// Reads the flat endpoint JSON of the first contract format, where an
  /// `auth_kind` name chose a fixed sign-in (`bearer`, `apiKey`,
  /// `emailCode`, `emailCodeTotp`, `emailPassword`, `emailPasswordTotp`,
  /// `aulaMasOperator`, `sstOperator`) and its routes and fields were
  /// separate members. Contracts saved in that format keep working.
  ///
  /// [businessId] keeps two rules that format tied to LoginFlow
  /// (`loginflow`): its `application_id` (and `company_id` for an email
  /// code) cannot be empty, and its access token renews the session when
  /// the answer has no refresh token.
  factory BusinessAuthFlow.fromLegacyJson(
    Map<String, Object?> json, {
    String businessId = '',
  }) {
    final kind = json.requiredString('auth_kind');
    final emailField = json.optionalString('email_field', 'email');
    final passwordField = json.optionalString('password_field', 'password');
    final codeField = json.optionalString('code_field', 'code');
    final apiKeyHeader = json.optionalString(
      'api_key_header',
      defaultApiKeyHeader,
    );
    final preset = switch (kind) {
      'bearer' => const BusinessAuthFlow.bearer(),
      'apiKey' => BusinessAuthFlow.apiKey(header: apiKeyHeader),
      'emailCode' => BusinessAuthFlow.emailCode(
        requestPath: json.optionalString('request_path', ''),
        verifyPath: json.optionalString('verify_path', ''),
        emailField: emailField,
        codeField: codeField,
      ),
      'emailCodeTotp' => BusinessAuthFlow.emailCodeTotp(
        requestPath: json.optionalString('request_path', ''),
        verifyPath: json.optionalString('verify_path', ''),
        totpPath: json.optionalString('totp_path', ''),
        emailField: emailField,
        codeField: codeField,
      ),
      'emailPassword' => BusinessAuthFlow.emailPassword(
        loginPath: json.optionalString('login_path', ''),
        emailField: emailField,
        passwordField: passwordField,
      ),
      'emailPasswordTotp' => BusinessAuthFlow.emailPasswordTotp(
        loginPath: json.optionalString('login_path', ''),
        totpPath: json.optionalString('totp_path', ''),
        emailField: emailField,
        passwordField: passwordField,
        codeField: codeField,
        challengeField: json.optionalString('challenge_field', 'totp_token'),
        challengeRequestField: json.optionalString(
          'challenge_request_field',
          'totp_token',
        ),
      ),
      'aulaMasOperator' => BusinessAuthFlow.aulaMasOperator(
        emailField: emailField,
        codeField: codeField,
      ),
      'sstOperator' => BusinessAuthFlow.sstOperator(
        emailField: emailField,
        codeField: codeField,
      ),
      _ => throw FormatException('Unknown auth_kind: $kind'),
    };
    final isLoginFlow = businessId == 'loginflow';
    return preset
        .copyWith(
          apiKeyHeader: apiKeyHeader,
          baseUrl: json.optionalString('auth_base_url', ''),
          parameters: json.stringMap('auth_parameters'),
          requiredParameters: switch ((isLoginFlow, kind)) {
            (true, 'emailCode') => const ['application_id', 'company_id'],
            (true, _) => const ['application_id'],
            (false, _) => const [],
          },
          tokenPath: kind == 'sstOperator'
              ? preset.tokenPath
              : json.optionalString('token_field', 'access_token'),
          refreshTokenField: json.optionalString(
            'refresh_token_field',
            'refresh_token',
          ),
          reusesTokenForRefresh: isLoginFlow,
          sessionIdPath: json.optionalString('session_id_field', 'session.id'),
          sessionIdField: json.optionalString(
            'session_id_request_field',
            'session_id',
          ),
          requiredRole: json.optionalString('required_role', ''),
          rolePath: json.optionalString('role_field', 'user.role'),
        )
        .withRefresh(json.optionalString('refresh_path', ''));
  }

  Map<String, Object?> toJson() => {
    'scheme': scheme.name,
    'api_key_header': apiKeyHeader,
    if (baseUrl.isNotEmpty) 'base_url': baseUrl,
    if (headers.isNotEmpty) 'headers': headers,
    if (parameters.isNotEmpty) 'parameters': parameters,
    if (requiredParameters.isNotEmpty)
      'required_parameters': requiredParameters,
    if (steps.isNotEmpty) 'steps': steps.map((step) => step.toJson()).toList(),
    'token_path': tokenPath,
    'refresh_token_field': refreshTokenField,
    if (reusesTokenForRefresh) 'reuses_token_for_refresh': true,
    'session_id_path': sessionIdPath,
    'session_id_field': sessionIdField,
    if (requiredRole.isNotEmpty) 'required_role': requiredRole,
    'role_path': rolePath,
    'enrollment_uri_path': enrollmentUriPath,
    'enrollment_secret_path': enrollmentSecretPath,
  };

  BusinessAuthFlow copyWith({
    BusinessAuthScheme? scheme,
    String? apiKeyHeader,
    String? baseUrl,
    Map<String, String>? headers,
    Map<String, String>? parameters,
    List<String>? requiredParameters,
    List<BusinessAuthStep>? steps,
    String? tokenPath,
    String? refreshTokenField,
    bool? reusesTokenForRefresh,
    String? sessionIdPath,
    String? sessionIdField,
    String? requiredRole,
    String? rolePath,
    String? enrollmentUriPath,
    String? enrollmentSecretPath,
  }) => BusinessAuthFlow(
    scheme: scheme ?? this.scheme,
    apiKeyHeader: apiKeyHeader ?? this.apiKeyHeader,
    baseUrl: baseUrl ?? this.baseUrl,
    headers: headers ?? this.headers,
    parameters: parameters ?? this.parameters,
    requiredParameters: requiredParameters ?? this.requiredParameters,
    steps: steps ?? this.steps,
    tokenPath: tokenPath ?? this.tokenPath,
    refreshTokenField: refreshTokenField ?? this.refreshTokenField,
    reusesTokenForRefresh: reusesTokenForRefresh ?? this.reusesTokenForRefresh,
    sessionIdPath: sessionIdPath ?? this.sessionIdPath,
    sessionIdField: sessionIdField ?? this.sessionIdField,
    requiredRole: requiredRole ?? this.requiredRole,
    rolePath: rolePath ?? this.rolePath,
    enrollmentUriPath: enrollmentUriPath ?? this.enrollmentUriPath,
    enrollmentSecretPath: enrollmentSecretPath ?? this.enrollmentSecretPath,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessAuthFlow &&
          scheme == other.scheme &&
          apiKeyHeader == other.apiKeyHeader &&
          baseUrl == other.baseUrl &&
          const MapEquality<String, String>().equals(headers, other.headers) &&
          const MapEquality<String, String>().equals(
            parameters,
            other.parameters,
          ) &&
          const UnorderedIterableEquality<String>().equals(
            requiredParameters,
            other.requiredParameters,
          ) &&
          const ListEquality<BusinessAuthStep>().equals(steps, other.steps) &&
          tokenPath == other.tokenPath &&
          refreshTokenField == other.refreshTokenField &&
          reusesTokenForRefresh == other.reusesTokenForRefresh &&
          sessionIdPath == other.sessionIdPath &&
          sessionIdField == other.sessionIdField &&
          requiredRole == other.requiredRole &&
          rolePath == other.rolePath &&
          enrollmentUriPath == other.enrollmentUriPath &&
          enrollmentSecretPath == other.enrollmentSecretPath;

  @override
  int get hashCode => Object.hash(
    scheme,
    apiKeyHeader,
    baseUrl,
    const MapEquality<String, String>().hash(headers),
    const MapEquality<String, String>().hash(parameters),
    const UnorderedIterableEquality<String>().hash(requiredParameters),
    Object.hashAll(steps),
    tokenPath,
    refreshTokenField,
    reusesTokenForRefresh,
    sessionIdPath,
    sessionIdField,
    requiredRole,
    rolePath,
    enrollmentUriPath,
    enrollmentSecretPath,
  );
}

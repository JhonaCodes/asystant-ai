import 'dart:convert';

import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/business/business_auth_flow.dart';
import 'package:asystant_core/src/business/business_auth_input_kind.dart';
import 'package:asystant_core/src/business/business_auth_scheme.dart';
import 'package:asystant_core/src/business/business_contract.dart';
import 'package:asystant_core/src/business/business_credential_profile.dart';
import 'package:asystant_core/src/business/business_endpoint.dart';
import 'package:asystant_core/src/business/business_environment.dart';
import 'package:asystant_core/src/business/business_failure.dart';
import 'package:asystant_core/src/business/business_failure_code.dart';
import 'package:asystant_core/src/business/business_field.dart';
import 'package:asystant_core/src/business/business_field_kind.dart';
import 'package:asystant_core/src/business/business_field_location.dart';
import 'package:asystant_core/src/business/business_header_name.dart';
import 'package:asystant_core/src/business/business_operation.dart';
import 'package:asystant_core/src/business/business_secret_name.dart';

/// The rules a contract must meet before it is saved or used.
extension BusinessContractValidation on BusinessContract {
  static final RegExp _identifier = RegExp(r'^[a-z][a-z0-9_]{1,63}$');
  static final RegExp _apiField = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{0,63}$');
  static final RegExp _dottedPath = RegExp(
    r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)*$',
  );
  static final RegExp _profileId = RegExp(r'^[a-z][a-z0-9_]{0,31}$');
  static final RegExp _apiKeyHeader = RegExp(r'^[A-Za-z][A-Za-z0-9-]*$');
  static final RegExp _placeholder = RegExp(r'\{([^}]+)\}');
  static final RegExp _credentialValue = RegExp(
    r'(bearer\s+\S+|sk-[a-z0-9]{12,})',
    caseSensitive: false,
  );

  static const Set<String> _methods = {'GET', 'POST', 'PUT', 'PATCH', 'DELETE'};

  /// Header name fragments that mark a credential, which never goes in a
  /// public header.
  static const List<String> _credentialHeaders = [
    'authorization',
    'cookie',
    'setcookie',
    'apikey',
    'token',
    'secret',
    'credential',
    'session',
  ];

  /// Field name fragments that must be typed `secret`.
  static const List<String> _secretFields = [
    'password',
    'secret',
    'token',
    'apikey',
    'privatekey',
    'authorization',
    'totp',
    'recoverycode',
    'verificationcode',
  ];

  /// Parameter name fragments that a sign-in parameter cannot have: those
  /// values are typed by the person, never stored in the contract.
  static const List<String> _secretParameters = [
    'password',
    'secret',
    'token',
    'apikey',
    'credential',
    'totp',
    'otp',
  ];

  /// The largest icon accepted, in bytes.
  static const int maxIconBytes = 512000;

  /// This contract when every rule holds; otherwise an `Err` with
  /// [BusinessFailureCode.invalidContract] naming the first broken one.
  ///
  /// Checks identifiers, the icon, each environment's addresses, headers,
  /// sign-in flow and profiles, and each operation's method, path and typed
  /// fields. [allowsOpenObjects] accepts object fields without typed
  /// members, for contracts that ship with the app; a contract written at
  /// runtime must type every member.
  Result<BusinessContract, BusinessFailure> validateContract({
    bool allowsOpenObjects = false,
  }) {
    final problem =
        _identityProblem ??
        _iconProblem ??
        _endpointsProblem ??
        _operationsProblem(allowsOpenObjects: allowsOpenObjects);
    return problem == null
        ? Ok(this)
        : Err(BusinessFailure(.invalidContract, message: problem));
  }

  String? get _identityProblem =>
      _identifier.hasMatch(id) && name.trim().isNotEmpty
      ? null
      : 'Invalid business identifier or name: the id is lower case letters, '
            'digits and underscores.';

  String? get _iconProblem {
    final icon = iconBase64;
    if (icon == null) return null;
    if (icon.length > 700000) return 'The business icon is too large.';
    final List<int> bytes;
    try {
      bytes = base64Decode(icon);
    } on FormatException {
      return 'The business icon is not valid base64.';
    }
    return bytes.isEmpty || bytes.length > maxIconBytes
        ? 'The business icon must be up to 500 KB.'
        : null;
  }

  String? get _endpointsProblem {
    for (final environment in BusinessEnvironment.values) {
      if (endpoint(environment) case final endpoint?) {
        final problem = _endpointProblem(environment, endpoint);
        if (problem != null) return problem;
      }
    }
    return null;
  }

  String? _endpointProblem(
    BusinessEnvironment environment,
    BusinessEndpoint endpoint,
  ) {
    final label = environment.name.toUpperCase();
    final auth = endpoint.auth;
    if (!_isAddress(endpoint.baseUrl, environment)) {
      return 'Invalid $label base URL: an http(s) address without '
          'credentials, query or fragment; PROD needs https.';
    }
    if (auth.baseUrl.isNotEmpty && !_isAddress(auth.baseUrl, environment)) {
      return 'Invalid $label sign-in address.';
    }
    if (!_apiKeyHeader.hasMatch(auth.apiKeyHeader)) {
      return 'Invalid $label API key header.';
    }
    if (endpoint.privateHeaders.any(
      (name) => name.toLowerCase() == auth.apiKeyHeader.toLowerCase(),
    )) {
      return 'The authentication header cannot be overridden.';
    }
    return _headersProblem(endpoint.headers, endpoint.privateHeaders) ??
        _headersProblem(auth.headers, const []) ??
        _flowProblem(label, auth) ??
        _profilesProblem(label, endpoint.profiles);
  }

  static bool _isAddress(String address, BusinessEnvironment environment) {
    final uri = Uri.tryParse(address);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      return false;
    }
    return switch (environment) {
      .prod => uri.scheme == 'https',
      .dev => uri.scheme == 'http' || uri.scheme == 'https',
    };
  }

  static bool _isRoute(String path) =>
      path.startsWith('/') &&
      !path.startsWith('//') &&
      !path.contains('..') &&
      !path.contains('?') &&
      !path.contains('#') &&
      !path.contains('://');

  static String? _headersProblem(
    Map<String, String> headers,
    List<String> privateHeaders,
  ) {
    if (headers.length + privateHeaders.length > 24) return 'Too many headers.';
    final names = <String>{};
    for (final MapEntry(key: name, :value) in headers.entries) {
      final compact = name.toLowerCase().replaceAll('-', '');
      if (!name.isBusinessHeaderName ||
          !names.add(name.toLowerCase()) ||
          _credentialHeaders.any(compact.contains) ||
          value.length > 512 ||
          value.contains('\r') ||
          value.contains('\n') ||
          _credentialValue.hasMatch(value)) {
        return 'Invalid public header $name: credentials go in private '
            'headers.';
      }
    }
    for (final name in privateHeaders) {
      if (!name.isBusinessHeaderName || !names.add(name.toLowerCase())) {
        return 'Invalid or duplicate private header $name.';
      }
    }
    return null;
  }

  static String? _flowProblem(String label, BusinessAuthFlow flow) {
    if (flow.steps.length > 8) return 'Too many $label sign-in steps.';
    if (flow.steps.where((step) => step.kind == .refresh).length > 1) {
      return '$label has more than one refresh step.';
    }
    final inputKinds = <String, BusinessAuthInputKind>{};
    for (final (index, step) in flow.signInSteps.indexed) {
      if (!_isRoute(step.path)) {
        return 'Invalid $label sign-in route "${step.path}": it starts with '
            '/ and has no query.';
      }
      if (index == 0 && step.carry.isNotEmpty) {
        return 'The first $label sign-in step has no previous answer to '
            'carry values from.';
      }
      if (step.inputs.length > 8) return 'Too many inputs in a sign-in step.';
      if (step.continueFlag.isNotEmpty &&
          !_dottedPath.hasMatch(step.continueFlag)) {
        return 'Invalid continue_flag ${step.continueFlag}.';
      }
      final members = <String>{
        if (step.sendsParameters) ...flow.parameters.keys,
      };
      for (final input in step.inputs) {
        if (!_apiField.hasMatch(input.name) ||
            !_apiField.hasMatch(input.field) ||
            input.label.length > 64) {
          return 'Invalid sign-in input ${input.name}.';
        }
        if (!members.add(input.field)) {
          return 'The sign-in step ${step.path} sends ${input.field} twice.';
        }
        if (inputKinds.putIfAbsent(input.name, () => input.kind) !=
            input.kind) {
          return 'The sign-in input ${input.name} has two kinds.';
        }
      }
      for (final MapEntry(key: member, value: path) in step.carry.entries) {
        if (!_apiField.hasMatch(member) || !_dottedPath.hasMatch(path)) {
          return 'Invalid carried value $member.';
        }
        if (!members.add(member)) {
          return 'The sign-in step ${step.path} sends $member twice.';
        }
      }
    }
    if (flow.refreshStep case final refresh?) {
      if (!_isRoute(refresh.path))
        return 'Invalid $label session renewal route.';
      if (refresh.inputs.isNotEmpty || refresh.carry.isNotEmpty) {
        return 'The refresh step takes no inputs.';
      }
    }
    if (![
          flow.tokenPath,
          flow.rolePath,
          flow.sessionIdPath,
          flow.enrollmentUriPath,
          flow.enrollmentSecretPath,
        ].every(_dottedPath.hasMatch) ||
        !_apiField.hasMatch(flow.refreshTokenField) ||
        !_apiField.hasMatch(flow.sessionIdField) ||
        flow.requiredRole.length > 64) {
      return 'Invalid $label sign-in response path or field.';
    }
    return _parametersProblem(label, flow);
  }

  static String? _parametersProblem(String label, BusinessAuthFlow flow) {
    if (flow.parameters.length > 20) {
      return 'Too many $label sign-in parameters.';
    }
    for (final MapEntry(key: name, :value) in flow.parameters.entries) {
      if (!_apiField.hasMatch(name) ||
          value.length > 256 ||
          _secretParameters.any(name.normalizedBusinessName.contains)) {
        return 'Invalid sign-in parameter $name: secrets are typed by the '
            'person, never stored in the contract.';
      }
    }
    for (final name in flow.requiredParameters) {
      if (flow.parameters[name]?.trim().isEmpty ?? true) {
        return 'The $label sign-in parameter $name is required.';
      }
    }
    return null;
  }

  static String? _profilesProblem(
    String label,
    List<BusinessCredentialProfile> profiles,
  ) {
    if (profiles.length > 8) return 'Too many $label credential profiles.';
    final ids = <String>{};
    for (final profile in profiles) {
      if (!_profileId.hasMatch(profile.id) ||
          !ids.add(profile.id) ||
          profile.label.length > 64) {
        return 'Invalid or duplicate $label credential profile ${profile.id}.';
      }
    }
    return null;
  }

  String? _operationsProblem({required bool allowsOpenObjects}) {
    final used = <String>{};
    final apiKeyHeaders = {
      for (final environment in environments)
        if (endpoint(environment)?.auth case final auth?
            when auth.scheme == BusinessAuthScheme.apiKey)
          auth.apiKeyHeader.toLowerCase(),
    };
    for (final operation in operations) {
      if (!_identifier.hasMatch(operation.id) ||
          !used.add(operation.id) ||
          !_methods.contains(operation.method) ||
          !_isRoute(operation.path) ||
          operation.path.contains('%')) {
        return 'Invalid operation ${operation.id}: a unique lower-case id, '
            'GET/POST/PUT/PATCH/DELETE and a path that starts with /.';
      }
      final problem =
          _headersProblem(operation.headers, operation.privateHeaders) ??
          (operation.privateHeaders.any(
                (name) => apiKeyHeaders.contains(name.toLowerCase()),
              )
              ? 'The authentication header cannot be overridden.'
              : null) ??
          _fieldsProblem(
            operation,
            apiKeyHeaders,
            allowsOpenObjects: allowsOpenObjects,
          );
      if (problem != null) return problem;
    }
    return null;
  }

  static String? _fieldsProblem(
    BusinessOperation operation,
    Set<String> apiKeyHeaders, {
    required bool allowsOpenObjects,
  }) {
    final names = <String>{};
    for (final field in operation.fields) {
      final problem = _fieldProblem(field, names, depth: 0);
      if (problem != null) return problem;
      if (!allowsOpenObjects && _hasOpenObject(field)) {
        return 'Object field ${field.name} needs typed members.';
      }
      if (field.location == BusinessFieldLocation.path &&
          !operation.path.contains('{${field.name}}')) {
        return 'Missing path parameter {${field.name}} in ${operation.path}.';
      }
      if (field.location != BusinessFieldLocation.body &&
          (field.kind == BusinessFieldKind.object ||
              field.kind == BusinessFieldKind.list ||
              (field.kind == BusinessFieldKind.secret &&
                  field.location != BusinessFieldLocation.header))) {
        return 'Structured values belong in the body: ${field.name}.';
      }
      if (field.location == BusinessFieldLocation.header &&
          (!field.name.isBusinessHeaderName ||
              apiKeyHeaders.contains(field.name.toLowerCase()))) {
        return 'Invalid or reserved header field ${field.name}.';
      }
      if (operation.isRead && field.location == BusinessFieldLocation.body) {
        return 'GET operations cannot have a body: ${field.name}.';
      }
    }
    for (final placeholder in _placeholder.allMatches(operation.path)) {
      if (!names.contains(placeholder.group(1))) {
        return 'Undeclared path parameter in ${operation.path}.';
      }
    }
    return null;
  }

  static bool _hasOpenObject(BusinessField field) =>
      field.allowsAdditionalProperties ||
      field.properties.any(_hasOpenObject) ||
      switch (field.item) {
        final BusinessField item => _hasOpenObject(item),
        null => false,
      };

  static String? _fieldProblem(
    BusinessField field,
    Set<String> names, {
    required int depth,
  }) {
    final validName =
        field.location == BusinessFieldLocation.header && depth == 0
        ? field.name.isBusinessHeaderName
        : _apiField.hasMatch(field.name);
    if (depth > 6 || !validName || !names.add(field.name)) {
      return 'Invalid or duplicate field ${field.name}.';
    }
    final normalized = field.name.normalizedBusinessName;
    final isSecretName =
        _secretFields.any(normalized.contains) || normalized == 'otp';
    if (isSecretName && field.kind != BusinessFieldKind.secret) {
      return 'Field ${field.name} must be of kind secret: the person types '
          'it on the device.';
    }
    if (field.options.isNotEmpty &&
        (field.kind != BusinessFieldKind.string ||
            field.options.length > 50 ||
            field.options.any(
              (option) => option.trim().isEmpty || option.length > 100,
            ) ||
            field.options.toSet().length != field.options.length)) {
      return 'Invalid choices for ${field.name}.';
    }
    final isNumeric =
        field.kind == BusinessFieldKind.integer ||
        field.kind == BusinessFieldKind.number;
    final (minimum, maximum) = (field.minimum, field.maximum);
    if ((minimum != null || maximum != null) &&
        (!isNumeric ||
            (minimum != null && maximum != null && minimum > maximum))) {
      return 'Invalid numeric limits for ${field.name}.';
    }
    if (field.kind == BusinessFieldKind.secret && depth > 0) {
      return 'Secret field ${field.name} must be top-level.';
    }
    return switch (field.kind) {
      .object => _objectProblem(field, depth),
      .list => _listProblem(field, depth),
      .string || .integer || .number || .boolean || .secret =>
        field.properties.isNotEmpty ||
                field.item != null ||
                field.allowsAdditionalProperties
            ? 'Scalar field ${field.name} cannot have members.'
            : null,
    };
  }

  static String? _objectProblem(BusinessField field, int depth) {
    if ((field.properties.isEmpty && !field.allowsAdditionalProperties) ||
        field.item != null) {
      return 'Object field ${field.name} needs typed properties.';
    }
    final nested = <String>{};
    for (final property in field.properties) {
      final problem = _fieldProblem(property, nested, depth: depth + 1);
      if (problem != null) return problem;
    }
    return null;
  }

  static String? _listProblem(BusinessField field, int depth) {
    final item = field.item;
    if (item == null || field.properties.isNotEmpty) {
      return 'List field ${field.name} needs an item type.';
    }
    return _fieldProblem(item, <String>{}, depth: depth + 1);
  }
}

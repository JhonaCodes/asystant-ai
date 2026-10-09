import 'package:collection/collection.dart';
import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/business/business_endpoint.dart';
import 'package:asystant_core/src/business/business_environment.dart';
import 'package:asystant_core/src/business/business_failure.dart';
import 'package:asystant_core/src/business/business_json_reading.dart';
import 'package:asystant_core/src/business/business_operation.dart';

/// The public, typed description of a business API: its environments and
/// the operations an assistant may run. It never holds a credential; those
/// live in a `BusinessCredentialStore`.
class BusinessContract {
  const BusinessContract({
    required this.id,
    required this.name,
    required this.operations,
    this.iconBase64,
    this.dev,
    this.prod,
  });

  /// Lower-case identifier, such as `loginflow`.
  final String id;

  final String name;

  /// PNG or JPEG bytes in base64, up to 500 KB.
  final String? iconBase64;

  final BusinessEndpoint? dev;
  final BusinessEndpoint? prod;
  final List<BusinessOperation> operations;

  /// The endpoint of [environment], if configured.
  BusinessEndpoint? endpoint(BusinessEnvironment environment) =>
      switch (environment) {
        .dev => dev,
        .prod => prod,
      };

  /// The environments that have an endpoint.
  List<BusinessEnvironment> get environments => [
    for (final environment in BusinessEnvironment.values)
      if (endpoint(environment) != null) environment,
  ];

  /// A copy whose [environment] uses [next], the other one untouched.
  BusinessContract withEndpoint(
    BusinessEnvironment environment,
    BusinessEndpoint next,
  ) => switch (environment) {
    .dev => copyWith(dev: next),
    .prod => copyWith(prod: next),
  };

  /// The operation [operationId], if registered.
  BusinessOperation? operation(String operationId) =>
      operations.firstWhereOrNull((operation) => operation.id == operationId);

  /// Reads a contract from untrusted JSON, such as one a model wrote or one
  /// synced from a server, in either contract format (see
  /// [BusinessEndpoint.fromJson]). It does not validate it: see
  /// `validateContract`.
  static Result<BusinessContract, BusinessFailure> parse(Object? json) {
    if (json is! Map) {
      return Err(
        const BusinessFailure(
          .invalidContract,
          message: 'The contract must be a JSON object.',
        ),
      );
    }
    try {
      return Ok(BusinessContract.fromJson(json.cast<String, Object?>()));
    } on FormatException catch (error) {
      return Err(BusinessFailure(.invalidContract, message: error.message));
    } on TypeError {
      return Err(
        const BusinessFailure(
          .invalidContract,
          message: 'A contract member has the wrong type.',
        ),
      );
    }
  }

  factory BusinessContract.fromJson(Map<String, Object?> json) {
    final id = json.requiredString('id');
    return BusinessContract(
      id: id,
      name: json.requiredString('name'),
      iconBase64: switch (json['icon_base64']) {
        final String icon => icon,
        _ => null,
      },
      dev: switch (json.optionalObject('dev')) {
        final Map<String, Object?> dev => BusinessEndpoint.fromJson(
          dev,
          businessId: id,
        ),
        null => null,
      },
      prod: switch (json.optionalObject('prod')) {
        final Map<String, Object?> prod => BusinessEndpoint.fromJson(
          prod,
          businessId: id,
        ),
        null => null,
      },
      operations: [
        for (final operation in json.objectList('operations'))
          BusinessOperation.fromJson(operation),
      ],
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'icon_base64': ?iconBase64,
    'dev': ?dev?.toJson(),
    'prod': ?prod?.toJson(),
    'operations': operations.map((operation) => operation.toJson()).toList(),
  };

  BusinessContract copyWith({
    String? id,
    String? name,
    String? iconBase64,
    BusinessEndpoint? dev,
    BusinessEndpoint? prod,
    List<BusinessOperation>? operations,
  }) => BusinessContract(
    id: id ?? this.id,
    name: name ?? this.name,
    iconBase64: iconBase64 ?? this.iconBase64,
    dev: dev ?? this.dev,
    prod: prod ?? this.prod,
    operations: operations ?? this.operations,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessContract &&
          id == other.id &&
          name == other.name &&
          iconBase64 == other.iconBase64 &&
          dev == other.dev &&
          prod == other.prod &&
          const ListEquality<BusinessOperation>().equals(
            operations,
            other.operations,
          );

  @override
  int get hashCode =>
      Object.hash(id, name, iconBase64, dev, prod, Object.hashAll(operations));
}

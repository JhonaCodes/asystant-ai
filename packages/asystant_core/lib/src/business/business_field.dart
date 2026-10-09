import 'package:collection/collection.dart';

import 'package:asystant_core/src/business/business_field_kind.dart';
import 'package:asystant_core/src/business/business_field_location.dart';
import 'package:asystant_core/src/business/business_json_reading.dart';

/// One typed parameter of a [BusinessOperation]: its JSON [kind], where it
/// travels ([location]) and the limits it must respect.
class BusinessField {
  const BusinessField({
    required this.name,
    required this.kind,
    required this.location,
    this.isRequired = true,
    this.properties = const [],
    this.item,
    this.allowsAdditionalProperties = false,
    this.options = const [],
    this.minimum,
    this.maximum,
  });

  final String name;
  final BusinessFieldKind kind;
  final BusinessFieldLocation location;
  final bool isRequired;

  /// Typed members of an [BusinessFieldKind.object]. Unknown members are
  /// rejected unless [allowsAdditionalProperties].
  final List<BusinessField> properties;

  /// Typed element of a [BusinessFieldKind.list].
  final BusinessField? item;

  final bool allowsAdditionalProperties;

  /// The only values a string accepts; any when empty.
  final List<String> options;

  final num? minimum;
  final num? maximum;

  factory BusinessField.fromJson(Map<String, Object?> json) => BusinessField(
    name: json.requiredString('name'),
    kind: json.enumValue(BusinessFieldKind.values, 'kind'),
    location: json.enumValue(BusinessFieldLocation.values, 'location'),
    isRequired: json.optionalBool('required', fallback: true),
    properties: [
      for (final property in json.objectList('properties'))
        BusinessField.fromJson(property),
    ],
    item: switch (json.optionalObject('item')) {
      final Map<String, Object?> item => BusinessField.fromJson(item),
      null => null,
    },
    allowsAdditionalProperties: json.optionalBool(
      'additional_properties',
      fallback: false,
    ),
    options: json.stringList('options'),
    minimum: json['minimum'] as num?,
    maximum: json['maximum'] as num?,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'kind': kind.name,
    'location': location.name,
    'required': isRequired,
    if (properties.isNotEmpty)
      'properties': properties.map((property) => property.toJson()).toList(),
    'item': ?item?.toJson(),
    if (allowsAdditionalProperties) 'additional_properties': true,
    if (options.isNotEmpty) 'options': options,
    'minimum': ?minimum,
    'maximum': ?maximum,
  };

  BusinessField copyWith({
    String? name,
    BusinessFieldKind? kind,
    BusinessFieldLocation? location,
    bool? isRequired,
    List<BusinessField>? properties,
    BusinessField? item,
    bool? allowsAdditionalProperties,
    List<String>? options,
    num? minimum,
    num? maximum,
  }) => BusinessField(
    name: name ?? this.name,
    kind: kind ?? this.kind,
    location: location ?? this.location,
    isRequired: isRequired ?? this.isRequired,
    properties: properties ?? this.properties,
    item: item ?? this.item,
    allowsAdditionalProperties:
        allowsAdditionalProperties ?? this.allowsAdditionalProperties,
    options: options ?? this.options,
    minimum: minimum ?? this.minimum,
    maximum: maximum ?? this.maximum,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessField &&
          name == other.name &&
          kind == other.kind &&
          location == other.location &&
          isRequired == other.isRequired &&
          const ListEquality<BusinessField>().equals(
            properties,
            other.properties,
          ) &&
          item == other.item &&
          allowsAdditionalProperties == other.allowsAdditionalProperties &&
          const ListEquality<String>().equals(options, other.options) &&
          minimum == other.minimum &&
          maximum == other.maximum;

  @override
  int get hashCode => Object.hash(
    name,
    kind,
    location,
    isRequired,
    Object.hashAll(properties),
    item,
    allowsAdditionalProperties,
    Object.hashAll(options),
    minimum,
    maximum,
  );
}

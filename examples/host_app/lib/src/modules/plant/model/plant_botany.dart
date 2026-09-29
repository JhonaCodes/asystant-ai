import 'package:collection/collection.dart';

/// What botany says about the plant: how it looks, how to grow it and what
/// it can be confused with.
class PlantBotany {
  const PlantBotany({
    this.description = '',
    this.identification = '',
    this.cultivation = '',
    this.lookalikes = const [],
    this.nativeRange = '',
    this.sources = const [],
  });

  factory PlantBotany.fromJson(Map<String, Object?> json) => PlantBotany(
    description: json['description'] as String? ?? '',
    identification: json['identification'] as String? ?? '',
    cultivation: json['cultivation'] as String? ?? '',
    lookalikes: List.unmodifiable(
      (json['lookalikes'] as List<Object?>? ?? const []).cast<String>(),
    ),
    nativeRange: json['nativeRange'] as String? ?? '',
    sources: List.unmodifiable(
      (json['sources'] as List<Object?>? ?? const []).cast<String>(),
    ),
  );

  /// What the plant is like, in plain words.
  final String description;

  /// How to recognize it in a garden or a market.
  final String identification;

  /// How to grow it at home: light, water, climate, how it spreads.
  final String cultivation;

  /// Plants it can be mistaken for, dangerous ones first.
  final List<String> lookalikes;

  /// Where it comes from and where it grows today.
  final String nativeRange;

  /// Ids of the plant's sources that back this section.
  final List<String> sources;

  bool get isEmpty =>
      description.isEmpty &&
      identification.isEmpty &&
      cultivation.isEmpty &&
      lookalikes.isEmpty &&
      nativeRange.isEmpty;

  PlantBotany copyWith({
    String? description,
    String? identification,
    String? cultivation,
    List<String>? lookalikes,
    String? nativeRange,
    List<String>? sources,
  }) => PlantBotany(
    description: description ?? this.description,
    identification: identification ?? this.identification,
    cultivation: cultivation ?? this.cultivation,
    lookalikes: List.unmodifiable(lookalikes ?? this.lookalikes),
    nativeRange: nativeRange ?? this.nativeRange,
    sources: List.unmodifiable(sources ?? this.sources),
  );

  Map<String, Object?> toJson() => {
    'description': description,
    'identification': identification,
    'cultivation': cultivation,
    'lookalikes': lookalikes,
    'nativeRange': nativeRange,
    'sources': sources,
  };

  @override
  bool operator ==(Object other) =>
      other is PlantBotany &&
      const DeepCollectionEquality().equals(toJson(), other.toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());

  @override
  String toString() =>
      'PlantBotany(${nativeRange.isEmpty ? '-' : nativeRange})';
}

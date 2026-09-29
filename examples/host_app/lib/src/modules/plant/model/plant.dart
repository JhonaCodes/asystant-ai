import 'package:collection/collection.dart';

import 'package:host_app/src/modules/plant/model/plant_belief.dart';
import 'package:host_app/src/modules/plant/model/plant_botany.dart';
import 'package:host_app/src/modules/plant/model/plant_enums.dart';
import 'package:host_app/src/modules/plant/model/plant_indication.dart';
import 'package:host_app/src/modules/plant/model/plant_media.dart';
import 'package:host_app/src/modules/plant/model/plant_safety.dart';
import 'package:host_app/src/modules/plant/model/preparation.dart';

/// A medicinal plant: what it is for, how to take it and when not to.
class Plant {
  const Plant({
    required this.id,
    required this.commonName,
    this.otherNames = const [],
    this.scientificName = '',
    this.family = '',
    this.partsUsed = const [],
    this.easyExplanation = '',
    this.botany = const PlantBotany(),
    this.beliefs = const [],
    this.indications = const [],
    this.preparations = const [],
    this.contraindications = const [],
    this.interactions = const [],
    this.pregnancy = SafetyGuidance.notEstablished,
    this.lactation = SafetyGuidance.notEstablished,
    this.minAgeYears,
    this.allergenGroups = const [],
    this.sideEffects = const [],
    this.photos = const [],
    this.sources = const [],
    this.safetySources = const [],
    this.origin = PlantOrigin.person,
    this.createdAt,
    this.updatedAt,
  });

  factory Plant.fromJson(Map<String, Object?> json) => Plant(
    id: json['id'] as String,
    commonName: json['commonName'] as String,
    otherNames: _strings(json['otherNames']),
    scientificName: json['scientificName'] as String? ?? '',
    family: json['family'] as String? ?? '',
    partsUsed: _strings(json['partsUsed']),
    easyExplanation: json['easyExplanation'] as String? ?? '',
    botany: switch (json['botany']) {
      final Map<String, Object?> botany => PlantBotany.fromJson(botany),
      _ => const PlantBotany(),
    },
    beliefs: _list(json['beliefs'], PlantBelief.fromJson),
    indications: _list(json['indications'], PlantIndication.fromJson),
    preparations: _list(json['preparations'], Preparation.fromJson),
    contraindications: _list(
      json['contraindications'],
      Contraindication.fromJson,
    ),
    interactions: _list(json['interactions'], PlantInteraction.fromJson),
    pregnancy: SafetyGuidance.values.byName(
      json['pregnancy'] as String? ?? SafetyGuidance.notEstablished.name,
    ),
    lactation: SafetyGuidance.values.byName(
      json['lactation'] as String? ?? SafetyGuidance.notEstablished.name,
    ),
    minAgeYears: json['minAgeYears'] as int?,
    allergenGroups: _strings(json['allergenGroups']),
    sideEffects: _strings(json['sideEffects']),
    photos: _list(json['photos'], PlantPhoto.fromJson),
    sources: _list(json['sources'], PlantSource.fromJson),
    safetySources: _strings(json['safetySources']),
    origin: PlantOrigin.values.byName(
      json['origin'] as String? ?? PlantOrigin.person.name,
    ),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );

  final String id;

  final String commonName;

  final List<String> otherNames;

  final String scientificName;

  final String family;

  final List<String> partsUsed;

  /// What the plant is and does, in plain words for anyone.
  final String easyExplanation;

  final List<PlantIndication> indications;

  final List<Preparation> preparations;

  final List<Contraindication> contraindications;

  final List<PlantInteraction> interactions;

  final SafetyGuidance pregnancy;

  final SafetyGuidance lactation;

  final int? minAgeYears;

  final List<String> allergenGroups;

  final List<String> sideEffects;

  final List<PlantPhoto> photos;

  final List<PlantSource> sources;

  /// Ids of the sources behind pregnancy, lactation, age, contraindications,
  /// interactions and side effects.
  final List<String> safetySources;

  /// How it looks, how to grow it and what it is confused with.
  final PlantBotany botany;

  /// Popular beliefs that are not safe to act on, with what is known.
  final List<PlantBelief> beliefs;

  final PlantOrigin origin;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  bool get isSeed => origin == PlantOrigin.seed;

  PlantPhoto? get mainPhoto => photos.firstOrNull;

  /// "Matricaria chamomilla L. · Asteraceae".
  String get botanicalLine =>
      [scientificName, family].where((part) => part.isNotEmpty).join(' · ');

  /// A bundled plant with no use safe enough to recommend: it is only shown.
  bool get hasNoSafeUse => isSeed && indications.isEmpty;

  /// Uses that studies or an official monograph back.
  List<PlantIndication> get scienceUses =>
      indications.where((item) => !item.isPopular).toList();

  /// Uses that only popular belief backs.
  List<PlantIndication> get popularUses =>
      indications.where((item) => item.isPopular).toList();

  /// The sources that speak for [kind].
  List<PlantSource> sourcesOf(SourceKind kind) =>
      sources.where((source) => source.kind == kind).toList();

  /// What it is used for, in one line: "Digestión · Tos".
  String get usesLine => indications.map((item) => item.label).join(' · ');

  /// The ways to take it for [tags]; all of them when none is linked to
  /// those uses, so the person still sees how the plant is taken.
  List<Preparation> preparationsFor(Set<String> tags) =>
      switch (preparations.where((item) => item.isFor(tags)).toList()) {
        [] => preparations,
        final linked => linked,
      };

  /// Every name the plant goes by, for search.
  List<String> get names => [commonName, scientificName, ...otherNames];

  Plant copyWith({
    String? id,
    String? commonName,
    List<String>? otherNames,
    String? scientificName,
    String? family,
    List<String>? partsUsed,
    String? easyExplanation,
    PlantBotany? botany,
    List<PlantBelief>? beliefs,
    List<PlantIndication>? indications,
    List<Preparation>? preparations,
    List<Contraindication>? contraindications,
    List<PlantInteraction>? interactions,
    SafetyGuidance? pregnancy,
    SafetyGuidance? lactation,
    int? minAgeYears,
    List<String>? allergenGroups,
    List<String>? sideEffects,
    List<PlantPhoto>? photos,
    List<PlantSource>? sources,
    List<String>? safetySources,
    PlantOrigin? origin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Plant(
    id: id ?? this.id,
    commonName: commonName ?? this.commonName,
    otherNames: List.unmodifiable(otherNames ?? this.otherNames),
    scientificName: scientificName ?? this.scientificName,
    family: family ?? this.family,
    partsUsed: List.unmodifiable(partsUsed ?? this.partsUsed),
    easyExplanation: easyExplanation ?? this.easyExplanation,
    botany: botany ?? this.botany,
    beliefs: List.unmodifiable(beliefs ?? this.beliefs),
    indications: List.unmodifiable(indications ?? this.indications),
    preparations: List.unmodifiable(preparations ?? this.preparations),
    contraindications: List.unmodifiable(
      contraindications ?? this.contraindications,
    ),
    interactions: List.unmodifiable(interactions ?? this.interactions),
    pregnancy: pregnancy ?? this.pregnancy,
    lactation: lactation ?? this.lactation,
    minAgeYears: minAgeYears ?? this.minAgeYears,
    allergenGroups: List.unmodifiable(allergenGroups ?? this.allergenGroups),
    sideEffects: List.unmodifiable(sideEffects ?? this.sideEffects),
    photos: List.unmodifiable(photos ?? this.photos),
    sources: List.unmodifiable(sources ?? this.sources),
    safetySources: List.unmodifiable(safetySources ?? this.safetySources),
    origin: origin ?? this.origin,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'commonName': commonName,
    'otherNames': otherNames,
    'scientificName': scientificName,
    'family': family,
    'partsUsed': partsUsed,
    'easyExplanation': easyExplanation,
    'botany': botany.toJson(),
    'beliefs': beliefs.map((item) => item.toJson()).toList(),
    'indications': indications.map((item) => item.toJson()).toList(),
    'preparations': preparations.map((item) => item.toJson()).toList(),
    'contraindications': contraindications
        .map((item) => item.toJson())
        .toList(),
    'interactions': interactions.map((item) => item.toJson()).toList(),
    'pregnancy': pregnancy.name,
    'lactation': lactation.name,
    'minAgeYears': minAgeYears,
    'allergenGroups': allergenGroups,
    'sideEffects': sideEffects,
    'photos': photos.map((item) => item.toJson()).toList(),
    'sources': sources.map((item) => item.toJson()).toList(),
    'safetySources': safetySources,
    'origin': origin.name,
  };

  static const _deep = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      other is Plant && _deep.equals(toJson(), other.toJson());

  @override
  int get hashCode => _deep.hash(toJson());

  @override
  String toString() => 'Plant($id, ${origin.name})';

  static List<String> _strings(Object? value) =>
      List.unmodifiable((value as List<Object?>? ?? const []).cast<String>());

  static List<T> _list<T>(
    Object? value,
    T Function(Map<String, Object?> json) fromJson,
  ) => List.unmodifiable(
    (value as List<Object?>? ?? const []).map(
      (item) => fromJson(item as Map<String, Object?>),
    ),
  );
}

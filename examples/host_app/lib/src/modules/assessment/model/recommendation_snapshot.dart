import 'package:collection/collection.dart';

import 'package:host_app/src/modules/plant/model/preparation.dart';

/// The outcome of a recommendation.
enum RecommendationStatus {
  /// Plants were found for the symptoms and goals.
  recommended,

  /// A warning sign was found: see a doctor, no plants.
  seeDoctor,

  /// Data needed to recommend safely is missing.
  needsInformation,

  /// Plants matched, but every one is unsafe for this person.
  allExcluded,

  /// No plant in the catalog covers these symptoms or goals.
  noMatch,
}

/// Data the assistant still has to ask before recommending.
enum MissingData { age, pregnancy, lactation, symptoms }

/// Why a matching plant was left out.
enum ExclusionKind {
  age,
  pregnancy,
  lactation,
  condition,
  allergy,
  interaction,
  notCurated,
}

/// A warning sign that fired.
class RedFlagHit {
  const RedFlagHit({
    required this.ruleId,
    required this.label,
    required this.advice,
  });

  factory RedFlagHit.fromJson(Map<String, Object?> json) => RedFlagHit(
    ruleId: json['ruleId'] as String,
    label: json['label'] as String,
    advice: json['advice'] as String,
  );

  final String ruleId;

  final String label;

  final String advice;

  RedFlagHit copyWith({String? ruleId, String? label, String? advice}) =>
      RedFlagHit(
        ruleId: ruleId ?? this.ruleId,
        label: label ?? this.label,
        advice: advice ?? this.advice,
      );

  Map<String, Object?> toJson() => {
    'ruleId': ruleId,
    'label': label,
    'advice': advice,
  };

  @override
  bool operator ==(Object other) =>
      other is RedFlagHit &&
      ruleId == other.ruleId &&
      label == other.label &&
      advice == other.advice;

  @override
  int get hashCode => Object.hash(ruleId, label, advice);

  @override
  String toString() => 'RedFlagHit($ruleId)';
}

class ExclusionReason {
  const ExclusionReason({required this.kind, this.detail = ''});

  factory ExclusionReason.fromJson(Map<String, Object?> json) =>
      ExclusionReason(
        kind: ExclusionKind.values.byName(json['kind'] as String),
        detail: json['detail'] as String? ?? '',
      );

  final ExclusionKind kind;

  /// The readable condition, medicine or allergen behind the reason.
  final String detail;

  ExclusionReason copyWith({ExclusionKind? kind, String? detail}) =>
      ExclusionReason(kind: kind ?? this.kind, detail: detail ?? this.detail);

  Map<String, Object?> toJson() => {'kind': kind.name, 'detail': detail};

  @override
  bool operator ==(Object other) =>
      other is ExclusionReason && kind == other.kind && detail == other.detail;

  @override
  int get hashCode => Object.hash(kind, detail);

  @override
  String toString() => 'ExclusionReason(${kind.name})';
}

/// A matching plant that was left out, and why.
class ExcludedPlant {
  const ExcludedPlant({
    required this.plantId,
    required this.commonName,
    this.reasons = const [],
  });

  factory ExcludedPlant.fromJson(Map<String, Object?> json) => ExcludedPlant(
    plantId: json['plantId'] as String,
    commonName: json['commonName'] as String,
    reasons: List.unmodifiable(
      (json['reasons'] as List<Object?>? ?? const []).map(
        (reason) => ExclusionReason.fromJson(reason as Map<String, Object?>),
      ),
    ),
  );

  final String plantId;

  final String commonName;

  final List<ExclusionReason> reasons;

  ExcludedPlant copyWith({
    String? plantId,
    String? commonName,
    List<ExclusionReason>? reasons,
  }) => ExcludedPlant(
    plantId: plantId ?? this.plantId,
    commonName: commonName ?? this.commonName,
    reasons: List.unmodifiable(reasons ?? this.reasons),
  );

  Map<String, Object?> toJson() => {
    'plantId': plantId,
    'commonName': commonName,
    'reasons': reasons.map((reason) => reason.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      other is ExcludedPlant &&
      plantId == other.plantId &&
      commonName == other.commonName &&
      const ListEquality<ExclusionReason>().equals(reasons, other.reasons);

  @override
  int get hashCode => Object.hash(plantId, commonName, Object.hashAll(reasons));

  @override
  String toString() => 'ExcludedPlant($plantId)';
}

/// A recommended plant, copied so the record survives catalog changes.
class PlantSuggestion {
  const PlantSuggestion({
    required this.plantId,
    required this.commonName,
    required this.score,
    this.scientificName = '',
    this.photoRef = '',
    this.matched = const [],
    this.easyExplanation = '',
    this.preparations = const [],
    this.cautions = const [],
    this.popularOnly = false,
  });

  factory PlantSuggestion.fromJson(Map<String, Object?> json) =>
      PlantSuggestion(
        plantId: json['plantId'] as String,
        commonName: json['commonName'] as String,
        score: json['score'] as int,
        scientificName: json['scientificName'] as String? ?? '',
        photoRef: json['photoRef'] as String? ?? '',
        matched: List.unmodifiable(
          (json['matched'] as List<Object?>? ?? const []).cast<String>(),
        ),
        easyExplanation: json['easyExplanation'] as String? ?? '',
        preparations: List.unmodifiable(
          (json['preparations'] as List<Object?>? ?? const []).map(
            (item) => Preparation.fromJson(item as Map<String, Object?>),
          ),
        ),
        cautions: List.unmodifiable(
          (json['cautions'] as List<Object?>? ?? const []).cast<String>(),
        ),
        popularOnly: json['popularOnly'] as bool? ?? false,
      );

  final String plantId;

  final String commonName;

  final int score;

  final String scientificName;

  /// The photo shown so the person recognizes the plant.
  final String photoRef;

  /// Labels of the symptoms and goals the plant covers.
  final List<String> matched;

  final String easyExplanation;

  final List<Preparation> preparations;

  /// Things to watch for this person, e.g. a medicine to use with caution.
  final List<String> cautions;

  /// Whether only popular belief backs it for what the person has.
  final bool popularOnly;

  String get matchedLine => matched.join(', ');

  PlantSuggestion copyWith({
    String? plantId,
    String? commonName,
    int? score,
    String? scientificName,
    String? photoRef,
    List<String>? matched,
    String? easyExplanation,
    List<Preparation>? preparations,
    List<String>? cautions,
    bool? popularOnly,
  }) => PlantSuggestion(
    plantId: plantId ?? this.plantId,
    commonName: commonName ?? this.commonName,
    score: score ?? this.score,
    scientificName: scientificName ?? this.scientificName,
    photoRef: photoRef ?? this.photoRef,
    matched: List.unmodifiable(matched ?? this.matched),
    easyExplanation: easyExplanation ?? this.easyExplanation,
    preparations: List.unmodifiable(preparations ?? this.preparations),
    cautions: List.unmodifiable(cautions ?? this.cautions),
    popularOnly: popularOnly ?? this.popularOnly,
  );

  Map<String, Object?> toJson() => {
    'plantId': plantId,
    'commonName': commonName,
    'score': score,
    'scientificName': scientificName,
    'photoRef': photoRef,
    'matched': matched,
    'easyExplanation': easyExplanation,
    'preparations': preparations.map((item) => item.toJson()).toList(),
    'cautions': cautions,
    'popularOnly': popularOnly,
  };

  @override
  bool operator ==(Object other) =>
      other is PlantSuggestion &&
      const DeepCollectionEquality().equals(toJson(), other.toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());

  @override
  String toString() => 'PlantSuggestion($plantId, $score)';
}

/// What the engine concluded for an assessment, at a point in time.
class RecommendationSnapshot {
  const RecommendationSnapshot({
    required this.status,
    required this.generatedAt,
    this.redFlags = const [],
    this.suggestions = const [],
    this.excluded = const [],
    this.uncovered = const [],
    this.missing = const [],
    this.basis = '',
    this.referenceVersion = 0,
  });

  factory RecommendationSnapshot.fromJson(Map<String, Object?> json) =>
      RecommendationSnapshot(
        status: RecommendationStatus.values.byName(json['status'] as String),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
        redFlags: _list(json['redFlags'], RedFlagHit.fromJson),
        suggestions: _list(json['suggestions'], PlantSuggestion.fromJson),
        excluded: _list(json['excluded'], ExcludedPlant.fromJson),
        uncovered: List.unmodifiable(
          (json['uncovered'] as List<Object?>? ?? const []).cast<String>(),
        ),
        missing: List.unmodifiable(
          (json['missing'] as List<Object?>? ?? const []).map(
            (item) => MissingData.values.byName(item as String),
          ),
        ),
        basis: json['basis'] as String? ?? '',
        referenceVersion: json['referenceVersion'] as int? ?? 0,
      );

  final RecommendationStatus status;

  final DateTime generatedAt;

  final List<RedFlagHit> redFlags;

  final List<PlantSuggestion> suggestions;

  final List<ExcludedPlant> excluded;

  /// Labels of symptoms and goals no plant in the catalog covers.
  final List<String> uncovered;

  final List<MissingData> missing;

  /// A fingerprint of the data used, to tell when it is out of date.
  final String basis;

  final int referenceVersion;

  RecommendationSnapshot copyWith({
    RecommendationStatus? status,
    DateTime? generatedAt,
    List<RedFlagHit>? redFlags,
    List<PlantSuggestion>? suggestions,
    List<ExcludedPlant>? excluded,
    List<String>? uncovered,
    List<MissingData>? missing,
    String? basis,
    int? referenceVersion,
  }) => RecommendationSnapshot(
    status: status ?? this.status,
    generatedAt: generatedAt ?? this.generatedAt,
    redFlags: List.unmodifiable(redFlags ?? this.redFlags),
    suggestions: List.unmodifiable(suggestions ?? this.suggestions),
    excluded: List.unmodifiable(excluded ?? this.excluded),
    uncovered: List.unmodifiable(uncovered ?? this.uncovered),
    missing: List.unmodifiable(missing ?? this.missing),
    basis: basis ?? this.basis,
    referenceVersion: referenceVersion ?? this.referenceVersion,
  );

  Map<String, Object?> toJson() => {
    'status': status.name,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'redFlags': redFlags.map((item) => item.toJson()).toList(),
    'suggestions': suggestions.map((item) => item.toJson()).toList(),
    'excluded': excluded.map((item) => item.toJson()).toList(),
    'uncovered': uncovered,
    'missing': missing.map((item) => item.name).toList(),
    'basis': basis,
    'referenceVersion': referenceVersion,
  };

  @override
  bool operator ==(Object other) =>
      other is RecommendationSnapshot &&
      const DeepCollectionEquality().equals(toJson(), other.toJson());

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());

  @override
  String toString() => 'RecommendationSnapshot(${status.name})';

  static List<T> _list<T>(
    Object? value,
    T Function(Map<String, Object?> json) fromJson,
  ) => List.unmodifiable(
    (value as List<Object?>? ?? const []).map(
      (item) => fromJson(item as Map<String, Object?>),
    ),
  );
}

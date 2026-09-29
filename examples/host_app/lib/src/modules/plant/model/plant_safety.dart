import 'package:host_app/src/modules/plant/model/plant_enums.dart';

/// A condition or allergy that rules the plant out.
class Contraindication {
  const Contraindication({
    required this.kind,
    required this.tag,
    this.note = '',
  });

  factory Contraindication.fromJson(Map<String, Object?> json) =>
      Contraindication(
        kind: ContraindicationKind.values.byName(json['kind'] as String),
        tag: json['tag'] as String,
        note: json['note'] as String? ?? '',
      );

  final ContraindicationKind kind;

  final String tag;

  final String note;

  Contraindication copyWith({
    ContraindicationKind? kind,
    String? tag,
    String? note,
  }) => Contraindication(
    kind: kind ?? this.kind,
    tag: tag ?? this.tag,
    note: note ?? this.note,
  );

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'tag': tag,
    'note': note,
  };

  @override
  bool operator ==(Object other) =>
      other is Contraindication &&
      kind == other.kind &&
      tag == other.tag &&
      note == other.note;

  @override
  int get hashCode => Object.hash(kind, tag, note);

  @override
  String toString() => 'Contraindication(${kind.name}, $tag)';
}

/// A class of medicines the plant should not, or should carefully, mix with.
class PlantInteraction {
  const PlantInteraction({
    required this.medicationClass,
    required this.severity,
    this.note = '',
  });

  factory PlantInteraction.fromJson(Map<String, Object?> json) =>
      PlantInteraction(
        medicationClass: json['medicationClass'] as String,
        severity: InteractionSeverity.values.byName(json['severity'] as String),
        note: json['note'] as String? ?? '',
      );

  final String medicationClass;

  final InteractionSeverity severity;

  final String note;

  PlantInteraction copyWith({
    String? medicationClass,
    InteractionSeverity? severity,
    String? note,
  }) => PlantInteraction(
    medicationClass: medicationClass ?? this.medicationClass,
    severity: severity ?? this.severity,
    note: note ?? this.note,
  );

  Map<String, Object?> toJson() => {
    'medicationClass': medicationClass,
    'severity': severity.name,
    'note': note,
  };

  @override
  bool operator ==(Object other) =>
      other is PlantInteraction &&
      medicationClass == other.medicationClass &&
      severity == other.severity &&
      note == other.note;

  @override
  int get hashCode => Object.hash(medicationClass, severity, note);

  @override
  String toString() => 'PlantInteraction($medicationClass, ${severity.name})';
}

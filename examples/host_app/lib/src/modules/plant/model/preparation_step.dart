import 'package:host_app/src/modules/plant/model/plant_enums.dart';

/// One short step of a preparation: what to do, in a few plain words.
class PreparationStep {
  const PreparationStep({required this.kind, required this.text});

  factory PreparationStep.fromJson(Map<String, Object?> json) =>
      PreparationStep(
        kind: PreparationStepKind.values.byName(json['kind'] as String),
        text: json['text'] as String,
      );

  final PreparationStepKind kind;

  /// "Hierve agua."
  final String text;

  PreparationStep copyWith({PreparationStepKind? kind, String? text}) =>
      PreparationStep(kind: kind ?? this.kind, text: text ?? this.text);

  Map<String, Object?> toJson() => {'kind': kind.name, 'text': text};

  @override
  bool operator ==(Object other) =>
      other is PreparationStep && kind == other.kind && text == other.text;

  @override
  int get hashCode => Object.hash(kind, text);

  @override
  String toString() => 'PreparationStep(${kind.name}, $text)';
}

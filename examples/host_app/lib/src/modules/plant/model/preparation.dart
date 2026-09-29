import 'package:collection/collection.dart';

import 'package:host_app/src/modules/plant/model/plant_enums.dart';
import 'package:host_app/src/modules/plant/model/preparation_step.dart';

/// One way to take a plant: what it is for, its steps, how much and for how
/// long, and what to be careful with.
class Preparation {
  const Preparation({
    required this.form,
    required this.route,
    required this.instructions,
    this.title = '',
    this.uses = const [],
    this.steps = const [],
    this.warnings = const [],
    this.sources = const [],
    this.dose = '',
    this.frequency = '',
    this.maxDays,
  });

  factory Preparation.fromJson(Map<String, Object?> json) => Preparation(
    form: PreparationForm.values.byName(json['form'] as String),
    route: IntakeRoute.values.byName(json['route'] as String),
    instructions: json['instructions'] as String,
    title: json['title'] as String? ?? '',
    uses: List.unmodifiable(
      (json['uses'] as List<Object?>? ?? const []).cast<String>(),
    ),
    steps: List.unmodifiable(
      (json['steps'] as List<Object?>? ?? const []).map(
        (step) => PreparationStep.fromJson(step as Map<String, Object?>),
      ),
    ),
    warnings: List.unmodifiable(
      (json['warnings'] as List<Object?>? ?? const []).cast<String>(),
    ),
    sources: List.unmodifiable(
      (json['sources'] as List<Object?>? ?? const []).cast<String>(),
    ),
    dose: json['dose'] as String? ?? '',
    frequency: json['frequency'] as String? ?? '',
    maxDays: json['maxDays'] as int?,
  );

  final PreparationForm form;

  final IntakeRoute route;

  /// The source's full explanation, shown under "more details".
  final String instructions;

  /// A plain name: "Té de menta", "Aceite de menta en la piel".
  final String title;

  /// The indication tags this preparation is for.
  final List<String> uses;

  /// What to do, one short step at a time; empty when only the full
  /// explanation exists, as for a plant the person added.
  final List<PreparationStep> steps;

  /// Short cautions taken from the explanation.
  final List<String> warnings;

  /// Ids of the plant's sources for how it is made and how much.
  final List<String> sources;

  final String dose;

  final String frequency;

  /// Longest use without asking a professional.
  final int? maxDays;

  /// Whether it is for any of [tags].
  bool isFor(Set<String> tags) => uses.any(tags.contains);

  /// Whether it starts with water that has just boiled.
  bool get needsBoilingWater =>
      steps.any((step) => step.kind == PreparationStepKind.boilWater);

  /// The picture that tells at a glance how it is used.
  PreparationScene get scene => switch ((form, route)) {
    (_, IntakeRoute.inhalation) => PreparationScene.vapor,
    (PreparationForm.capsule, _) => PreparationScene.capsule,
    (PreparationForm.tincture, _) => PreparationScene.drops,
    (PreparationForm.infusion || PreparationForm.decoction, IntakeRoute.oral) =>
      PreparationScene.cup,
    (
      PreparationForm.infusion || PreparationForm.decoction,
      IntakeRoute.topical,
    ) =>
      PreparationScene.compress,
    _ when steps.any((step) => step.kind == PreparationStepKind.bath) =>
      PreparationScene.bath,
    _ => PreparationScene.skin,
  };

  Preparation copyWith({
    PreparationForm? form,
    IntakeRoute? route,
    String? instructions,
    String? title,
    List<String>? uses,
    List<PreparationStep>? steps,
    List<String>? warnings,
    List<String>? sources,
    String? dose,
    String? frequency,
    int? maxDays,
  }) => Preparation(
    form: form ?? this.form,
    route: route ?? this.route,
    instructions: instructions ?? this.instructions,
    title: title ?? this.title,
    uses: List.unmodifiable(uses ?? this.uses),
    steps: List.unmodifiable(steps ?? this.steps),
    warnings: List.unmodifiable(warnings ?? this.warnings),
    sources: List.unmodifiable(sources ?? this.sources),
    dose: dose ?? this.dose,
    frequency: frequency ?? this.frequency,
    maxDays: maxDays ?? this.maxDays,
  );

  Map<String, Object?> toJson() => {
    'form': form.name,
    'route': route.name,
    'instructions': instructions,
    'title': title,
    'uses': uses,
    'steps': steps.map((step) => step.toJson()).toList(),
    'warnings': warnings,
    'sources': sources,
    'dose': dose,
    'frequency': frequency,
    'maxDays': maxDays,
  };

  @override
  bool operator ==(Object other) =>
      other is Preparation &&
      form == other.form &&
      route == other.route &&
      instructions == other.instructions &&
      title == other.title &&
      const ListEquality<String>().equals(uses, other.uses) &&
      const ListEquality<PreparationStep>().equals(steps, other.steps) &&
      const ListEquality<String>().equals(warnings, other.warnings) &&
      const ListEquality<String>().equals(sources, other.sources) &&
      dose == other.dose &&
      frequency == other.frequency &&
      maxDays == other.maxDays;

  @override
  int get hashCode => Object.hash(
    form,
    route,
    instructions,
    title,
    Object.hashAll(uses),
    Object.hashAll(steps),
    Object.hashAll(warnings),
    Object.hashAll(sources),
    dose,
    frequency,
    maxDays,
  );

  @override
  String toString() => 'Preparation(${form.name}, ${route.name}, $title)';
}

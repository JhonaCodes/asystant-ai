import 'package:flutter/material.dart';

import 'package:host_app/src/modules/plant/model/plant.dart';
import 'package:host_app/src/modules/plant/model/plant_enums.dart';
import 'package:host_app/src/modules/plant/model/plant_indication.dart';
import 'package:host_app/src/modules/plant/model/plant_safety.dart';
import 'package:host_app/src/modules/plant/model/preparation.dart';
import 'package:host_app/src/shared/shared.dart';

/// Readable names for the plant's enums.
extension EvidenceLevelLabel on EvidenceLevel {
  String get label => switch (this) {
    EvidenceLevel.wellEstablished => PlantStrings.wellEstablished,
    EvidenceLevel.traditional => PlantStrings.traditional,
    EvidenceLevel.limited => PlantStrings.limited,
    EvidenceLevel.popular => PlantStrings.popular,
  };
}

extension PreparationFormLabel on PreparationForm {
  String get label => switch (this) {
    PreparationForm.infusion => PlantStrings.infusion,
    PreparationForm.decoction => PlantStrings.decoction,
    PreparationForm.tincture => PlantStrings.tincture,
    PreparationForm.topical => PlantStrings.topical,
    PreparationForm.capsule => PlantStrings.capsule,
    PreparationForm.essentialOil => PlantStrings.essentialOil,
    PreparationForm.gel => PlantStrings.gel,
    PreparationForm.freshPlant => PlantStrings.freshPlant,
  };
}

extension IntakeRouteLabel on IntakeRoute {
  String get label => switch (this) {
    IntakeRoute.oral => PlantStrings.oral,
    IntakeRoute.topical => PlantStrings.onSkin,
    IntakeRoute.inhalation => PlantStrings.inhaled,
  };

  IconData get icon => switch (this) {
    IntakeRoute.oral => Icons.local_drink_outlined,
    IntakeRoute.topical => Icons.back_hand_outlined,
    IntakeRoute.inhalation => Icons.air,
  };
}

extension PreparationStepKindIcon on PreparationStepKind {
  IconData get icon => switch (this) {
    PreparationStepKind.buy => Icons.local_pharmacy_outlined,
    PreparationStepKind.clean => Icons.wash_outlined,
    PreparationStepKind.boilWater => Icons.local_fire_department_outlined,
    PreparationStepKind.simmer => Icons.soup_kitchen_outlined,
    PreparationStepKind.pour => Icons.water_drop_outlined,
    PreparationStepKind.steep => Icons.hourglass_bottom,
    PreparationStepKind.strain => Icons.filter_alt_outlined,
    PreparationStepKind.cool => Icons.ac_unit,
    PreparationStepKind.drink => Icons.local_cafe_outlined,
    PreparationStepKind.swallow => Icons.medication_outlined,
    PreparationStepKind.dilute => Icons.water_outlined,
    PreparationStepKind.apply => Icons.back_hand_outlined,
    PreparationStepKind.compress => Icons.healing_outlined,
    PreparationStepKind.rinse => Icons.face_outlined,
    PreparationStepKind.inhale => Icons.air,
    PreparationStepKind.bath => Icons.bathtub_outlined,
  };
}

extension SourceKindLabel on SourceKind {
  String get label => switch (this) {
    SourceKind.botany => PlantStrings.botanySources,
    SourceKind.popular => PlantStrings.popularSources,
    SourceKind.science => PlantStrings.scienceSources,
  };
}

extension PreparationTitle on Preparation {
  /// Its plain name, or the form's for a preparation without one.
  String get displayTitle => title.isEmpty ? form.label : title;
}

extension SafetyGuidanceLabel on SafetyGuidance {
  String get label => switch (this) {
    SafetyGuidance.acceptable => PlantStrings.acceptable,
    SafetyGuidance.avoid => PlantStrings.avoid,
    SafetyGuidance.notEstablished => PlantStrings.notEstablished,
  };

  Color colorIn(BuildContext context) => switch (this) {
    SafetyGuidance.acceptable => BotanicaColors.of(context).safe,
    SafetyGuidance.avoid => BotanicaColors.of(context).danger,
    SafetyGuidance.notEstablished => BotanicaColors.of(context).caution,
  };
}

extension ContraindicationText on Contraindication {
  /// "No usar si tienes: cálculos biliares. Nota…"
  String describe(String Function(String tag) labelOf) {
    final lead = switch (kind) {
      ContraindicationKind.allergy => PlantStrings.allergyTo,
      ContraindicationKind.condition => PlantStrings.notFor,
    };
    return _Precaution.withNote('$lead: ${labelOf(tag)}', note);
  }
}

extension InteractionText on PlantInteraction {
  String describe(String Function(String tag) labelOf) {
    final lead = switch (severity) {
      InteractionSeverity.avoid => PlantStrings.avoidWith,
      InteractionSeverity.caution => PlantStrings.cautionWith,
    };
    return _Precaution.withNote('$lead: ${labelOf(medicationClass)}', note);
  }

  Color colorIn(BuildContext context) => switch (severity) {
    InteractionSeverity.avoid => BotanicaColors.of(context).danger,
    InteractionSeverity.caution => BotanicaColors.of(context).caution,
  };
}

/// Joins a precaution with its note.
abstract final class _Precaution {
  static String withNote(String text, String note) =>
      note.isEmpty ? text : '$text. $note';
}

extension PlantIndicationText on PlantIndication {
  /// "Uso tradicional · Alivia molestias leves".
  String get detail =>
      [evidence.label, note].where((part) => part.isNotEmpty).join(' · ');
}

extension PlantAllergens on Plant {
  /// "Alergia a: Asteráceas, ..." or empty when the plant lists none.
  String allergensLine(String Function(String tag) labelOf) =>
      allergenGroups.isEmpty
      ? ''
      : '${PlantStrings.allergyTo}: ${allergenGroups.map(labelOf).join(', ')}';
}

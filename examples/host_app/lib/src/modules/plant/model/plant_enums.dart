/// Who put a plant in the catalog.
enum PlantOrigin { seed, person }

/// How strong the support for an indication is.
enum EvidenceLevel {
  wellEstablished,
  traditional,
  limited,

  /// What people say it is for, with no study or official monograph behind
  /// it; recommended only below everything with evidence, and marked.
  popular;

  /// Weight in the recommendation score.
  int get weight => switch (this) {
    EvidenceLevel.wellEstablished => 3,
    EvidenceLevel.traditional => 2,
    EvidenceLevel.limited => 1,
    EvidenceLevel.popular => 0,
  };
}

/// Which of the three views a source speaks for.
enum SourceKind { botany, popular, science }

enum PreparationForm {
  infusion,
  decoction,
  tincture,
  topical,
  capsule,
  essentialOil,
  gel,
  freshPlant,
}

enum IntakeRoute { oral, topical, inhalation }

enum ContraindicationKind { condition, allergy }

enum InteractionSeverity { avoid, caution }

/// Whether the plant may be used during pregnancy or lactation.
enum SafetyGuidance { acceptable, avoid, notEstablished }

/// What a preparation's picture shows: how it is used at a glance.
enum PreparationScene { cup, compress, vapor, skin, capsule, drops, bath }

/// What a step asks the person to do; each has its own icon.
enum PreparationStepKind {
  buy,
  clean,
  boilWater,
  simmer,
  pour,
  steep,
  strain,
  cool,
  drink,
  swallow,
  dilute,
  apply,
  compress,
  rinse,
  inhale,
  bath,
}

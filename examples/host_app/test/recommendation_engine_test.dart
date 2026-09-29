import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:host_app/src/modules/assessment/model/assessment.dart';
import 'package:host_app/src/modules/assessment/model/goal.dart';
import 'package:host_app/src/modules/assessment/model/recommendation_snapshot.dart';
import 'package:host_app/src/modules/assessment/model/symptom.dart';
import 'package:host_app/src/modules/plant/model/plant.dart';
import 'package:host_app/src/modules/plant/model/plant_enums.dart';
import 'package:host_app/src/modules/plant/model/plant_indication.dart';
import 'package:host_app/src/modules/profile/model/biological_sex.dart';
import 'package:host_app/src/modules/profile/model/person_profile.dart';
import 'package:host_app/src/modules/recommendation/model/recommendation_input.dart';
import 'package:host_app/src/modules/recommendation/service/recommendation_engine.dart';
import 'package:host_app/src/modules/reference/model/red_flag_rule.dart';
import 'package:host_app/src/modules/reference/model/reference_data.dart';
import 'package:host_app/src/modules/reference/model/term_kind.dart';
import 'package:host_app/src/modules/reference/model/vocabulary_term.dart';

final _now = DateTime.utc(2026, 9, 28);

const _reference = ReferenceData(
  version: 1,
  terms: [
    VocabularyTerm(
      id: 'headache',
      label: 'Dolor de cabeza',
      kind: TermKind.symptom,
    ),
    VocabularyTerm(
      id: 'chest_pain',
      label: 'Dolor en el pecho',
      kind: TermKind.symptom,
    ),
    VocabularyTerm(
      id: 'weight_loss',
      label: 'Bajar de peso',
      kind: TermKind.goal,
    ),
  ],
  redFlags: [
    RedFlagRule(
      id: 'chest_pain',
      label: 'Dolor en el pecho',
      advice: 'Busca atención médica de inmediato.',
      triggerTags: ['chest_pain'],
    ),
  ],
);

const _safeInPregnancy = Plant(
  id: 'jengibre',
  commonName: 'Jengibre',
  origin: PlantOrigin.seed,
  pregnancy: SafetyGuidance.acceptable,
  lactation: SafetyGuidance.acceptable,
  indications: [
    PlantIndication(
      tag: 'headache',
      label: 'Dolor de cabeza',
      evidence: EvidenceLevel.traditional,
    ),
  ],
);

const _unknownInPregnancy = Plant(
  id: 'menta',
  commonName: 'Menta',
  origin: PlantOrigin.seed,
  indications: [
    PlantIndication(
      tag: 'headache',
      label: 'Dolor de cabeza',
      evidence: EvidenceLevel.wellEstablished,
    ),
  ],
);

const _addedByPerson = Plant(
  id: 'ruda',
  commonName: 'Ruda',
  indications: [
    PlantIndication(
      tag: 'headache',
      label: 'Dolor de cabeza',
      evidence: EvidenceLevel.traditional,
    ),
  ],
);

PersonProfile _person({bool? pregnant = false, bool? lactating = false}) =>
    PersonProfile(
      birthDate: DateTime.utc(1991, 5, 14),
      sex: BiologicalSex.female,
      isPregnant: pregnant,
      isLactating: lactating,
      updatedAt: _now,
    );

Assessment _assessment({
  List<Symptom> symptoms = const [],
  List<Goal> goals = const [],
}) => Assessment(
  id: 'a1',
  reason: 'Prueba',
  createdAt: _now,
  symptoms: symptoms,
  goals: goals,
);

RecommendationSnapshot _evaluate(
  PersonProfile profile,
  Assessment assessment,
) => RecommendationEngine.evaluate(
  RecommendationInput(
    profile: profile,
    assessment: assessment,
    plants: const [_unknownInPregnancy, _safeInPregnancy, _addedByPerson],
    reference: _reference,
    now: _now,
  ),
);

const _headache = Symptom(
  id: 's1',
  description: 'Dolor de cabeza',
  tag: 'headache',
  intensity: 4,
  durationDays: 2,
);

void main() {
  test(
    'a warning sign sends the person to a doctor and recommends nothing',
    () {
      final snapshot = _evaluate(
        _person(),
        _assessment(
          symptoms: const [
            _headache,
            Symptom(
              id: 's2',
              description: 'Presión en el pecho',
              tag: 'chest_pain',
            ),
          ],
        ),
      );

      expect(snapshot.status, RecommendationStatus.seeDoctor);
      expect(snapshot.redFlags.map((hit) => hit.ruleId), ['chest_pain']);
      expect(snapshot.suggestions, isEmpty);
    },
  );

  test('pregnancy excludes plants not known to be safe in pregnancy', () {
    final snapshot = _evaluate(
      _person(pregnant: true),
      _assessment(symptoms: const [_headache]),
    );

    expect(snapshot.status, RecommendationStatus.recommended);
    expect(snapshot.suggestions.map((plant) => plant.plantId), ['jengibre']);
    final menta = snapshot.excluded.firstWhere(
      (plant) => plant.plantId == 'menta',
    );
    expect(menta.reasons.map((reason) => reason.kind), [
      ExclusionKind.pregnancy,
    ]);
  });

  test('plants the person added are never recommended automatically', () {
    final snapshot = _evaluate(
      _person(),
      _assessment(symptoms: const [_headache]),
    );

    final ruda = snapshot.excluded.firstWhere(
      (plant) => plant.plantId == 'ruda',
    );
    expect(ruda.reasons.map((reason) => reason.kind), [
      ExclusionKind.notCurated,
    ]);
    expect(snapshot.suggestions.map((plant) => plant.plantId), [
      'menta',
      'jengibre',
    ]);
  });

  test('popular belief ranks below evidence and is marked as such', () {
    const folk = Plant(
      id: 'ruda',
      commonName: 'Ruda',
      origin: PlantOrigin.seed,
      pregnancy: SafetyGuidance.acceptable,
      lactation: SafetyGuidance.acceptable,
      indications: [
        PlantIndication(
          tag: 'headache',
          label: 'Dolor de cabeza',
          evidence: EvidenceLevel.popular,
        ),
      ],
    );
    final snapshot = RecommendationEngine.evaluate(
      RecommendationInput(
        profile: _person(),
        assessment: _assessment(symptoms: const [_headache]),
        plants: const [folk, _safeInPregnancy],
        reference: _reference,
        now: _now,
      ),
    );

    expect(snapshot.suggestions.map((plant) => plant.plantId), [
      'jengibre',
      'ruda',
    ]);
    expect(snapshot.suggestions.map((plant) => plant.popularOnly), [
      false,
      true,
    ]);
  });

  test('a goal no plant covers is reported instead of invented', () {
    final snapshot = _evaluate(
      _person(),
      _assessment(
        symptoms: const [_headache],
        goals: const [
          Goal(id: 'g1', description: 'Bajar de peso', tag: 'weight_loss'),
        ],
      ),
    );

    expect(snapshot.uncovered, ['Bajar de peso']);
  });

  test('without the pregnancy answer it asks instead of recommending', () {
    final snapshot = _evaluate(
      _person(pregnant: null),
      _assessment(symptoms: const [_headache]),
    );

    expect(snapshot.status, RecommendationStatus.needsInformation);
    expect(snapshot.missing, [MissingData.pregnancy]);
  });

  group('with the bundled catalog', () {
    final seed = jsonDecode(
      File('assets/seed/botanica_seed.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final reference = ReferenceData.fromJson(
      seed['reference'] as Map<String, Object?>,
    );
    final plants = [
      for (final id in (seed['plants'] as List<Object?>).cast<String>())
        Plant.fromJson({
          ...jsonDecode(File('assets/seed/plants/$id.json').readAsStringSync())
              as Map<String, Object?>,
          'origin': PlantOrigin.seed.name,
        }),
    ];

    RecommendationSnapshot evaluateSeed(Assessment assessment) =>
        RecommendationEngine.evaluate(
          RecommendationInput(
            profile: _person(),
            assessment: assessment,
            plants: plants,
            reference: reference,
            now: _now,
          ),
        );

    test('loads every listed plant, with tags from the vocabulary', () {
      expect(plants, isNotEmpty);
      for (final plant in plants) {
        for (final indication in plant.indications) {
          expect(reference.termFor(indication.tag), isNotNull);
        }
      }
    });

    test('a tension headache and better sleep get plants with photos', () {
      final snapshot = evaluateSeed(
        _assessment(
          symptoms: const [_headache],
          goals: const [
            Goal(id: 'g1', description: 'Dormir mejor', tag: 'sleep_better'),
          ],
        ),
      );

      expect(snapshot.status, RecommendationStatus.recommended);
      expect(snapshot.suggestions, isNotEmpty);
      expect(
        snapshot.suggestions.every((plant) => plant.photoRef.isNotEmpty),
        isTrue,
      );
      expect(snapshot.uncovered, isEmpty);
    });

    test('a plant brings only the preparations for what the person has', () {
      final snapshot = evaluateSeed(_assessment(symptoms: const [_headache]));

      final menta = snapshot.suggestions.firstWhere(
        (plant) => plant.plantId == 'menta',
      );
      expect(menta.preparations.map((item) => item.title), [
        'Aceite de menta en la piel',
      ]);
      expect(menta.preparations.single.steps, isNotEmpty);
    });

    test('chest pain is sent to a doctor', () {
      final snapshot = evaluateSeed(
        _assessment(
          symptoms: const [
            Symptom(id: 's1', description: 'Presión', tag: 'chest_pain'),
          ],
        ),
      );

      expect(snapshot.status, RecommendationStatus.seeDoctor);
    });
  });
}

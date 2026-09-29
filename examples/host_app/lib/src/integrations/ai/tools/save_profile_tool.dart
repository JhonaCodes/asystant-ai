part of '../ai.dart';

/// What the person just said about themselves, decoded from the model.
typedef _ProfileFacts = ({
  int? age,
  BiologicalSex? sex,
  bool? pregnant,
  bool? lactating,
  List<String> conditions,
  List<String> allergies,
});

/// Saves in the person's profile what they said, as soon as they say it.
///
/// It runs without asking: the person just told the assistant, and the card
/// shows what was kept. Everything can be erased from the Profile screen.
final class _SaveProfileTool extends TypedAsystantTool<_ProfileFacts> {
  const _SaveProfileTool();

  static const _maxAge = 120;

  @override
  bool get requiresConfirmation => false;

  @override
  ToolDefinition get definition => ToolDefinition(
    name: 'save_profile',
    description:
        'Guarda en el perfil de la persona lo que te acaba de contar sobre '
        'sí misma: edad, sexo, embarazo, lactancia, condiciones de salud y '
        'alergias. Úsala apenas lo diga, sin pedirle confirmación, y envía '
        'solo lo nuevo.',
    fields: [
      const ToolField(
        name: 'age',
        description: 'Edad en años.',
        kind: .integer,
        isRequired: false,
      ),
      const ToolField(
        name: 'sex',
        description: 'mujer u hombre.',
        kind: .string,
        isRequired: false,
      ),
      const ToolField(
        name: 'pregnant',
        description: 'Si está embarazada.',
        kind: .boolean,
        isRequired: false,
      ),
      const ToolField(
        name: 'lactating',
        description: 'Si está dando lactancia.',
        kind: .boolean,
        isRequired: false,
      ),
      ToolField(
        name: 'conditions',
        description:
            'Condiciones de salud. Usa el id cuando coincida: '
            '${_Vocabulary.of(TermKind.condition)}. Si ninguna coincide, '
            'escríbela como la dijo la persona.',
        kind: .strings,
        isRequired: false,
      ),
      ToolField(
        name: 'allergies',
        description:
            'Alergias. Si es a una planta, usa el id de su familia: '
            '${_Vocabulary.of(TermKind.allergenGroup)}. Si ninguna coincide, '
            'escríbela como la dijo la persona.',
        kind: .strings,
        isRequired: false,
      ),
    ],
  );

  @override
  Result<_ProfileFacts, AssistantFailure> decode(ToolArguments arguments) {
    final json = arguments.toJson();
    return switch ((
      json['age'],
      json['sex'],
      json['pregnant'],
      json['lactating'],
      json['conditions'],
      json['allergies'],
    )) {
      (
        final num? age,
        final String? sex,
        final bool? pregnant,
        final bool? lactating,
        final List<Object?>? conditions,
        final List<Object?>? allergies,
      )
          when age == null || (age >= 0 && age <= _maxAge) =>
        Ok((
          age: age?.toInt(),
          sex: _sexOf(sex),
          pregnant: pregnant,
          lactating: lactating,
          conditions: _ToolInput.texts(conditions),
          allergies: _ToolInput.texts(allergies),
        )),
      _ => Err(
        const AssistantFailure(.invalidTool, detail: 'save_profile arguments'),
      ),
    };
  }

  @override
  Future<Result<AssistantCard, AssistantFailure>> previewInput(
    _ProfileFacts facts,
  ) async => Ok(const AssistantCard(title: AssistantToolStrings.savingProfile));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> executeInput(
    _ProfileFacts facts,
    ToolContext context,
  ) async {
    final lines = _lines(facts);
    if (lines.isEmpty) {
      return Ok(
        const ToolOutcome(modelContent: 'No había nada nuevo para guardar.'),
      );
    }
    // One save: the person's words are kept together or not at all.
    final saved = await ProfileService.notifier.record(
      age: facts.age,
      sex: facts.sex,
      isPregnant: facts.pregnant,
      isLactating: facts.lactating,
      conditions: [
        for (final text in facts.conditions)
          HealthCondition(
            id: '',
            description: _Vocabulary.labelFor(TermKind.condition, text),
            tag: _Vocabulary.match(TermKind.condition, text)?.id,
          ),
      ],
      allergies: [
        for (final text in facts.allergies)
          Allergy(
            id: '',
            description: _Vocabulary.labelFor(TermKind.allergenGroup, text),
            tag: _Vocabulary.match(TermKind.allergenGroup, text)?.id,
          ),
      ],
    );
    if (saved.errorOrNull case final ApiFailure failure) {
      Log.w('save_profile: ${failure.title} ${failure.msm}');
      return Err(const AssistantFailure(.toolFailed, detail: 'Profile'));
    }
    return Ok(
      ToolOutcome(
        modelContent: 'Guardado en el perfil: ${lines.join('; ')}.',
        card: AssistantCard(
          kind: AssistantCardKind.result,
          title: AssistantToolStrings.savedToProfile,
          body: lines.map((line) => '- $line').join('\n'),
        ),
      ),
    );
  }

  /// What the card tells the person was kept, in the order they read it.
  static List<String> _lines(_ProfileFacts facts) => [
    if (facts.age case final age?) AssistantToolStrings.age(age),
    if (facts.sex case final sex?) AssistantToolStrings.sex(sex.label),
    if (facts.pregnant case final pregnant?)
      AssistantToolStrings.pregnant(pregnant),
    if (facts.lactating case final lactating?)
      AssistantToolStrings.lactating(lactating),
    for (final text in facts.conditions)
      AssistantToolStrings.condition(
        _Vocabulary.labelFor(TermKind.condition, text),
      ),
    for (final text in facts.allergies)
      AssistantToolStrings.allergy(
        _Vocabulary.labelFor(TermKind.allergenGroup, text),
      ),
  ];

  static BiologicalSex? _sexOf(String? text) => switch (text?.searchKey) {
    'mujer' || 'femenino' || 'female' => BiologicalSex.female,
    'hombre' || 'masculino' || 'male' => BiologicalSex.male,
    _ => null,
  };
}

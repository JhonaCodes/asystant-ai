part of '../ai.dart';

/// A medicine the person takes, decoded from the model.
typedef _MedicationFact = ({
  String name,
  List<String> classes,
  String dose,
  String frequency,
});

/// Saves a medicine the person takes; its type lets the recommendation
/// leave out plants that interact with it.
final class _AddMedicationTool extends TypedAsystantTool<_MedicationFact> {
  const _AddMedicationTool();

  @override
  bool get requiresConfirmation => false;

  @override
  ToolDefinition get definition => ToolDefinition(
    name: 'add_medication',
    description:
        'Guarda en el perfil un medicamento que la persona toma. Úsala apenas '
        'lo mencione, sin pedirle confirmación.',
    fields: [
      const ToolField(
        name: 'name',
        description: 'Nombre del medicamento, como lo dijo la persona.',
        kind: .string,
      ),
      ToolField(
        name: 'classes',
        description:
            'Tipo de medicamento, si lo sabes; sirve para descartar plantas '
            'que interactúan con él: ${_Vocabulary.of(TermKind.medicationClass)}.',
        kind: .strings,
        isRequired: false,
      ),
      const ToolField(
        name: 'dose',
        description: 'Cuánto toma, si lo dijo.',
        kind: .string,
        isRequired: false,
      ),
      const ToolField(
        name: 'frequency',
        description: 'Cada cuánto lo toma, si lo dijo.',
        kind: .string,
        isRequired: false,
      ),
    ],
  );

  @override
  Result<_MedicationFact, AssistantFailure> decode(ToolArguments arguments) {
    final json = arguments.toJson();
    final name = _ToolInput.text(json['name']);
    if (name.isEmpty) {
      return Err(
        const AssistantFailure(.invalidTool, detail: 'add_medication name'),
      );
    }
    return Ok((
      name: name,
      classes: [
        for (final text in _ToolInput.texts(json['classes']))
          if (_Vocabulary.match(TermKind.medicationClass, text)
              case final term?)
            term.id,
      ],
      dose: _ToolInput.text(json['dose']),
      frequency: _ToolInput.text(json['frequency']),
    ));
  }

  @override
  Future<Result<AssistantCard, AssistantFailure>> previewInput(
    _MedicationFact medication,
  ) async => Ok(const AssistantCard(title: AssistantToolStrings.savingProfile));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> executeInput(
    _MedicationFact medication,
    ToolContext context,
  ) async {
    final saved = await ProfileService.notifier.addMedication(
      Medication(
        id: '',
        name: medication.name,
        classTags: medication.classes,
        dose: medication.dose,
        frequency: medication.frequency,
      ),
    );
    if (saved.errorOrNull case final ApiFailure failure) {
      Log.w('add_medication: ${failure.title} ${failure.msm}');
      return Err(const AssistantFailure(.toolFailed, detail: 'Profile'));
    }
    final line = AssistantToolStrings.medication(medication.name);
    return Ok(
      ToolOutcome(
        modelContent: 'Guardado en el perfil: $line.',
        card: AssistantCard(
          kind: AssistantCardKind.result,
          title: AssistantToolStrings.savedToProfile,
          body: '- $line',
        ),
      ),
    );
  }
}

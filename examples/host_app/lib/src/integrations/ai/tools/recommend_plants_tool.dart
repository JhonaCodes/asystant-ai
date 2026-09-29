part of '../ai.dart';

/// What to recommend for, decoded from the model.
typedef _ConsultationRequest = ({
  String consultationId,
  String reason,
  List<String> symptoms,
  List<String> goals,
});

/// One thing the person has or wants, placed by the vocabulary.
typedef _ConsultationItem = ({String text, VocabularyTerm? term, bool isGoal});

/// Records the person's symptoms and goals in a consultation and runs the
/// app's recommendation engine on it.
///
/// The engine, not the model, decides: it reads the saved profile, leaves out
/// what is unsafe for this person and stops at warning signs. The result is
/// kept in the consultation, so the person finds it in the app.
final class _RecommendPlantsTool
    extends TypedAsystantTool<_ConsultationRequest> {
  const _RecommendPlantsTool();

  @override
  bool get requiresConfirmation => false;

  @override
  ToolDefinition get definition => ToolDefinition(
    name: 'recommend_plants',
    description:
        'Busca en el catálogo de la app plantas para los síntomas u '
        'objetivos de la persona, con cómo prepararlas, cantidad, frecuencia '
        'y precauciones. Descarta sola las plantas que no son seguras según '
        'su perfil y guarda todo en una consulta que la persona ve en la app. '
        'Úsala cuando la persona cuente un síntoma o algo que quiere lograr.',
    fields: [
      const ToolField(
        name: 'reason',
        description:
            'El motivo de la consulta en pocas palabras, como lo dijo la '
            'persona.',
        kind: .string,
        isRequired: false,
      ),
      ToolField(
        name: 'symptoms',
        description:
            'Síntomas. Usa el id cuando coincida: '
            '${_Vocabulary.of(TermKind.symptom)}. Si ninguno coincide, '
            'escríbelo como lo dijo la persona.',
        kind: .strings,
        isRequired: false,
      ),
      ToolField(
        name: 'goals',
        description:
            'Lo que quiere lograr. Usa el id cuando coincida: '
            '${_Vocabulary.of(TermKind.goal)}. Si ninguno coincide, escríbelo '
            'como lo dijo la persona.',
        kind: .strings,
        isRequired: false,
      ),
      const ToolField(
        name: 'consultation_id',
        description:
            'El id de una consulta que ya creaste en esta conversación, para '
            'sumarle datos y recalcular en lugar de crear otra.',
        kind: .string,
        isRequired: false,
      ),
    ],
  );

  @override
  Result<_ConsultationRequest, AssistantFailure> decode(
    ToolArguments arguments,
  ) {
    final json = arguments.toJson();
    final symptoms = _ToolInput.texts(json['symptoms']);
    final goals = _ToolInput.texts(json['goals']);
    final consultationId = _ToolInput.text(json['consultation_id']);
    if (symptoms.isEmpty && goals.isEmpty && consultationId.isEmpty) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail: 'recommend_plants needs symptoms or goals',
        ),
      );
    }
    final reason = _ToolInput.text(json['reason']);
    return Ok((
      consultationId: consultationId,
      reason: reason.isNotEmpty
          ? reason
          : [
              for (final text in symptoms)
                _Vocabulary.labelFor(TermKind.symptom, text),
              for (final text in goals)
                _Vocabulary.labelFor(TermKind.goal, text),
            ].join(', '),
      symptoms: symptoms,
      goals: goals,
    ));
  }

  @override
  Future<Result<AssistantCard, AssistantFailure>> previewInput(
    _ConsultationRequest request,
  ) async =>
      Ok(const AssistantCard(title: AssistantToolStrings.lookingForPlants));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> executeInput(
    _ConsultationRequest request,
    ToolContext context,
  ) async {
    final consultation = await _consultation(request);
    final id = consultation.when(ok: (id) => id, err: (_) => null);
    if (id == null) {
      return _failed(consultation.errorOrNull, 'consultation');
    }
    final assessments = AssessmentService.notifier;
    for (final item in _items(request)) {
      final description = _Vocabulary.labelFor(
        item.isGoal ? TermKind.goal : TermKind.symptom,
        item.text,
      );
      final added = item.isGoal
          ? await assessments.addGoal(
              id,
              Goal(id: '', description: description, tag: item.term?.id),
            )
          : await assessments.addSymptom(
              id,
              Symptom(id: '', description: description, tag: item.term?.id),
            );
      if (added.isErr) {
        return _failed(added.errorOrNull, 'symptom or goal');
      }
    }
    final result = await RecommendationService.notifier.recommend(id);
    final snapshot = result.when(ok: (snapshot) => snapshot, err: (_) => null);
    if (snapshot == null) {
      return _failed(result.errorOrNull, 'recommendation');
    }
    final card = _RecommendationCard(
      title: AssistantToolStrings.recommendationFor(request.reason),
      consultationId: id,
      snapshot: snapshot,
    );
    return Ok(ToolOutcome(modelContent: card.modelSummary, card: card));
  }

  /// Symptoms and goals where the vocabulary says they belong, whichever
  /// list the model used: `headache` sent as a goal is still a symptom.
  static List<_ConsultationItem> _items(_ConsultationRequest request) => [
    for (final (text, sentAsGoal) in [
      for (final text in request.symptoms) (text, false),
      for (final text in request.goals) (text, true),
    ])
      switch (_Vocabulary.matchAny(const [
        TermKind.symptom,
        TermKind.goal,
      ], text)) {
        final term? => (
          text: text,
          term: term,
          isGoal: term.kind == TermKind.goal,
        ),
        null => (text: text, term: null, isGoal: sentAsGoal),
      },
  ];

  /// The consultation the model named, when it exists; a new one otherwise.
  static Future<Result<String, ApiFailure>> _consultation(
    _ConsultationRequest request,
  ) async {
    final assessments = AssessmentService.notifier;
    await assessments.loaded();
    if (assessments.current.byId(request.consultationId) case final existing?) {
      return Ok(existing.id);
    }
    final started = await assessments.startAssessment(reason: request.reason);
    return started.map((assessment) => assessment.id);
  }

  static Result<ToolOutcome, AssistantFailure> _failed(
    ApiFailure? failure,
    String step,
  ) {
    Log.w('recommend_plants $step: ${failure?.title} ${failure?.msm}');
    return Err(const AssistantFailure(.toolFailed, detail: 'Recommendation'));
  }
}

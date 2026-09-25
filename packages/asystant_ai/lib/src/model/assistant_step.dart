/// Ephemeral execution trace; never persisted or sent as model reasoning.
class AssistantStep {
  const AssistantStep({
    required this.id,
    required this.title,
    this.phase = .preparing,
  });

  final String id;

  final String title;

  final StepPhase phase;

  AssistantStep copyWith({String? id, String? title, StepPhase? phase}) =>
      AssistantStep(
        id: id ?? this.id,
        title: title ?? this.title,
        phase: phase ?? this.phase,
      );

  bool get active => switch (phase) {
    StepPhase.preparing || StepPhase.permission || StepPhase.running => true,
    StepPhase.completed ||
    StepPhase.declined ||
    StepPhase.canceled ||
    StepPhase.failed => false,
  };

  @override
  bool operator ==(Object other) =>
      other is AssistantStep &&
      id == other.id &&
      title == other.title &&
      phase == other.phase;

  @override
  int get hashCode => Object.hash(id, title, phase);
}

/// The execution or permission state of a displayed local-tool step.
enum StepPhase {
  preparing,
  permission,
  running,
  completed,
  declined,
  canceled,
  failed,
}

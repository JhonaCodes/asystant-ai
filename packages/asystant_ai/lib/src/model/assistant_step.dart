import 'package:asystant_core/asystant_core.dart';
import 'package:collection/collection.dart';

/// One local tool call as the person sees it: what it is doing and how it
/// ended. Never sent to the model; a conversation store keeps it with the
/// entries it belongs to.
class AssistantStep {
  const AssistantStep({
    required this.id,
    required this.title,
    this.phase = .preparing,
    this.toolName = '',
    this.startedAt,
    this.detail = '',
    this.data = const {},
    this.progress,
    this.progressLabel = '',
    this.images = const [],
  });

  final String id;

  /// The preview's title while it runs; the tool's `ToolOutcome.summary`
  /// once it completes, when it gives one.
  final String title;

  final StepPhase phase;

  /// The tool the model called.
  final String toolName;

  /// When the tool started running; null while it waits or when it never
  /// ran.
  final DateTime? startedAt;

  /// Why it did not complete, as the tool or the validation said it.
  final String detail;

  /// The tool's `ToolOutcome.data`: structured result for the host.
  final Map<String, Object?> data;

  /// How far the running tool has come, from 0 to 1, as it reported with
  /// `ToolContext.reportProgress`; null when it reported none.
  final double? progress;

  /// The label of the last progress report, such as "Frame 12 of 48"; empty
  /// when there is none.
  final String progressLabel;

  /// The images the tool returned with its result (`ToolOutcome.images`),
  /// such as a frame it rendered to review its own work. The chat shows them
  /// under the step; the model receives them on the tool's result message.
  final List<AsystantAttachment> images;

  /// Whether the step is running and has progress to show.
  bool get showsProgress => active && progress != null;

  AssistantStep copyWith({
    String? id,
    String? title,
    StepPhase? phase,
    String? toolName,
    DateTime? startedAt,
    String? detail,
    Map<String, Object?>? data,
    double? progress,
    String? progressLabel,
    List<AsystantAttachment>? images,
  }) => AssistantStep(
    id: id ?? this.id,
    title: title ?? this.title,
    phase: phase ?? this.phase,
    toolName: toolName ?? this.toolName,
    startedAt: startedAt ?? this.startedAt,
    detail: detail ?? this.detail,
    data: Map.unmodifiable(data ?? this.data),
    progress: progress ?? this.progress,
    progressLabel: progressLabel ?? this.progressLabel,
    images: List.unmodifiable(images ?? this.images),
  );

  bool get active => switch (phase) {
    StepPhase.preparing || StepPhase.permission || StepPhase.running => true,
    StepPhase.completed ||
    StepPhase.declined ||
    StepPhase.canceled ||
    StepPhase.failed => false,
  };

  /// Finished without doing what it set out to do.
  bool get hasIssue => switch (phase) {
    StepPhase.declined || StepPhase.canceled || StepPhase.failed => true,
    StepPhase.preparing ||
    StepPhase.permission ||
    StepPhase.running ||
    StepPhase.completed => false,
  };

  StepOutcome get outcome => switch (this) {
    AssistantStep(active: true) => StepOutcome.running,
    AssistantStep(hasIssue: true) => StepOutcome.issue,
    _ => StepOutcome.done,
  };

  @override
  bool operator ==(Object other) =>
      other is AssistantStep &&
      id == other.id &&
      title == other.title &&
      phase == other.phase &&
      toolName == other.toolName &&
      startedAt == other.startedAt &&
      detail == other.detail &&
      const DeepCollectionEquality().equals(data, other.data) &&
      progress == other.progress &&
      progressLabel == other.progressLabel &&
      const ListEquality<AsystantAttachment>().equals(images, other.images);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    phase,
    toolName,
    startedAt,
    detail,
    const DeepCollectionEquality().hash(data),
    progress,
    progressLabel,
    Object.hashAll(images),
  );
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

/// How a step looks at a glance: still going, done, or with an issue.
enum StepOutcome { running, done, issue }

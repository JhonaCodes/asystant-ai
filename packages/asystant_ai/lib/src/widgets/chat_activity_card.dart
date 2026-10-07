import 'package:flutter/material.dart';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/assistant_step.dart';
import 'package:asystant_ai/src/model/asystant_action_policy.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/chat_activity_pulse.dart';
import 'package:asystant_ai/src/widgets/asystant_sensitivity_badge.dart';

/// What the assistant did in a turn: live while it works, a record after.
///
/// The header toggles the list of steps; it starts open, like the reference.
class ChatActivityCard extends StatefulWidget {
  const ChatActivityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.steps,
    required this.strings,
    this.tone,
    this.live = false,
    this.closingStep,
  });

  final String title;

  final String subtitle;

  final AsystantGlyphKind icon;

  final List<AssistantStep> steps;

  final AsystantStrings strings;

  /// Icon color; the primary color when null.
  final Color? tone;

  /// Pulses the icon while the turn runs.
  final bool live;

  /// The last row of a live card: analyzing or drafting.
  final String? closingStep;

  @override
  State<ChatActivityCard> createState() => _ChatActivityCardState();
}

class _ChatActivityCardState extends State<ChatActivityCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(tokens.radius / 2);
    return Container(
      margin: EdgeInsets.only(bottom: tokens.spacing + 4),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: radius,
      ),
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: radius,
              child: Padding(
                padding: EdgeInsets.all(tokens.spacing - 4),
                child: Row(
                  children: [
                    Semantics(
                      label: widget.title,
                      liveRegion: widget.live,
                      child: ChatActivityPulse(
                        active: widget.live,
                        child: AsystantGlyph(
                          widget.icon,
                          color: widget.tone ?? colors.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: tokens.spacing - 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(widget.title, style: text.bodyMedium),
                          Text(
                            widget.subtitle,
                            style: text.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AsystantGlyph(
                      _expanded
                          ? AsystantGlyphKind.chevronUp
                          : AsystantGlyphKind.chevron,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(tokens.spacing - 4),
              child: Column(
                children: [
                  _ActivityRow(
                    icon: AsystantGlyphKind.inbox,
                    label: widget.strings.requestReceived,
                    outcome: StepOutcome.done,
                    strings: widget.strings,
                  ),
                  for (final step in widget.steps)
                    _ActivityRow(
                      icon: AsystantGlyphKind.tool,
                      label: switch (step) {
                        AssistantStep(showsProgress: true, :final progressLabel)
                            when progressLabel.isNotEmpty =>
                          '${step.title} · $progressLabel',
                        _ => step.title,
                      },
                      outcome: step.outcome,
                      strings: widget.strings,
                      progress: step.showsProgress ? step.progress : null,
                      images: step.images,
                      sensitivity: step.sensitivity,
                    ),
                  if (widget.closingStep case final label?)
                    _ActivityRow(
                      icon: AsystantGlyphKind.writing,
                      label: label,
                      outcome: StepOutcome.running,
                      strings: widget.strings,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.label,
    required this.outcome,
    required this.strings,
    this.progress,
    this.images = const [],
    this.sensitivity,
  });

  final AsystantGlyphKind icon;

  final String label;

  final StepOutcome outcome;

  final AsystantStrings strings;

  /// How far a running tool has come, from 0 to 1; null shows no bar.
  final double? progress;

  /// What the tool returned for the model to look at, shown under the label.
  final List<AsystantAttachment> images;

  final AsystantSensitivity? sensitivity;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    final colors = Theme.of(context).colorScheme;
    final (glyph, color, tooltip) = switch (outcome) {
      StepOutcome.running => (
        AsystantGlyphKind.pending,
        colors.onSurfaceVariant,
        strings.stepPhase(StepPhase.running),
      ),
      StepOutcome.done => (
        AsystantGlyphKind.check,
        tokens.successColor(context),
        strings.stepPhase(StepPhase.completed),
      ),
      StepOutcome.issue => (
        AsystantGlyphKind.warning,
        colors.error,
        strings.stepPhase(StepPhase.failed),
      ),
    };
    // The images go under the whole row, so the icons stay beside the label.
    final row = Row(
      children: [
        SizedBox.square(
          dimension: _iconSize,
          child: FittedBox(child: AsystantGlyph(icon)),
        ),
        SizedBox(width: tokens.spacing - 4),
        Expanded(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                  if (sensitivity case final level?) ...[
                    SizedBox(width: tokens.spacing / 2),
                    AsystantSensitivityBadge(
                      sensitivity: level,
                      strings: strings,
                      compact: true,
                    ),
                  ],
                ],
              ),
              if (progress case final value?)
                Padding(
                  padding: EdgeInsets.only(top: tokens.spacing / 3),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 2,
                    semanticsLabel: label,
                  ),
                ),
            ],
          ),
        ),
        Tooltip(
          message: tooltip,
          child: SizedBox.square(
            dimension: 15,
            child: FittedBox(child: AsystantGlyph(glyph, color: color)),
          ),
        ),
      ],
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing / 3),
      child: switch (images) {
        [] => row,
        [_, ...] => Column(
          crossAxisAlignment: .start,
          children: [
            row,
            Padding(
              padding: EdgeInsets.only(
                left: _iconSize + tokens.spacing - 4,
                top: tokens.spacing / 2,
              ),
              child: _StepImages(images: images),
            ),
          ],
        ),
      },
    );
  }

  static const double _iconSize = 16;
}

/// The images a tool returned, as thumbnails the person can look at.
class _StepImages extends StatelessWidget {
  const _StepImages({required this.images});

  final List<AsystantAttachment> images;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    final colors = Theme.of(context).colorScheme;
    final height = tokens.stepImageHeight;
    // Decoded at the size it is drawn, not at the size the tool rendered it.
    final cacheHeight = (height * MediaQuery.devicePixelRatioOf(context))
        .round();
    return Wrap(
      spacing: tokens.spacing / 2,
      runSpacing: tokens.spacing / 2,
      children: [
        for (final image in images)
          DecoratedBox(
            position: .foreground,
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(tokens.radius / 4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radius / 4),
              child: Image.memory(
                image.bytes,
                height: height,
                fit: .contain,
                cacheHeight: cacheHeight,
                gaplessPlayback: true,
                semanticLabel: image.filename,
                errorBuilder: (context, error, stackTrace) =>
                    SizedBox.square(dimension: height),
              ),
            ),
          ),
      ],
    );
  }
}

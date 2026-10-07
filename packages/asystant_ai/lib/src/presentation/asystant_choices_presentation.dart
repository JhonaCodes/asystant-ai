import 'package:flutter/widgets.dart';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/presentation/asystant_presentation.dart';
import 'package:asystant_ai/src/widgets/gen_ui_card.dart';

/// Built-in selectable answers for an assistant question.
class AsystantChoicesPresentation extends AsystantPresentation {
  const AsystantChoicesPresentation({this.summary = 'Options shown'});

  /// Visible activity label. Hosts can supply their own translation.
  final String summary;

  @override
  String get id => 'present_choices';

  @override
  String get description =>
      'Ask the user a question with tappable answer buttons in the chat. '
      'Use when offering concrete next actions. This ends the assistant '
      'turn and waits for the user to choose. Read-only.';

  @override
  List<ToolField> get fields => const [
    ToolField(
      name: 'question',
      description: 'Short question shown above the buttons.',
      kind: .string,
    ),
    ToolField(
      name: 'options',
      description: 'Two to six short answer labels.',
      kind: .strings,
    ),
    ToolField(
      name: 'context',
      description: 'Optional brief context shown below the question.',
      kind: .string,
      isRequired: false,
    ),
  ];

  @override
  Result<Map<String, Object?>, AssistantFailure> validate(
    ToolArguments arguments,
  ) {
    final question = arguments.string('question').trim();
    final options = arguments
        .strings('options')
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (question.isEmpty ||
        options.length < 2 ||
        options.length > 6 ||
        options.any((option) => option.length > 100)) {
      return Err(
        const AssistantFailure(
          .invalidTool,
          detail: 'Provide a question and 2 to 6 distinct short options.',
        ),
      );
    }
    return Ok({
      'question': question,
      'options': options,
      'context': (arguments.toJson()['context'] as String? ?? '').trim(),
    });
  }

  AssistantCard _card(Map<String, Object?> input) => AssistantCard(
    title: input['question'] as String,
    body: input['context'] as String,
    kind: .selection,
    options: input['options'] as List<String>,
  );

  @override
  AssistantCard preview(Map<String, Object?> input) => _card(input);

  @override
  Future<Result<AsystantPresentationResult, AssistantFailure>> present(
    Map<String, Object?> input,
    ToolContext context,
  ) async => Ok(
    AsystantPresentationResult(
      card: _card(input),
      modelContent:
          'Question shown with selectable answers. Wait for the user.',
      summary: summary,
      endsTurn: true,
    ),
  );

  @override
  Widget build(
    BuildContext context,
    AsystantPresentationCard card,
    AsystantStrings strings,
    ValueChanged<String>? onOptionPressed,
  ) =>
      GenUiCard(card: card, strings: strings, onOptionPressed: onOptionPressed);
}

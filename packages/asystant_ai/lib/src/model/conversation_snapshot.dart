import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:asystant_core/asystant_core.dart';
import 'package:collection/collection.dart';

import 'package:asystant_ai/src/model/chat_entry.dart';
import 'package:asystant_ai/src/model/conversation_summary.dart';
import 'package:asystant_ai/src/model/assistant_step.dart';
import 'package:asystant_ai/src/model/asystant_action_policy.dart';
import 'package:asystant_ai/src/presentation/asystant_presentation.dart';

/// What the store keeps of a conversation that is not on screen.
class ConversationSnapshot {
  const ConversationSnapshot({
    required this.summary,
    this.messages = const [],
    this.entries = const [],
  });

  final ConversationSummary summary;

  /// The provider transcript, tool calls and results included.
  final List<AssistantMessage> messages;

  /// What the chat shows, in order.
  final List<ChatEntry> entries;

  /// Storage format owned by the Flutter package. Attachment bytes are kept
  /// so reopened conversations can still send the same provider transcript.
  Map<String, Object?> toJson() => {
    'summary': summary.toJson(),
    'messages': messages.map(_messageToJson).toList(),
    'entries': entries
        .map(
          (entry) => {
            'message': entry.message == null
                ? null
                : _messageToJson(entry.message!),
            'card': entry.card?.toJson(),
            'activity': entry.activity
                .map(
                  (step) => {
                    'id': step.id,
                    'title': step.title,
                    'phase': step.phase.name,
                    'tool_name': step.toolName,
                    'started_at': step.startedAt?.toIso8601String(),
                    'detail': step.detail,
                    'progress': step.progress,
                    'progress_label': step.progressLabel,
                    'images': step.images.map(_attachmentToJson).toList(),
                    if (step.sensitivity case final level?)
                      'sensitivity': {
                        'name': level.name,
                        'color': level.color.toARGB32(),
                        if (level.level case final kind?) 'level': kind.name,
                      },
                  },
                )
                .toList(),
          },
        )
        .toList(),
  };

  factory ConversationSnapshot.fromJson(Map<String, Object?> json) =>
      ConversationSnapshot(
        summary: ConversationSummary.fromJson(_object(json['summary'])),
        messages: [
          for (final value in _array(json['messages']))
            _messageFromJson(_object(value)),
        ],
        entries: [
          for (final value in _array(json['entries']))
            _entryFromJson(_object(value)),
        ],
      );

  static ChatEntry _entryFromJson(Map<String, Object?> json) => ChatEntry(
    message: json['message'] == null
        ? null
        : _messageFromJson(_object(json['message'])),
    card: switch (json['card']) {
      null => null,
      final Object value => _cardFromJson(_object(value)),
    },
    activity: [
      for (final value in _array(json['activity']))
        _stepFromJson(_object(value)),
    ],
  );

  static AssistantCard _cardFromJson(Map<String, Object?> json) =>
      json['presentation_id'] is String
      ? AsystantPresentationCard.fromJson(json)
      : AssistantCard.fromJson(json);

  static AssistantStep _stepFromJson(Map<String, Object?> json) =>
      AssistantStep(
        id: json['id'] as String,
        title: json['title'] as String,
        phase: StepPhase.values.byName(json['phase'] as String),
        toolName: json['tool_name'] as String? ?? '',
        sensitivity: switch (json['sensitivity']) {
          final Map<Object?, Object?> value => AsystantSensitivity(
            name: value['name'] as String,
            color: Color(value['color'] as int),
            level: switch (value['level']) {
              final String name => AsystantSensitivityLevel.values.byName(name),
              _ => null,
            },
          ),
          _ => null,
        },
        startedAt: switch (json['started_at']) {
          final String value => DateTime.parse(value),
          _ => null,
        },
        detail: json['detail'] as String? ?? '',
        progress: (json['progress'] as num?)?.toDouble(),
        progressLabel: json['progress_label'] as String? ?? '',
        images: [
          for (final value in _array(json['images']))
            _attachmentFromJson(_object(value)),
        ],
      );

  static Map<String, Object?> _messageToJson(AssistantMessage message) => {
    ...message.toJson(),
    'attachments': message.attachments.map(_attachmentToJson).toList(),
  };

  static AssistantMessage _messageFromJson(Map<String, Object?> json) =>
      AssistantMessage.fromJson(json).copyWith(
        attachments: [
          for (final value in _array(json['attachments']))
            _attachmentFromJson(_object(value)),
        ],
      );

  static Map<String, Object?> _attachmentToJson(AsystantAttachment file) => {
    'id': file.id,
    'filename': file.filename,
    'mime_type': file.mimeType,
    'bytes': base64Encode(file.bytes),
  };

  static AsystantAttachment _attachmentFromJson(Map<String, Object?> json) =>
      AsystantAttachment(
        id: json['id'] as String,
        filename: json['filename'] as String,
        mimeType: json['mime_type'] as String,
        bytes: Uint8List.fromList(base64Decode(json['bytes'] as String)),
      );

  static Map<String, Object?> _object(Object? value) =>
      (value as Map).cast<String, Object?>();

  static List<Object?> _array(Object? value) =>
      (value as List?)?.cast<Object?>() ?? const [];

  ConversationSnapshot copyWith({
    ConversationSummary? summary,
    List<AssistantMessage>? messages,
    List<ChatEntry>? entries,
  }) => ConversationSnapshot(
    summary: summary ?? this.summary,
    messages: List.unmodifiable(messages ?? this.messages),
    entries: List.unmodifiable(entries ?? this.entries),
  );

  @override
  bool operator ==(Object other) =>
      other is ConversationSnapshot &&
      summary == other.summary &&
      const ListEquality<AssistantMessage>().equals(messages, other.messages) &&
      const ListEquality<ChatEntry>().equals(entries, other.entries);

  @override
  int get hashCode =>
      Object.hash(summary, Object.hashAll(messages), Object.hashAll(entries));
}

import 'dart:convert';

import 'package:asystant_core/src/model/assistant_message.dart';
import 'package:asystant_core/src/model/asystant_attachment.dart';

/// Writes conversation messages in OpenRouter's chat-completions format,
/// attached files included.
///
/// Each file goes in the richest form the model accepts: images as images
/// for models that see them, PDFs through OpenRouter's parser, audio for
/// models that hear it, text files as text. Anything else is announced by
/// name and id, so a local tool can process it.
class OpenRouterMessageCodec {
  const OpenRouterMessageCodec({
    required this.inputModalities,
    this.maxAttachmentText = 60000,
  });

  /// What the model accepts besides text, e.g. `{'image', 'file', 'audio'}`.
  final Set<String> inputModalities;

  /// Longest text taken from one text file, in characters.
  final int maxAttachmentText;

  static const _audioFormats = {'audio/wav': 'wav', 'audio/mpeg': 'mp3'};

  /// Whether any message carries a PDF, which needs the parser plugin.
  static bool hasPdf(List<AssistantMessage> messages) =>
      messages.any((message) => message.attachments.any((file) => file.isPdf));

  Map<String, Object?> encode(AssistantMessage message) =>
      switch (message.role) {
        MessageRole.user => {
          'role': 'user',
          'content': message.attachments.isEmpty
              ? message.content
              : [
                  if (message.content.isNotEmpty)
                    {'type': 'text', 'text': message.content},
                  for (final file in message.attachments) _part(file),
                ],
        },
        MessageRole.assistant => {
          'role': 'assistant',
          'content': message.content,
          if (message.calls.isNotEmpty)
            'tool_calls': [
              for (final call in message.calls)
                {
                  'id': call.id,
                  'type': 'function',
                  'function': {
                    'name': call.name,
                    'arguments': call.arguments.encoded,
                  },
                },
            ],
        },
        MessageRole.tool => {
          'role': 'tool',
          'tool_call_id': message.callId,
          'content': message.content,
        },
      };

  Map<String, Object?> _part(AsystantAttachment file) {
    if (file.isImage && inputModalities.contains('image')) {
      return {
        'type': 'image_url',
        'image_url': {'url': _dataUrl(file)},
      };
    }
    if (file.isPdf) {
      return {
        'type': 'file',
        'file': {'filename': file.filename, 'file_data': _dataUrl(file)},
      };
    }
    if (_audioFormats[file.mimeType] case final String format
        when inputModalities.contains('audio')) {
      return {
        'type': 'input_audio',
        'input_audio': {'data': base64Encode(file.bytes), 'format': format},
      };
    }
    if (file.isText) {
      final text = file.text;
      final cut = text.length > maxAttachmentText;
      return {
        'type': 'text',
        'text':
            'Attached file "${file.filename}" (id ${file.id})'
            '${cut ? ', first $maxAttachmentText characters' : ''}:\n'
            '```\n${cut ? text.substring(0, maxAttachmentText) : text}\n```',
      };
    }
    return {
      'type': 'text',
      'text':
          'Attached file "${file.filename}" (${file.mimeType}, '
          '${file.size} bytes, id ${file.id}). You cannot read its contents '
          'directly; a registered tool may process it by its id.',
    };
  }

  static String _dataUrl(AsystantAttachment file) =>
      'data:${file.mimeType};base64,${base64Encode(file.bytes)}';
}

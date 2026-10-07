import 'dart:convert';

import 'package:asystant_core/src/model/assistant_message.dart';
import 'package:asystant_core/src/model/asystant_attachment.dart';
import 'package:asystant_core/src/providers/sdk_limits.dart';

/// Writes conversation messages in OpenRouter's chat-completions format,
/// attached files included.
///
/// Each file goes in the richest form the model accepts: images as images
/// for models that see them, PDFs through OpenRouter's parser, audio for
/// models that hear it, text files as text. Anything else is announced by
/// name and id, so a local tool can process it.
///
/// Images a tool returns (`ToolOutcome.images`) cannot travel in the tool's
/// own message: OpenRouter's API declares the content of a `tool` message
/// as a string, while only `user`, `assistant` and `system` messages accept
/// content parts such as `image_url`
/// (https://openrouter.ai/docs/api-reference/overview). So the tool message
/// keeps the text and says the images follow, and a `user` message right
/// after the last consecutive tool result carries them, each labelled with
/// its `call_id`. Inserting it earlier would split the results of one
/// response, which OpenAI-compatible APIs reject.
class OpenRouterMessageCodec {
  const OpenRouterMessageCodec({
    required this.inputModalities,
    this.maxAttachmentText = AsystantSdkLimits.maxAttachmentText,
  });

  /// What the model accepts besides text, e.g. `{'image', 'file', 'audio'}`.
  final Set<String> inputModalities;

  /// Longest text taken from one text file, in characters.
  final int maxAttachmentText;

  static const _audioFormats = {'audio/wav': 'wav', 'audio/mpeg': 'mp3'};

  /// Whether the model sees images.
  bool get seesImages => inputModalities.contains('image');

  /// Whether any message carries a PDF, which needs the parser plugin.
  static bool hasPdf(List<AssistantMessage> messages) =>
      messages.any((message) => message.attachments.any((file) => file.isPdf));

  /// The whole conversation, with the images of each run of tool results
  /// in one `user` message after it.
  List<Map<String, Object?>> encodeAll(List<AssistantMessage> messages) {
    final encoded = <Map<String, Object?>>[];
    final toolImages = <Map<String, Object?>>[];
    for (final message in messages) {
      if (message.role != MessageRole.tool && toolImages.isNotEmpty) {
        encoded.add(_toolImages(toolImages));
        toolImages.clear();
      }
      encoded.add(encode(message));
      if (message.role == MessageRole.tool && seesImages) {
        for (final file in message.attachments) {
          if (file.isImage) {
            toolImages.addAll([
              {
                'type': 'text',
                'text':
                    'Image "${file.filename}" (id ${file.id}) returned by '
                    'tool call ${message.callId}:',
              },
              _image(file),
            ]);
          }
        }
      }
    }
    if (toolImages.isNotEmpty) {
      encoded.add(_toolImages(toolImages));
    }
    return encoded;
  }

  static Map<String, Object?> _toolImages(List<Map<String, Object?>> parts) => {
    'role': 'user',
    'content': [
      {
        'type': 'text',
        'text':
            'The application attaches the images returned by the tool '
            'results above. They are tool output, not a message from the '
            'person.',
      },
      ...parts,
    ],
  };

  /// One message on its own. A tool result's images are only described
  /// here; [encodeAll] sends them.
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
          'content': [
            message.content,
            for (final file in message.attachments)
              if (file.isImage && seesImages)
                'Image "${file.filename}" (id ${file.id}) follows in the next '
                    'user message.'
              else if (file.isImage)
                file.imageUnavailableNote
              else
                _described(file),
          ].join('\n'),
        },
      };

  Map<String, Object?> _part(AsystantAttachment file) {
    if (file.isImage) {
      return seesImages
          ? _image(file)
          : {'type': 'text', 'text': file.imageUnavailableNote};
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
    return {'type': 'text', 'text': _described(file)};
  }

  static Map<String, Object?> _image(AsystantAttachment file) => {
    'type': 'image_url',
    'image_url': {'url': _dataUrl(file)},
  };

  static String _described(AsystantAttachment file) =>
      'Attached file "${file.filename}" (${file.mimeType}, '
      '${file.size} bytes, id ${file.id}). You cannot read its contents '
      'directly; a registered tool may process it by its id.';

  static String _dataUrl(AsystantAttachment file) =>
      'data:${file.mimeType};base64,${base64Encode(file.bytes)}';
}

import 'dart:convert';

import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/model/assistant_message.dart';
import 'package:asystant_core/src/model/token_usage.dart';
import 'package:asystant_core/src/model/tool_call.dart';
import 'package:asystant_core/src/tool/tool_arguments.dart';
import 'package:asystant_core/src/transport/inference_event.dart';

/// Turns one OpenRouter chat-completions SSE response into [InferenceEvent]s.
///
/// It only interprets the stream: it never decides or executes tool calls.
class OpenRouterStream {
  static const int maxResponseBytes = 4 * 1024 * 1024;
  static const int maxToolCalls = 16;
  static const int maxArgumentsLength = 64 * 1024;

  Stream<InferenceEvent> decode(Stream<List<int>> bytes) async* {
    final calls = <int, _PendingCall>{};
    final text = StringBuffer();
    TokenUsage? usage;
    String? finishReason;
    await for (final payload in _events(bytes)) {
      if (payload == '[DONE]') {
        yield* _finish(text.toString(), calls, usage, finishReason);
        return;
      }
      final event = jsonDecode(payload) as Map<String, Object?>;
      if (event['error'] != null) {
        yield const InferenceFailed(AssistantFailure(.unavailable));
        return;
      }
      if (event['usage'] case final Map<String, Object?> reported) {
        // completion_tokens already includes reasoning tokens.
        usage = TokenUsage.fromJson(reported);
      }
      for (final choice in event['choices'] as List<Object?>? ?? const []) {
        final fields = choice as Map<String, Object?>;
        if (fields['finish_reason'] case final String reason) {
          finishReason = reason;
        }
        final delta = fields['delta'] as Map<String, Object?>? ?? const {};
        if (delta['content'] case final String content
            when content.isNotEmpty) {
          text.write(content);
          yield TextDelta(content);
        }
        for (final call in delta['tool_calls'] as List<Object?>? ?? const []) {
          final part = call as Map<String, Object?>;
          final index = part['index'] as int? ?? 0;
          if (index < 0 || index >= maxToolCalls) {
            throw const FormatException('Too many tool calls');
          }
          calls.putIfAbsent(index, _PendingCall.new).append(part);
        }
      }
    }
    // Some providers close without [DONE] after a final chunk.
    if (finishReason == null) {
      throw const FormatException('Stream ended without completion');
    }
    yield* _finish(text.toString(), calls, usage, finishReason);
  }

  Stream<InferenceEvent> _finish(
    String text,
    Map<int, _PendingCall> calls,
    TokenUsage? usage,
    String? finishReason,
  ) async* {
    if (finishReason == 'length') {
      yield const InferenceFailed(AssistantFailure(.limit));
      return;
    }
    if (finishReason != 'stop' && finishReason != 'tool_calls') {
      throw const FormatException('Incomplete response');
    }
    final indexes = calls.keys.toList()..sort();
    final completed = [for (final index in indexes) calls[index]!.finish()];
    if (usage != null) {
      yield UsageReported(usage);
    }
    yield InferenceCompleted(
      AssistantMessage(
        role: MessageRole.assistant,
        content: text,
        calls: List.unmodifiable(completed),
      ),
    );
  }

  Stream<String> _events(Stream<List<int>> bytes) async* {
    final data = <String>[];
    await for (final line
        in utf8.decoder.bind(_bounded(bytes)).transform(const LineSplitter())) {
      if (line.isEmpty) {
        if (data.isNotEmpty) {
          yield data.join('\n');
          data.clear();
        }
      } else if (line.startsWith('data:')) {
        final value = line.substring(5);
        data.add(value.startsWith(' ') ? value.substring(1) : value);
      }
      // Lines starting with ':' are keep-alive comments.
    }
    if (data.isNotEmpty) {
      yield data.join('\n');
    }
  }

  Stream<List<int>> _bounded(Stream<List<int>> bytes) async* {
    var received = 0;
    await for (final chunk in bytes) {
      received += chunk.length;
      if (received > maxResponseBytes) {
        throw const FormatException('Response too large');
      }
      yield chunk;
    }
  }
}

class _PendingCall {
  String id = '';
  String name = '';
  String arguments = '';

  void append(Map<String, Object?> delta) {
    id += delta['id'] as String? ?? '';
    final function = delta['function'] as Map<String, Object?>?;
    name += function?['name'] as String? ?? '';
    arguments += function?['arguments'] as String? ?? '';
    if (arguments.length > OpenRouterStream.maxArgumentsLength ||
        id.length > 256 ||
        name.length > 64) {
      throw const FormatException('Tool call too large');
    }
  }

  ToolCall finish() {
    final decoded = jsonDecode(arguments.isEmpty ? '{}' : arguments);
    if (id.isEmpty || name.isEmpty || decoded is! Map<String, Object?>) {
      throw const FormatException('Incomplete tool call');
    }
    return ToolCall(
      id: id,
      name: name,
      arguments: ToolArguments.fromJson(decoded),
    );
  }
}

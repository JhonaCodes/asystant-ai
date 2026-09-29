import 'dart:async';
import 'dart:convert';

import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/model/token_usage.dart';
import 'package:asystant_core/src/transport/claude_cli_launcher.dart';
import 'package:asystant_core/src/transport/claude_cli_protocol.dart';
import 'package:asystant_core/src/transport/inference_event.dart';

/// Turns one `claude -p --output-format stream-json` run into
/// [InferenceEvent]s.
///
/// The CLI writes NDJSON, one event per line. The ones read here:
///
/// ```text
/// {"type":"stream_event","event":{"type":"content_block_delta",
///   "delta":{"type":"text_delta","text":"Hel"}}}      -> TextDelta
/// {"type":"assistant","message":{"content":[{"type":"text","text":"…"}]}}
/// {"type":"result","subtype":"success","is_error":false,
///   "stop_reason":"end_turn","usage":{…}}             -> UsageReported,
///                                                        InferenceCompleted
/// ```
///
/// It only interprets the output: it never decides or executes tool calls.
/// stderr is kept as a short tail to classify a failure and is never logged.
class ClaudeCliStream {
  const ClaudeCliStream({this.idleTimeout = const Duration(minutes: 2)});

  /// Longest wait for the next output line before the run is abandoned.
  final Duration idleTimeout;

  /// Most output accepted from one run, in characters.
  static const int maxOutputLength = 8 * 1024 * 1024;

  Stream<InferenceEvent> decode(
    ClaudeCliProcess process, {
    required String requestId,
  }) async* {
    final diagnostics = _Tail();
    final stderr = process.stderrLines.listen(
      diagnostics.add,
      onError: (Object _) {},
    );
    final visible = ClaudeCliVisibleText();
    final blocks = StringBuffer();
    final deltas = StringBuffer();
    var received = 0;
    try {
      await for (final line in process.stdoutLines.timeout(idleTimeout)) {
        received += line.length;
        if (received > maxOutputLength) {
          process.kill();
          yield const InferenceFailed(
            AssistantFailure(.protocol, detail: 'Response too large'),
          );
          return;
        }
        final event = _decode(line);
        // Subagent output cannot occur without tools; skip it if it does.
        if (event == null || event['parent_tool_use_id'] != null) {
          continue;
        }
        switch (event['type']) {
          case 'stream_event':
            if (event['event'] case {
              'type': 'content_block_delta',
              'delta': {'type': 'text_delta', 'text': final String text},
            }) {
              deltas.write(text);
              final shown = visible.add(text);
              if (shown.isNotEmpty) {
                yield TextDelta(shown);
              }
            }
          case 'assistant':
            for (final text in _texts(event)) {
              blocks.write(text);
              // Without partial messages the block is the only delta.
              if (deltas.isEmpty) {
                final shown = visible.add(text);
                if (shown.isNotEmpty) {
                  yield TextDelta(shown);
                }
              }
            }
          case 'result':
            yield* _finish(
              event,
              blocks.isEmpty ? deltas.toString() : blocks.toString(),
              requestId,
            );
            return;
        }
      }
      final code = await process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () => -1,
      );
      yield InferenceFailed(_exitFailure(code, diagnostics.text));
    } on TimeoutException {
      process.kill();
      yield const InferenceFailed(
        AssistantFailure(.network, detail: 'Claude Code stopped responding'),
      );
    } finally {
      await stderr.cancel();
    }
  }

  Stream<InferenceEvent> _finish(
    Map<String, Object?> result,
    String text,
    String requestId,
  ) async* {
    if (result['is_error'] == true || result['subtype'] != 'success') {
      yield InferenceFailed(_resultFailure(result));
      return;
    }
    if (result['stop_reason'] == 'max_tokens') {
      yield const InferenceFailed(AssistantFailure(.limit));
      return;
    }
    final reply = ClaudeCliProtocol.reply(text, requestId: requestId);
    final message = reply.when(ok: (value) => value, err: (_) => null);
    if (message == null) {
      yield InferenceFailed(
        reply.errorOrNull ?? const AssistantFailure(.protocol),
      );
      return;
    }
    if (result['usage']
        case {
              'input_tokens': final int input,
              'output_tokens': final int output,
            } &&
            final Map<String, Object?> usage) {
      // Cached prompt tokens still occupy the context window.
      final cached = [
        usage['cache_creation_input_tokens'],
        usage['cache_read_input_tokens'],
      ].whereType<int>().fold(0, (sum, tokens) => sum + tokens);
      yield UsageReported(
        TokenUsage(promptTokens: input + cached, completionTokens: output),
      );
    }
    yield InferenceCompleted(message);
  }

  static Iterable<String> _texts(Map<String, Object?> event) sync* {
    if (event['message'] case {'content': final List<Object?> content}) {
      for (final block in content) {
        if (block case {'type': 'text', 'text': final String text}) {
          yield text;
        }
      }
    }
  }

  static Map<String, Object?>? _decode(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      return switch (jsonDecode(trimmed)) {
        final Map<String, Object?> event => event,
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }

  /// The CLI reports provider errors as a result with `is_error`; only the
  /// category and a short excerpt are kept.
  static AssistantFailure _resultFailure(Map<String, Object?> result) {
    final status = result['api_error_status'];
    final message = [
      if (result['result'] case final String text) text,
      if (result['errors'] case final List<Object?> errors)
        for (final error in errors)
          if (error case final String text) text,
    ].join(' ');
    return switch (status) {
      401 || 403 => _signedOut,
      429 => const AssistantFailure(.rateLimited),
      413 => const AssistantFailure(.contextFull),
      _ => _classify(message),
    };
  }

  static AssistantFailure _exitFailure(int code, String stderr) {
    final failure = _classify(stderr);
    return failure.code == FailureCode.unavailable
        ? AssistantFailure(
            .unavailable,
            detail: _excerpt(
              'Claude Code exited with code $code without a response. '
              '$stderr',
            ),
          )
        : failure;
  }

  static AssistantFailure _classify(String message) {
    final text = message.toLowerCase();
    if (text.contains('not logged in') ||
        text.contains('/login') ||
        text.contains('invalid api key') ||
        text.contains('oauth token')) {
      return _signedOut;
    }
    if (text.contains('rate limit') || text.contains('usage limit')) {
      return const AssistantFailure(.rateLimited);
    }
    if (text.contains('prompt is too long') ||
        text.contains('context window') ||
        text.contains('context length')) {
      return const AssistantFailure(.contextFull);
    }
    return AssistantFailure(.unavailable, detail: _excerpt(message));
  }

  static const _signedOut = AssistantFailure(
    .authentication,
    detail:
        'Claude Code is not signed in. Run `claude` once in a terminal and '
        'sign in with your subscription.',
  );

  static String _excerpt(String text) {
    final trimmed = text.trim();
    return trimmed.length <= 300 ? trimmed : '${trimmed.substring(0, 300)}…';
  }
}

/// The last few stderr lines, bounded, for failure classification only.
class _Tail {
  final List<String> _lines = [];

  void add(String line) {
    _lines.add(line.length > 500 ? line.substring(0, 500) : line);
    if (_lines.length > 8) {
      _lines.removeAt(0);
    }
  }

  String get text => _lines.join('\n');
}

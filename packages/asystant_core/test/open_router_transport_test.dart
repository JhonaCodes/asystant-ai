import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:asystant_core/asystant_core.dart';
import 'package:test/test.dart';

/// A local OpenRouter stand-in, so requests go through the real `dart:io`
/// HTTP stack and its header rules.
class _LocalOpenRouter {
  _LocalOpenRouter._(this._server);

  static Future<_LocalOpenRouter> start() async =>
      _LocalOpenRouter._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0))
        .._serve();

  final HttpServer _server;

  final List<String> titles = [];

  final List<String> authorizations = [];

  final List<Map<String, Object?>> bodies = [];

  Uri get baseUri => Uri.parse('http://127.0.0.1:${_server.port}/api/v1/');

  void _serve() => _server.listen((request) async {
    if (request.uri.path.endsWith('/chat/completions')) {
      titles.add(request.headers.value('x-title') ?? '');
      authorizations.add(request.headers.value('authorization') ?? '');
      bodies.add(
        jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, Object?>,
      );
      request.response.headers.contentType = ContentType(
        'text',
        'event-stream',
      );
      request.response.write(
        'data: {"id":"g","choices":[{"index":0,"delta":{"role":"assistant",'
        '"content":"Hola"},"finish_reason":null}]}\n\n'
        'data: {"id":"g","choices":[{"index":0,"delta":{"content":""},'
        '"finish_reason":"stop"}]}\n\n'
        'data: [DONE]\n\n',
      );
    } else if (request.uri.path.endsWith('/models/vision/model/endpoints')) {
      // A model that sees images; any other model's metadata is missing.
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'data': {
            'architecture': {
              'input_modalities': ['text', 'image'],
            },
            'endpoints': <Object?>[],
          },
        }),
      );
    } else {
      request.response.statusCode = HttpStatus.notFound;
    }
    await request.response.close();
  });

  Future<void> close() => _server.close(force: true);
}

/// Replies to `chat/completions` with a fixed HTTP status and body, to drive
/// `OpenRouterTransport`'s error classification.
class _FailingOpenRouter {
  _FailingOpenRouter._(this._server);

  static Future<_FailingOpenRouter> start(int status, String body) async =>
      _FailingOpenRouter._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0))
        .._serve(status, body);

  final HttpServer _server;

  Uri get baseUri => Uri.parse('http://127.0.0.1:${_server.port}/api/v1/');

  void _serve(int status, String body) => _server.listen((request) async {
    request.response.statusCode = status;
    request.response.write(body);
    await request.response.close();
  });

  Future<void> close() => _server.close(force: true);
}

void main() {
  test('an app name with accents still reaches the model', () async {
    final server = await _LocalOpenRouter.start();
    addTearDown(server.close);
    final transport = OpenRouterTransport(
      credentials: () async => Ok(OpenRouterCredential(apiKey: 'test-key')),
      baseUri: server.baseUri,
      appName: 'Botánica 100%',
    );
    addTearDown(transport.dispose);
    await transport.initialize(
      tools: const [],
      prompts: const [],
      models: const ['openai/gpt-oss-120b'],
    );

    final events = await transport
        .infer(
          messages: const [
            AssistantMessage(role: MessageRole.user, content: 'Hola'),
          ],
          model: 'openai/gpt-oss-120b',
          requestId: 'r1',
        )
        .toList();

    expect(events.whereType<InferenceFailed>(), isEmpty);
    expect(
      events.whereType<InferenceCompleted>().single.message.content,
      'Hola',
    );
    // Sent as ASCII, and nothing of the name is lost on the way.
    expect(server.titles.single, 'Bot%C3%A1nica 100%25');
    expect(Uri.decodeComponent(server.titles.single), 'Botánica 100%');
  });

  test(
    'the host context goes after the fixed prompts, for that call',
    () async {
      final server = await _LocalOpenRouter.start();
      addTearDown(server.close);
      final transport = OpenRouterTransport(
        credentials: () async => Ok(OpenRouterCredential(apiKey: 'test-key')),
        baseUri: server.baseUri,
      );
      addTearDown(transport.dispose);
      await transport.initialize(
        tools: const [],
        prompts: const [
          AsystantSystemPrompt(id: 'role', content: 'Fixed role'),
        ],
        models: const ['openai/gpt-oss-120b'],
      );

      await transport
          .infer(
            messages: const [
              AssistantMessage(role: MessageRole.user, content: 'Hola'),
            ],
            model: 'openai/gpt-oss-120b',
            requestId: 'r1',
            context: const [
              AsystantSystemPrompt(id: 'profile', content: 'Allergy: pollen'),
            ],
          )
          .drain<void>();

      final messages = server.bodies.single['messages'] as List<Object?>;
      final contents = [
        for (final message in messages.cast<Map<String, Object?>>())
          '${message['role']}: ${message['content']}',
      ];
      expect(contents.skip(contents.length - 3), [
        'system: Fixed role',
        'system: Allergy: pollen',
        'user: Hola',
      ]);
    },
  );

  test('a key cached for one login is never used for another', () async {
    final server = await _LocalOpenRouter.start();
    addTearDown(server.close);
    var signedIn = 'ana';
    var issued = 0;
    final transport = OpenRouterTransport(
      credentials: () async {
        issued++;
        return Ok(OpenRouterCredential(apiKey: 'key-of-$signedIn'));
      },
      identity: () => signedIn,
      baseUri: server.baseUri,
    );
    addTearDown(transport.dispose);
    await transport.initialize(
      tools: const [],
      prompts: const [],
      models: const ['openai/gpt-oss-120b'],
    );
    Future<void> ask() => transport
        .infer(
          messages: const [
            AssistantMessage(role: MessageRole.user, content: 'Hola'),
          ],
          model: 'openai/gpt-oss-120b',
          requestId: 'r$issued',
        )
        .drain<void>();

    await ask();
    signedIn = 'luis';
    await ask();

    expect(issued, 2);
    expect(server.authorizations, ['Bearer key-of-ana', 'Bearer key-of-luis']);
  });

  test(
    'a tool image follows its results as a user message, since a tool '
    'message only carries text; a model without vision gets a note',
    () async {
      final server = await _LocalOpenRouter.start();
      addTearDown(server.close);
      final transport = OpenRouterTransport(
        credentials: () async => Ok(OpenRouterCredential(apiKey: 'test-key')),
        baseUri: server.baseUri,
      );
      addTearDown(transport.dispose);
      await transport.initialize(
        tools: const [],
        prompts: const [],
        models: const ['vision/model', 'text/model'],
      );
      final frame = AsystantAttachment.fromBytes(
        bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
        filename: 'frame.png',
      );
      final messages = [
        const AssistantMessage(role: MessageRole.user, content: 'Check it'),
        AssistantMessage(
          role: MessageRole.assistant,
          content: '',
          calls: [
            ToolCall(
              id: 'call_a',
              name: 'look',
              arguments: ToolArguments.fromJson(const {}),
            ),
            ToolCall(
              id: 'call_b',
              name: 'count',
              arguments: ToolArguments.fromJson(const {}),
            ),
          ],
        ),
        AssistantMessage(
          role: MessageRole.tool,
          content: 'Rendered',
          callId: 'call_a',
          attachments: [frame],
        ),
        const AssistantMessage(
          role: MessageRole.tool,
          content: '3',
          callId: 'call_b',
        ),
      ];
      Future<List<Map<String, Object?>>> sent(String model) async {
        await transport
            .infer(messages: messages, model: model, requestId: model)
            .drain<void>();
        return (server.bodies.last['messages'] as List<Object?>)
            .cast<Map<String, Object?>>();
      }

      expect(transport.supportsImageInput('vision/model'), isTrue);
      final seen = await sent('vision/model');
      // Both results stay together, right after the calls; then the image.
      expect(
        [for (final m in seen) m['role']],
        ['system', 'user', 'assistant', 'tool', 'tool', 'user'],
      );
      expect(seen[3]['content'], isA<String>());
      expect(seen[3]['content'], contains('follows in the next user message'));
      final parts = (seen[5]['content'] as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(parts[1]['text'], contains('call_a'));
      expect(parts[2], {
        'type': 'image_url',
        'image_url': {
          'url': 'data:image/png;base64,${base64Encode(frame.bytes)}',
        },
      });

      expect(transport.supportsImageInput('text/model'), isFalse);
      final blind = await sent('text/model');
      expect([for (final m in blind) m['role']].last, 'tool');
      expect(blind[3]['content'], contains(frame.imageUnavailableNote));
    },
  );

  test(
    'a "too many tokens" error is classified as contextFull, the same as '
    "Claude Code's own classification",
    () async {
      final server = await _FailingOpenRouter.start(
        400,
        '{"error":{"message":"too many tokens in the request"}}',
      );
      addTearDown(server.close);
      final transport = OpenRouterTransport(
        credentials: () async => Ok(OpenRouterCredential(apiKey: 'test-key')),
        baseUri: server.baseUri,
      );
      addTearDown(transport.dispose);
      await transport.initialize(
        tools: const [],
        prompts: const [],
        models: const ['openai/gpt-oss-120b'],
      );

      final events = await transport
          .infer(
            messages: const [
              AssistantMessage(role: MessageRole.user, content: 'Hola'),
            ],
            model: 'openai/gpt-oss-120b',
            requestId: 'r1',
          )
          .toList();

      final failure = (events.single as InferenceFailed).failure;
      expect(failure.code, FailureCode.contextFull);
    },
  );
}

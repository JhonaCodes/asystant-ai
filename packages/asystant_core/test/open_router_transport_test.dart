import 'dart:convert';
import 'dart:io';

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

  final List<Map<String, Object?>> bodies = [];

  Uri get baseUri => Uri.parse('http://127.0.0.1:${_server.port}/api/v1/');

  void _serve() => _server.listen((request) async {
    if (request.uri.path.endsWith('/chat/completions')) {
      titles.add(request.headers.value('x-title') ?? '');
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
    } else {
      request.response.statusCode = HttpStatus.notFound;
    }
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
}

import 'dart:async';
import 'dart:convert';

import 'package:asystant_core/asystant_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class TestSession extends SessionSource {
  String? current = 'u1';
  int tickets = 0;
  @override
  String? get identity => current;
  @override
  Stream<void> get changes => const Stream.empty();
  @override
  Future<Result<String, AssistantFailure>> issueTicket() async =>
      Ok('ticket-${++tickets}');
}

void main() {
  test('server-assigned model may replace an old client preference', () async {
    final transport = GatewayTransport(
      baseUri: Uri.parse('https://gateway.test'),
      sessionSource: TestSession(),
      clientFactory: () => MockClient(
        (r) async => http.Response(
          r.url.path.endsWith('exchange')
              ? jsonEncode({
                  'token': 'secret',
                  'expires_at': DateTime.now()
                      .toUtc()
                      .add(const Duration(minutes: 10))
                      .toIso8601String(),
                })
              : '{"id":"r","models":["assigned"],"default_model":"assigned","allow_selection":false}',
          200,
        ),
      ),
    );
    final result = await transport.initialize(
      tools: [],
      prompts: [],
      models: ['old'],
    );
    expect(result.isOk, isTrue);
    expect(result.when(ok: (models) => models, err: (_) => <String>[]), [
      'assigned',
    ]);
    await transport.dispose();
  });

  test(
    'refreshes expiring credentials before a turn and keeps registration',
    () async {
      final session = TestSession();
      var exchanges = 0;
      final transport = GatewayTransport(
        baseUri: Uri.parse('https://gateway.test'),
        sessionSource: session,
        clientFactory: () => MockClient((r) async {
          switch (r.url.path) {
            case '/v1/sessions/exchange':
              exchanges++;
              return http.Response(
                jsonEncode({
                  'token': 'secret-$exchanges',
                  'expires_at': DateTime.now()
                      .toUtc()
                      .add(Duration(seconds: exchanges == 1 ? 10 : 600))
                      .toIso8601String(),
                }),
                200,
              );
            case '/v1/assistants/init':
              return http.Response(
                '{"id":"registration","models":["test"]}',
                200,
              );
            case '/v1/turns':
              expect(r.headers['Authorization'], 'Bearer secret-2');
              expect(
                (jsonDecode(r.body) as Map<String, Object?>)['registration_id'],
                'registration',
              );
              return http.Response(
                'data: {"type":"completed","message":{"role":"assistant","content":"Hi"}}\n\n',
                200,
              );
            default:
              return http.Response('', 404);
          }
        }),
      );
      expect(
        (await transport.initialize(
          tools: [],
          prompts: [],
          models: ['test'],
        )).isOk,
        isTrue,
      );
      final events = await transport
          .infer(messages: [], model: 'test', requestId: 'r')
          .toList();
      expect(events.single, isA<InferenceCompleted>());
      expect(exchanges, 2);
      await transport.dispose();
    },
  );
  test('malformed credential response is a typed failure', () async {
    final transport = GatewayTransport(
      baseUri: Uri.parse('https://gateway.test'),
      sessionSource: TestSession(),
      clientFactory: () => MockClient((_) async => http.Response('{}', 200)),
    );
    expect(
      (await transport.initialize(
        tools: [],
        prompts: [],
        models: ['test'],
      )).isErr,
      isTrue,
    );
    await transport.dispose();
  });
  test('truncated stream fails rather than pretending completion', () async {
    final transport = GatewayTransport(
      baseUri: Uri.parse('https://gateway.test'),
      sessionSource: TestSession(),
      clientFactory: () => MockClient(
        (r) async => http.Response(
          r.url.path.endsWith('exchange')
              ? jsonEncode({
                  'token': 'secret',
                  'expires_at': DateTime.now()
                      .toUtc()
                      .add(const Duration(minutes: 10))
                      .toIso8601String(),
                })
              : r.url.path.endsWith('init')
              ? '{"id":"r","models":["test"]}'
              : 'data: {"type":"text_delta","text":"partial"}\n\n',
          200,
        ),
      ),
    );
    await transport.initialize(tools: [], prompts: [], models: ['test']);
    final events = await transport
        .infer(messages: [], model: 'test', requestId: 'r')
        .toList();
    expect(events.last, isA<InferenceFailed>());
    await transport.dispose();
  });
}

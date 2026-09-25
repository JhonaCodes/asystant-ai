import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:result_controller/result_controller.dart';
import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/model/assistant_message.dart';
import 'package:asystant_core/src/model/system_prompt.dart';
import 'package:asystant_core/src/tool/tool_definition.dart';
import 'package:asystant_core/src/transport/assistant_transport.dart';
import 'package:asystant_core/src/transport/inference_event.dart';
import 'package:asystant_core/src/transport/session_source.dart';

/// HTTP/SSE transport with memory-only credentials renewed through the host session.
class GatewayTransport extends AssistantTransport {
  GatewayTransport({
    required this.baseUri,
    required this.sessionSource,
    http.Client Function()? clientFactory,
  }) : _clientFactory = clientFactory ?? http.Client.new;

  /// Base address of a compatible gateway. Use HTTPS outside local development.
  final Uri baseUri;

  /// Host authentication bridge; never a provider API key.
  final SessionSource sessionSource;
  final http.Client Function() _clientFactory;
  String? _token;
  String? _boundIdentity;
  String? _registration;
  String? _defaultModel;
  bool _allowSelection = true;
  @override
  String? get defaultModel => _defaultModel;
  @override
  bool get allowModelSelection => _allowSelection;
  DateTime _expires = DateTime.fromMillisecondsSinceEpoch(0);
  http.Client? _active;
  int _epoch = 0;
  bool _disposed = false;
  @override
  String? get identity => sessionSource.identity;
  @override
  bool get isAuthenticated =>
      identity != null &&
      identity == _boundIdentity &&
      _token != null &&
      DateTime.now().toUtc().isBefore(_expires);
  @override
  Stream<void> get sessionChanges => sessionSource.changes;
  Uri _url(String path) => baseUri.resolve(path);
  Future<Result<String, AssistantFailure>> _access() async {
    final identityAtStart = identity;
    if (_disposed || identityAtStart == null) {
      return Err(AssistantFailure(.authentication));
    }
    if (_token != null &&
        identityAtStart == _boundIdentity &&
        DateTime.now()
            .toUtc()
            .add(const Duration(seconds: 30))
            .isBefore(_expires)) {
      return Ok(_token ?? '');
    }
    final ticket = await sessionSource.issueTicket();
    return ticket.when(
      ok: (ticket) async {
        final exchange = await _post('/v1/sessions/exchange', {
          'ticket': ticket,
        });
        return exchange.when(
          ok: (json) {
            if (_disposed || identity != identityAtStart) {
              return Err(AssistantFailure(.authentication));
            }
            final rawToken = json['token'];
            final rawExpiry = json['expires_at'];
            final expiry = rawExpiry is String
                ? DateTime.tryParse(rawExpiry)?.toUtc()
                : null;
            if (rawToken is! String ||
                rawToken.isEmpty ||
                expiry == null ||
                !expiry.isAfter(DateTime.now().toUtc())) {
              return Err(const AssistantFailure(.protocol));
            }
            _token = rawToken;
            _expires = expiry;
            _boundIdentity = identityAtStart;
            return Ok(_token ?? '');
          },
          err: Err.new,
        );
      },
      err: (failure) async => Err(failure),
    );
  }

  Future<Result<Map<String, Object?>, AssistantFailure>> _post(
    String path,
    Map<String, Object?> body, {
    String? token,
  }) async {
    final client = _clientFactory();
    try {
      final response = await client
          .post(
            _url(path),
            headers: {
              'Content-Type': 'application/json',
              if (token case final token?) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 401) {
        _token = null;
      }
      if (response.statusCode != 200 && response.statusCode != 204) {
        return Err(_failure(response.statusCode));
      }
      if (response.statusCode == 204) {
        return Ok(const <String, Object?>{});
      }
      return Ok(jsonDecode(response.body) as Map<String, Object?>);
    } on TimeoutException {
      return Err(AssistantFailure(.network));
    } on http.ClientException {
      return Err(AssistantFailure(.network));
    } on FormatException {
      return Err(AssistantFailure(.protocol));
    } on TypeError {
      return Err(AssistantFailure(.protocol));
    } finally {
      client.close();
    }
  }

  AssistantFailure _failure(int status) => AssistantFailure(switch (status) {
    401 || 403 => .authentication,
    402 => .budget,
    429 => .limit,
    _ => .unavailable,
  });
  @override
  Future<Result<List<String>, AssistantFailure>> initialize({
    required List<ToolDefinition> tools,
    required List<AsystantSystemPrompt> prompts,
    required List<String> models,
  }) async {
    final identityAtStart = identity;
    final access = await _access();
    return access.when(
      ok: (token) async {
        final registration = await _post('/v1/assistants/init', {
          'tools': tools.map((tool) => tool.toSchema()).toList(),
          'prompts': prompts.map((p) => p.content).toList(),
          'models': models,
        }, token: token);
        return registration.when(
          ok: (json) {
            final id = json['id'];
            final allowed = json['models'];
            if (id is! String ||
                id.isEmpty ||
                allowed is! List<Object?> ||
                allowed.isEmpty ||
                allowed.any((m) => m is! String || m.isEmpty)) {
              return Err(const AssistantFailure(.protocol));
            }
            if (_disposed ||
                identity != _boundIdentity ||
                identity != identityAtStart) {
              return Err(const AssistantFailure(.authentication));
            }
            final assigned = json['default_model'] ?? allowed.first;
            final selectable = json['allow_selection'] ?? true;
            if (assigned is! String ||
                !allowed.contains(assigned) ||
                selectable is! bool) {
              return Err(const AssistantFailure(.protocol));
            }
            _defaultModel = assigned;
            _allowSelection = selectable;
            _registration = id;
            return Ok(List<String>.unmodifiable(allowed.cast<String>()));
          },
          err: Err.new,
        );
      },
      err: (failure) async => Err(failure),
    );
  }

  @override
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
  }) async* {
    final epoch = ++_epoch;
    try {
      final access = await _access();
      final token = access.when(ok: (token) => token, err: (failure) => null);
      if (token == null) {
        yield InferenceFailed(
          access.errorOrNull ?? const AssistantFailure(.authentication),
        );
        return;
      }
      if (epoch != _epoch || _disposed) {
        return;
      }
      final client = _clientFactory();
      _active = client;
      final request = http.Request('POST', _url('/v1/turns'))
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        })
        ..body = jsonEncode({
          'registration_id': _registration,
          'request_id': requestId,
          'model': model,
          'messages': messages.map((m) => m.toJson()).toList(),
        });
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          _token = null;
        }
        yield InferenceFailed(_failure(response.statusCode));
        return;
      }
      var completed = false;
      var total = 0;
      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .timeout(const Duration(seconds: 90))) {
        if (epoch != _epoch || _disposed) {
          return;
        }
        total += line.length;
        if (total > 2000000) {
          throw const FormatException('Stream limit');
        }
        if (!line.startsWith('data:')) {
          continue;
        }
        final envelope =
            jsonDecode(line.substring(5).trim()) as Map<String, Object?>;
        if (completed) {
          throw const FormatException('Event after completion');
        }
        switch (envelope['type']) {
          case 'text_delta':
            yield TextDelta(envelope['text'] as String);
          case 'completed':
            completed = true;
            yield InferenceCompleted(
              AssistantMessage.fromJson(
                envelope['message'] as Map<String, Object?>,
              ),
            );
          case 'failed':
            yield InferenceFailed(
              AssistantFailure.fromJson(
                envelope['failure'] as Map<String, Object?>,
              ),
            );
            return;
          default:
            throw const FormatException('Unknown event');
        }
      }
      if (!completed) {
        yield const InferenceFailed(AssistantFailure(.protocol));
      }
    } on TimeoutException {
      yield const InferenceFailed(AssistantFailure(.network));
    } on http.ClientException {
      if (epoch == _epoch) {
        yield const InferenceFailed(AssistantFailure(.network));
      }
    } on FormatException {
      yield const InferenceFailed(AssistantFailure(.protocol));
    } on ArgumentError {
      yield const InferenceFailed(AssistantFailure(.protocol));
    } on TypeError {
      yield const InferenceFailed(AssistantFailure(.protocol));
    } finally {
      if (epoch == _epoch) {
        _active?.close();
        _active = null;
      }
    }
  }

  Future<Result<bool, AssistantFailure>> revokeSession() async {
    cancel();
    final token = _token;
    _token = null;
    _registration = null;
    _defaultModel = null;
    _boundIdentity = null;
    if (token == null) {
      return Ok(true);
    }
    final result = await _post('/v1/sessions/revoke', const {}, token: token);
    return result.when(ok: (_) => Ok(true), err: Err.new);
  }

  @override
  void cancel() {
    _epoch++;
    _active?.close();
    _active = null;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    cancel();
    _token = null;
    _registration = null;
    _defaultModel = null;
    _boundIdentity = null;
  }
}

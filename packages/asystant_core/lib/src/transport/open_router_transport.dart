import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/model/assistant_message.dart';
import 'package:asystant_core/src/model/asystant_prompt_policy.dart';
import 'package:asystant_core/src/model/system_prompt.dart';
import 'package:asystant_core/src/tool/tool_definition.dart';
import 'package:asystant_core/src/transport/assistant_transport.dart';
import 'package:asystant_core/src/transport/inference_event.dart';
import 'package:asystant_core/src/transport/open_router_credential.dart';
import 'package:asystant_core/src/transport/open_router_message_codec.dart';
import 'package:asystant_core/src/transport/open_router_stream.dart';

/// Talks to OpenRouter directly with the signed-in user's own key.
///
/// The key comes from [credentials] (in production, a budget-limited key that
/// the host backend obtains from asystant-api), is cached until it must be
/// refreshed, and is only ever placed in the `Authorization` header.
class OpenRouterTransport extends AssistantTransport {
  OpenRouterTransport({
    required OpenRouterCredentialSource credentials,
    String? Function()? identity,
    Stream<void>? sessionChanges,
    this.baseUri,
    this.appName,
    this.appUrl,
    this.maxOutputTokens,
    this.temperature,
    this.pdfEngine = 'pdf-text',
    http.Client Function()? clientFactory,
    DateTime Function()? clock,
  }) : _credentials = credentials,
       _identity = identity ?? _alwaysSignedIn,
       sessionChanges = sessionChanges ?? const Stream.empty(),
       _clientFactory = clientFactory ?? http.Client.new,
       _clock = clock ?? DateTime.now;

  static final Uri defaultBaseUri = Uri.parse('https://openrouter.ai/api/v1/');

  /// OpenRouter's API root; override it for a compatible proxy.
  final Uri? baseUri;

  /// Sent as `X-Title` so usage is attributed to the app in OpenRouter.
  /// Any name works: headers carry ASCII only, so other characters travel
  /// percent-encoded ("Botánica" is sent as "Bot%C3%A1nica").
  final String? appName;

  /// Sent as `HTTP-Referer` together with [appName].
  final String? appUrl;

  /// Upper bound for each response; the model's default when null.
  final int? maxOutputTokens;

  final double? temperature;

  /// How OpenRouter reads attached PDFs: `pdf-text` (free, text layer),
  /// `mistral-ocr` (paid, scanned documents) or `native` (models that read
  /// PDFs themselves).
  final String pdfEngine;

  final OpenRouterCredentialSource _credentials;

  final String? Function() _identity;

  final http.Client Function() _clientFactory;

  final DateTime Function() _clock;

  @override
  final Stream<void> sessionChanges;

  OpenRouterCredential? _credential;

  /// The login the cached [_credential] was issued for. A key is reused only
  /// while the same identity is signed in: another user never inherits it.
  String? _credentialOwner;

  List<AsystantSystemPrompt> _prompts = const [];

  List<Map<String, Object?>> _tools = const [];

  final Map<String, int> _contextLengths = {};

  final Map<String, Set<String>> _inputModalities = {};

  http.Client? _active;

  var _epoch = 0;

  var _disposed = false;

  static String? _alwaysSignedIn() => 'local';

  Uri _url(String path) => (baseUri ?? defaultBaseUri).resolve(path);

  @override
  bool get isAuthenticated => _identity() != null;

  @override
  String? get identity => _identity();

  @override
  int? contextLengthOf(String model) => _contextLengths[model];

  @override
  Future<Result<List<String>, AssistantFailure>> initialize({
    required List<ToolDefinition> tools,
    required List<AsystantSystemPrompt> prompts,
    required List<String> models,
  }) async {
    final policy = const AsystantPromptPolicy().compose(prompts);
    final composed = policy.when(ok: (value) => value, err: (_) => null);
    if (composed == null) {
      return Err(policy.errorOrNull ?? const AssistantFailure(.protocol));
    }
    final access = await _access();
    final credential = access.when(ok: (value) => value, err: (_) => null);
    if (credential == null) {
      return Err(access.errorOrNull ?? const AssistantFailure(.authentication));
    }
    final permitted = _permitted(models, credential.allowedModels);
    if (permitted.isEmpty) {
      return Err(const AssistantFailure(.unavailable));
    }
    _prompts = composed;
    _tools = List.unmodifiable([
      for (final tool in tools)
        {'type': 'function', 'function': tool.toSchema()},
    ]);
    await Future.wait(permitted.map(_loadModel));
    return Ok(List.unmodifiable(permitted));
  }

  /// The host's preferred order, limited to what the key allows.
  List<String> _permitted(List<String> preferred, List<String> allowed) {
    if (preferred.isEmpty) {
      return allowed;
    }
    if (allowed.isEmpty) {
      return preferred;
    }
    return [
      for (final model in preferred)
        if (allowed.contains(model)) model,
    ];
  }

  /// Reads the model's context window and the inputs it accepts. Without
  /// them the meter stays hidden and files are sent as text only.
  Future<void> _loadModel(String model) async {
    final client = _clientFactory();
    try {
      final response = await client
          .get(_url('models/$model/endpoints'), headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return;
      }
      final body = jsonDecode(response.body) as Map<String, Object?>;
      final data = body['data'] as Map<String, Object?>? ?? const {};
      final architecture =
          data['architecture'] as Map<String, Object?>? ?? const {};
      _inputModalities[model] = {
        for (final modality
            in architecture['input_modalities'] as List<Object?>? ?? const [])
          if (modality case final String name) name,
      };
      final lengths = [
        for (final endpoint in data['endpoints'] as List<Object?>? ?? const [])
          if ((endpoint as Map<String, Object?>)['context_length']
              case final int length)
            length,
      ];
      if (lengths.isNotEmpty) {
        _contextLengths[model] = lengths.reduce((a, b) => a > b ? a : b);
      }
    } on Exception {
      // Optional metadata: the chat works without it.
    } on TypeError {
      // Same: an unexpected shape only hides the meter.
    } finally {
      client.close();
    }
  }

  Future<Result<OpenRouterCredential, AssistantFailure>> _access() async {
    final cached = _credential;
    final owner = _identity();
    if (cached != null &&
        _credentialOwner == owner &&
        cached.usableAt(_clock())) {
      return Ok(cached);
    }
    _credential = null;
    _credentialOwner = null;
    final issued = await _credentials();
    return issued.when(
      ok: (credential) {
        if (!credential.usableAt(_clock())) {
          return Err(const AssistantFailure(.authentication));
        }
        _credential = credential;
        _credentialOwner = owner;
        return Ok(credential);
      },
      err: (failure) => Err(failure),
    );
  }

  Map<String, String> _headers([OpenRouterCredential? credential]) => {
    if (credential != null) 'Authorization': credential.authorization,
    if (appName case final String name) 'X-Title': _headerValue(name),
    if (appUrl case final String url) 'HTTP-Referer': _headerValue(url),
  };

  /// Printable ASCII as is; anything else, and `%` itself, percent-encoded,
  /// so the value is always a valid header and decodes back unchanged.
  static String _headerValue(String value) => [
    for (final rune in value.runes)
      if (rune >= 0x20 && rune < 0x7F && rune != 0x25)
        String.fromCharCode(rune)
      else
        Uri.encodeComponent(String.fromCharCode(rune)),
  ].join();

  @override
  Stream<InferenceEvent> infer({
    required List<AssistantMessage> messages,
    required String model,
    required String requestId,
    List<AsystantSystemPrompt> context = const [],
  }) async* {
    final epoch = ++_epoch;
    try {
      final access = await _access();
      final credential = access.when(ok: (value) => value, err: (_) => null);
      if (credential == null) {
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
      final request = http.Request('POST', _url('chat/completions'))
        ..headers.addAll({
          ..._headers(credential),
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        })
        ..body = jsonEncode(_body(messages, model, context));
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        if (response.statusCode == 401 || response.statusCode == 403) {
          _credential = null;
        }
        final detail = await response.stream
            .transform(utf8.decoder)
            .join()
            .timeout(const Duration(seconds: 10));
        yield InferenceFailed(_failure(response.statusCode, detail));
        return;
      }
      await for (final event in OpenRouterStream().decode(
        response.stream.timeout(const Duration(seconds: 90)),
      )) {
        if (epoch != _epoch || _disposed) {
          return;
        }
        yield event;
      }
    } on TimeoutException {
      yield const InferenceFailed(AssistantFailure(.network));
    } on http.ClientException {
      if (epoch == _epoch) {
        yield const InferenceFailed(AssistantFailure(.network));
      }
    } on FormatException {
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

  Map<String, Object?> _body(
    List<AssistantMessage> messages,
    String model,
    List<AsystantSystemPrompt> context,
  ) {
    final codec = OpenRouterMessageCodec(
      inputModalities: _inputModalities[model] ?? const {},
    );
    return {
      'model': model,
      'stream': true,
      'usage': {'include': true},
      'parallel_tool_calls': false,
      if (maxOutputTokens case final int tokens) 'max_tokens': tokens,
      if (temperature case final double value) 'temperature': value,
      if (OpenRouterMessageCodec.hasPdf(messages))
        'plugins': [
          {
            'id': 'file-parser',
            'pdf': {'engine': pdfEngine},
          },
        ],
      'messages': [
        for (final prompt in [..._prompts, ...context])
          {'role': 'system', 'content': prompt.content},
        for (final message in messages) codec.encode(message),
      ],
      if (_tools.isNotEmpty) 'tools': _tools,
    };
  }

  /// [detail] is the provider's error body; only its category is kept.
  AssistantFailure _failure(int status, String detail) => switch (status) {
    401 || 403 => const AssistantFailure(.authentication),
    402 => const AssistantFailure(.budget),
    413 => const AssistantFailure(.contextFull),
    400 when _mentionsContext(detail) => const AssistantFailure(.contextFull),
    429 => const AssistantFailure(.rateLimited),
    408 => const AssistantFailure(.network),
    >= 500 => const AssistantFailure(.unavailable),
    _ => const AssistantFailure(.protocol),
  };

  static bool _mentionsContext(String detail) {
    final text = detail.toLowerCase();
    return text.contains('context length') ||
        text.contains('context_length') ||
        text.contains('context window') ||
        text.contains('too many tokens');
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
    _credential = null;
  }
}

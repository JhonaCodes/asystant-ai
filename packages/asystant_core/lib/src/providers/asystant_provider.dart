/// Where the assistant's answers come from.
///
/// Each provider lives in its own folder under `providers/`, with its
/// transport and everything it needs, and declares its variant of
/// [AsystantProvider] in a `part` of this library (Dart requires the
/// subclasses of a sealed class to be in the same library). Adding a
/// provider adds one `import` and one `part` line here and changes nothing
/// else in the SDK; see "Adding a provider" in `docs/public-api.md`.
library;

import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/model/assistant_failure.dart';
import 'package:asystant_core/src/model/asystant_model_catalog.dart';
import 'package:asystant_core/src/model/asystant_provider_status.dart';
import 'package:asystant_core/src/transport/assistant_transport.dart';

// One import and one part per provider.
import 'package:asystant_core/src/providers/claude_code/claude_code.dart';
import 'package:asystant_core/src/providers/openrouter/openrouter.dart';

part 'claude_code/claude_code_provider.dart';
part 'openrouter/open_router_provider.dart';

/// Which provider the assistant talks to, and how.
///
/// Pass one to `AsystantAI.init(provider: ...)`. Tools, system prompts,
/// per-request context, attachments, the model picker, permissions and
/// cards work the same with every provider: they only use the
/// [AssistantTransport] that [createTransport] returns.
///
/// The class is sealed, so a host can `switch` over the providers it knows
/// and the compiler lists the ones it does not handle. Every variant must
/// implement [createTransport]; a variant without it does not compile.
sealed class AsystantProvider {
  const AsystantProvider();

  /// The provider's name as a person reads it, e.g. "Claude Code".
  String get name;

  /// A new transport configured as this provider says. The caller owns it
  /// and disposes it; `AsystantAI.init` does this for you.
  AssistantTransport createTransport();

  /// Checks that the provider can answer, without running an inference:
  /// a local program is installed and signed in, or a key is accepted.
  /// For a settings screen's "Test connection". See
  /// [AssistantTransport.verify].
  Future<Result<AsystantProviderStatus, AssistantFailure>> verify() =>
      _withTransport((transport) => transport.verify());

  /// The models and effort levels the provider offers, for a model picker.
  /// See [AssistantTransport.modelCatalog].
  Future<Result<AsystantModelCatalog, AssistantFailure>> modelCatalog() =>
      _withTransport((transport) => transport.modelCatalog());

  Future<T> _withTransport<T>(
    Future<T> Function(AssistantTransport transport) action,
  ) async {
    final transport = createTransport();
    try {
      return await action(transport);
    } finally {
      await transport.dispose();
    }
  }
}

import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/model/assistant_failure.dart';

/// A fresh short-lived JWT ticket issued by the host backend, never a provider key.
abstract class SessionSource {
  /// The current host login identity, or null when signed out.
  String? get identity;

  /// Emits on login, logout and identity changes.
  Stream<void> get changes;

  /// Obtains a fresh single-use ticket from the authenticated product backend.
  Future<Result<String, AssistantFailure>> issueTicket();
}

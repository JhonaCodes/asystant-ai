import 'package:result_controller/result_controller.dart';
import 'package:asystant_core/src/model/assistant_failure.dart';

/// A fresh short-lived JWT ticket issued by the host backend, never a provider key.
abstract class SessionSource {
  String? get identity;
  Stream<void> get changes;
  Future<Result<String, AssistantFailure>> issueTicket();
}

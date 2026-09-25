import 'package:result_controller/result_controller.dart';

import '../model/assistant_failure.dart';
import 'session_source.dart';

/// Bridges the host's existing authentication without adding a second login UI.
class CallbackSessionSource extends SessionSource {
  CallbackSessionSource({
    required String? Function() identity,
    required this.changes,
    required Future<Result<String, AssistantFailure>> Function() issueTicket,
  }) : _identity = identity,
       _issueTicket = issueTicket;
  final String? Function() _identity;
  final Future<Result<String, AssistantFailure>> Function() _issueTicket;
  @override
  final Stream<void> changes;
  @override
  String? get identity => _identity();
  @override
  Future<Result<String, AssistantFailure>> issueTicket() => _issueTicket();
}

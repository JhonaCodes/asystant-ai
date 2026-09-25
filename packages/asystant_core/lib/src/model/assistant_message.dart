import 'package:asystant_core/src/model/assistant_value.dart';
import 'package:asystant_core/src/model/tool_call.dart';

/// Roles accepted by the gateway; system instructions are registered separately.
enum MessageRole { user, assistant, tool }

/// One protocol message, including model-requested calls or a local tool result.
class AssistantMessage extends AssistantValue {
  const AssistantMessage({
    required this.role,
    required this.content,
    this.calls = const [],
    this.callId = '',
  });
  final MessageRole role;
  final String content;
  final List<ToolCall> calls;
  final String callId;
  AssistantMessage copyWith({
    MessageRole? role,
    String? content,
    List<ToolCall>? calls,
    String? callId,
  }) => AssistantMessage(
    role: role ?? this.role,
    content: content ?? this.content,
    calls: List.unmodifiable(calls ?? this.calls),
    callId: callId ?? this.callId,
  );
  factory AssistantMessage.fromJson(Map<String, Object?> json) =>
      AssistantMessage(
        role: MessageRole.values.byName(json['role'] as String),
        content: json['content'] as String,
        calls: List.unmodifiable(
          (json['calls'] as List<Object?>? ?? const []).map(
            (call) => ToolCall.fromJson(call as Map<String, Object?>),
          ),
        ),
        callId: json['call_id'] as String? ?? '',
      );
  @override
  Map<String, Object?> toJson() => {
    'role': role.name,
    'content': content,
    'calls': calls.map((c) => c.toJson()).toList(),
    'call_id': callId,
  };
}

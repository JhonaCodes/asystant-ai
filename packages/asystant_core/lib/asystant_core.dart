/// Typed local-tool contracts and a credential-safe gateway transport for Dart.
library;

export 'package:result_controller/result_controller.dart';

export 'src/model/assistant_card.dart';
export 'src/model/assistant_failure.dart';
export 'src/model/assistant_message.dart';
export 'src/model/system_prompt.dart';
export 'src/model/tool_call.dart';
export 'src/tool/asystant_tool.dart';
export 'src/tool/typed_asystant_tool.dart';
export 'src/tool/tool_arguments.dart';
export 'src/tool/tool_context.dart';
export 'src/tool/tool_definition.dart';
export 'src/tool/tool_field.dart';
export 'src/tool/tool_outcome.dart';
export 'src/tool/tool_registry.dart';
export 'src/transport/assistant_transport.dart';
export 'src/transport/gateway_transport.dart';
export 'src/transport/inference_event.dart';
export 'src/transport/session_source.dart';
export 'src/tool/presentation_tool.dart';
export 'src/transport/callback_session_source.dart';

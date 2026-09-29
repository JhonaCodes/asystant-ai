/// Typed local tools, protocol models and the model providers (OpenRouter,
/// Claude Code) for embedded assistants in Dart.
library;

export 'package:result_controller/result_controller.dart';

export 'package:asystant_core/src/knowledge/asystant_knowledge.dart';
export 'package:asystant_core/src/knowledge/knowledge_document.dart';
export 'package:asystant_core/src/knowledge/knowledge_hit.dart';
export 'package:asystant_core/src/knowledge/knowledge_query.dart';
export 'package:asystant_core/src/knowledge/knowledge_retriever.dart';
export 'package:asystant_core/src/model/assistant_card.dart';
export 'package:asystant_core/src/model/assistant_chart.dart';
export 'package:asystant_core/src/model/assistant_failure.dart';
export 'package:asystant_core/src/model/assistant_message.dart';
export 'package:asystant_core/src/model/asystant_attachment.dart';
export 'package:asystant_core/src/model/asystant_attachment_policy.dart';
export 'package:asystant_core/src/model/asystant_model_catalog.dart';
export 'package:asystant_core/src/model/asystant_prompt_policy.dart';
export 'package:asystant_core/src/model/asystant_provider_status.dart';
export 'package:asystant_core/src/model/chart_point.dart';
export 'package:asystant_core/src/model/system_prompt.dart';
export 'package:asystant_core/src/model/token_usage.dart';
export 'package:asystant_core/src/model/tool_call.dart';
export 'package:asystant_core/src/tool/asystant_tool.dart';
export 'package:asystant_core/src/tool/chart_presentation_tool.dart';
export 'package:asystant_core/src/tool/knowledge_search_tool.dart';
export 'package:asystant_core/src/tool/presentation_tool.dart';
export 'package:asystant_core/src/tool/tool_arguments.dart';
export 'package:asystant_core/src/tool/tool_context.dart';
export 'package:asystant_core/src/tool/tool_definition.dart';
export 'package:asystant_core/src/tool/tool_field.dart';
export 'package:asystant_core/src/tool/tool_outcome.dart';
export 'package:asystant_core/src/tool/tool_registry.dart';
export 'package:asystant_core/src/tool/typed_asystant_tool.dart';
export 'package:asystant_core/src/transport/assistant_transport.dart';
export 'package:asystant_core/src/transport/inference_event.dart';

// Providers: the sealed AsystantProvider with every variant, then one
// export per provider folder.
export 'package:asystant_core/src/providers/asystant_provider.dart';
export 'package:asystant_core/src/providers/claude_code/claude_code.dart';
export 'package:asystant_core/src/providers/openrouter/openrouter.dart';

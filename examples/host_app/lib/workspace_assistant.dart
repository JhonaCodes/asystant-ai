import 'package:asystant_ai/asystant_ai.dart';

import 'create_draft_tool.dart';

class WorkspaceAssistant extends AsystantAI {
  WorkspaceAssistant() : super(name: 'Asistente');
  @override
  List<AsystantTool> get tools => const [CreateDraftTool()];
  @override
  List<AsystantSystemPrompt> get systemPrompts => const [
    AsystantSystemPrompt(
      id: 'workspace',
      content: 'Help the user manage drafts. Use local tools and never claim that a draft was saved unless the tool succeeded.',
    ),
  ];
}

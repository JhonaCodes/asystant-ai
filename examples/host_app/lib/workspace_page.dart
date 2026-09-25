import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:asystant_ai/asystant_ai.dart';

import 'workspace_assistant.dart';
import 'workspace_service.dart';
import 'workspace_view_model.dart';

class WorkspacePage extends StatelessWidget {
  const WorkspacePage({super.key, required this.assistant});
  final WorkspaceAssistant assistant;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My workspace'),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: AsystantButton(
            assistant: assistant,
            strings: const AsystantStrings(spanish: false),
          ),
        ),
      ],
    ),
    endDrawer: Drawer(
      width: 460,
      child: AsystantChat(
        assistant: assistant,
        strings: const AsystantStrings(spanish: false),
        onClose: () => Navigator.of(context).pop(),
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Your drafts',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Local demo · real in-memory actions, simulated responses. Open the assistant to prepare a draft without leaving this section.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AsystantButton(
                  assistant: assistant,
                  strings: const AsystantStrings(spanish: false),
                ),
                Builder(
                  builder: (context) => OutlinedButton.icon(
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    icon: const Icon(Icons.view_sidebar_outlined),
                    label: const Text('Side panel'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => Scaffold(
                        body: AsystantChat(
                          assistant: assistant,
                          strings: const AsystantStrings(spanish: false),
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_full),
                  label: const Text('Full screen'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ReactiveViewModelBuilder<WorkspaceViewModel, List<String>>(
              viewmodel: WorkspaceService.drafts.notifier,
              build: (drafts, vm, keep) => Column(
                children: [
                  if (drafts.isEmpty)
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.edit_note_rounded),
                        title: Text('No drafts yet'),
                        subtitle: Text(
                          'The assistant can help you create your first draft.',
                        ),
                      ),
                    ),
                  for (final title in drafts)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.article_outlined),
                        title: Text(title),
                        subtitle: const Text('Created with a local tool'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

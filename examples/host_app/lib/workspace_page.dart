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
      title: const Text('Mi espacio'),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: AsystantButton(
            assistant: assistant,
            strings: const AsystantStrings(),
          ),
        ),
      ],
    ),
    endDrawer: Drawer(
      width: 460,
      child: AsystantChat(
        assistant: assistant,
        strings: const AsystantStrings(),
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
              'Tus borradores',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Demo local · acciones reales en memoria, respuestas simuladas. Abre el asistente para preparar un borrador sin salir de esta sección.',
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AsystantButton(
                  assistant: assistant,
                  strings: const AsystantStrings(),
                ),
                Builder(
                  builder: (context) => OutlinedButton.icon(
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    icon: const Icon(Icons.view_sidebar_outlined),
                    label: const Text('Panel lateral'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => Scaffold(
                        body: AsystantChat(
                          assistant: assistant,
                          strings: const AsystantStrings(),
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_full),
                  label: const Text('Pantalla completa'),
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
                        title: Text('Aún no tienes borradores'),
                        subtitle: Text(
                          'El asistente puede ayudarte a crear el primero.',
                        ),
                      ),
                    ),
                  for (final title in drafts)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.article_outlined),
                        title: Text(title),
                        subtitle: const Text('Creado con una tool local'),
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

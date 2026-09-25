import 'package:flutter/material.dart';

import 'workspace_assistant.dart';
import 'workspace_page.dart';

class HostApp extends StatelessWidget {
  const HostApp({super.key, required this.assistant});
  final WorkspaceAssistant assistant;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Asistente · Host demo',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff6366a5),
        brightness: Brightness.light,
      ),
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xffbcb1ef),
        brightness: Brightness.dark,
      ),
    ),
    home: WorkspacePage(assistant: assistant),
  );
}

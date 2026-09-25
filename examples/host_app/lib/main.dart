import 'package:flutter/material.dart';

import 'demo_transport.dart';
import 'host_app.dart';
import 'workspace_assistant.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final assistant = WorkspaceAssistant();
  await assistant.init(transport: DemoTransport());
  runApp(HostApp(assistant: assistant));
}

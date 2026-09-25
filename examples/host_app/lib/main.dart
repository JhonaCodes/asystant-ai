import 'package:flutter/material.dart';

import 'demo_transport.dart';
import 'host_app.dart';
import 'workspace_assistant.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final assistant = WorkspaceAssistant();
  assistant.init(transport: DemoTransport());
  runApp(HostApp(assistant: assistant));
}

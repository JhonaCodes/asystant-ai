import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:asystant_ai/src/widgets/chat_conversation.dart';

void main() {
  testWidgets(
    'host content augments completed cards without replacing consent',
    (tester) async {
      final vm = ChatViewModel();
      var callbacks = 0;
      var downloads = 0;
      const card = AssistantCard(title: 'Static QR', body: 'Ready to download');
      final state = ChatState(
        entries: const [ChatEntry(card: card)],
        pending: const PendingAction(
          call: ToolCall(
            id: '1',
            name: 'configure',
            arguments: ToolArguments('{}'),
          ),
          card: AssistantCard(title: 'Approve changes', kind: .permission),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatConversation(
              state: state,
              viewModel: vm,
              strings: const AsystantStrings(spanish: false),
              cardContentBuilder: (context, card) {
                callbacks++;
                return TextButton(
                  onPressed: () => downloads++,
                  child: const Text('Download image'),
                );
              },
            ),
          ),
        ),
      );
      expect(callbacks, 1);
      expect(downloads, 0);
      expect(find.text('Static QR'), findsOneWidget);
      expect(find.text('Approve changes'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      await tester.tap(find.text('Download image'));
      expect(downloads, 1);
      vm.dispose();
    },
  );
}

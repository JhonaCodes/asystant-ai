import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/widgets/chat_conversation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a finished turn folds its steps into one line under what it '
      'showed, that opens on a tap, while the turn in progress shows its '
      'steps from the start', (tester) async {
    final vm = ChatViewModel();
    addTearDown(vm.dispose);
    final state = ChatState(
      phase: ChatPhase.executing,
      steps: const [
        AssistantStep(
          id: 'turn-2/call-1',
          title: 'Reading the schedule',
          phase: StepPhase.running,
        ),
      ],
      entries: [
        // As the view model records a turn: a tool's card on its own entry,
        // then the final answer carrying what the turn did.
        const ChatEntry(card: AssistantCard(title: 'Negocios')),
        ChatEntry(
          activity: [
            for (final (index, title) in const [
              'Listed the businesses',
              'Read AulaMás',
              'Read Jhonacode School',
            ].indexed)
              AssistantStep(
                id: 'turn-1/call-$index',
                title: title,
                phase: StepPhase.completed,
              ),
          ],
          message: const AssistantMessage(
            role: MessageRole.assistant,
            content: 'There are two businesses.',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatConversation(
            name: 'Keel AI',
            onStartNew: () {},
            state: state,
            viewModel: vm,
            strings: AsystantStrings.spanishLabels,
          ),
        ),
      ),
    );

    final line = find.text('3 pasos · completado');
    expect(line, findsOneWidget);
    expect(
      tester.getTopLeft(line).dy,
      greaterThan(tester.getTopLeft(find.text('Negocios')).dy),
    );
    expect(
      tester.getTopLeft(line).dy,
      greaterThan(
        tester
            .getTopLeft(
              find.text('There are two businesses.', findRichText: true),
            )
            .dy,
      ),
    );
    expect(find.text('Listed the businesses'), findsNothing);
    expect(find.text('Reading the schedule'), findsOneWidget);

    await tester.tap(line);
    await tester.pump();

    expect(find.text('Listed the businesses'), findsOneWidget);
    expect(find.text('Read Jhonacode School'), findsOneWidget);
  });
}

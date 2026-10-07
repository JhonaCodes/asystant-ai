import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chat_flow_test.dart' show FakeTransport;

class _Assistant extends AsystantAI {
  _Assistant() : super(name: 'Studio');

  @override
  List<AsystantTool> get tools => const [];
}

/// Adds what the provider reported to the default wording.
class _DetailedStrings extends AsystantStrings {
  const _DetailedStrings() : super(spanish: false);

  @override
  String failureMessage(AssistantFailure failure) =>
      '${this.failure(failure.code)} (${failure.detail})';
}

Future<_Assistant> _connected(WidgetTester tester) async {
  final assistant = _Assistant()
    ..init(
      transport: FakeTransport(),
      models: [AsystantModelOption.fallback('test')],
    );
  await tester.runAsync(assistant.ensureInitialized);
  addTearDown(assistant.dispose);
  return assistant;
}

Future<void> _pumpChat(WidgetTester tester, AsystantChat chat) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: chat)));
  await tester.pump();
}

void main() {
  testWidgets('a host card calls back only on an explicit press, and a null '
      'action is drawn disabled', (tester) async {
    final assistant = await _connected(tester);
    var approvals = 0;
    await _pumpChat(
      tester,
      AsystantChat(
        assistant: assistant,
        strings: const AsystantStrings(spanish: false),
        hostCards: [
          AsystantHostCard(
            card: const AssistantCard(
              title: 'Publish the draft',
              body: 'Three pages change.',
              kind: .permission,
            ),
            actions: [
              AsystantCardAction(
                label: 'Publish',
                onPressed: () => approvals++,
                isPrimary: true,
              ),
              const AsystantCardAction(label: 'Keep editing', onPressed: null),
            ],
          ),
        ],
      ),
    );

    expect(find.text('Publish the draft'), findsOneWidget);
    expect(approvals, 0);
    await tester.tap(find.text('Publish'));
    expect(approvals, 1);
    final keepEditing = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Keep editing'),
    );
    expect(keepEditing.onPressed, isNull);
  });

  testWidgets('host header actions sit in the header row, before the '
      'conversation actions', (tester) async {
    final assistant = await _connected(tester);
    var homes = 0;
    await _pumpChat(
      tester,
      AsystantChat(
        assistant: assistant,
        strings: const AsystantStrings(spanish: false),
        headerActions: [
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => homes++,
          ),
        ],
      ),
    );

    final home = find.byTooltip('Home');
    expect(home, findsOneWidget);
    expect(
      tester.getCenter(home).dy,
      moreOrLessEquals(tester.getCenter(find.text('Studio')).dy, epsilon: 12),
    );
    expect(
      tester.getCenter(home).dx,
      lessThan(tester.getCenter(find.byTooltip('New conversation')).dx),
    );
    await tester.tap(home);
    expect(homes, 1);
  });

  testWidgets('the conversation actions can live in a menu behind a host '
      'icon, each with its own icon', (tester) async {
    final assistant = await _connected(tester);
    await _pumpChat(
      tester,
      AsystantChat(
        assistant: assistant,
        strings: const AsystantStrings(spanish: false),
        conversationActionsStyle: AsystantConversationActionsStyle.menu,
        conversationMenuIcon: const Icon(Icons.tune_rounded),
      ),
    );

    expect(find.byTooltip('New conversation'), findsNothing);
    expect(find.text('New conversation'), findsNothing);

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Conversations'), findsOneWidget);
    expect(find.text('New conversation'), findsOneWidget);
    expect(find.text('Delete conversation'), findsOneWidget);
  });

  testWidgets('the header shows the host content', (tester) async {
    final assistant = await _connected(tester);
    await _pumpChat(
      tester,
      AsystantChat(
        assistant: assistant,
        strings: const AsystantStrings(spanish: false),
        headerContent: const Text('Chapter 3 · draft'),
      ),
    );

    expect(find.text('Chapter 3 · draft'), findsOneWidget);
  });

  testWidgets('without conversation management the chat offers no list, new '
      'or delete', (tester) async {
    final assistant = await _connected(tester);
    await _pumpChat(
      tester,
      AsystantChat(
        assistant: assistant,
        strings: const AsystantStrings(spanish: false),
        managesConversations: false,
      ),
    );

    expect(find.byTooltip('Conversations'), findsNothing);
    expect(find.byTooltip('New conversation'), findsNothing);
    expect(find.byTooltip('Delete conversation'), findsNothing);
  });

  testWidgets('a failure reads as the strings word it, detail included', (
    tester,
  ) async {
    final assistant = await _connected(tester);
    final chat = assistant.conversation.notifier;
    chat.updateState(
      chat.state.copyWith(
        phase: .error,
        failure: const AssistantFailure(
          .unavailable,
          detail: 'claude is not installed',
        ),
      ),
    );
    await _pumpChat(
      tester,
      AsystantChat(assistant: assistant, strings: const _DetailedStrings()),
    );

    expect(find.textContaining('(claude is not installed)'), findsOneWidget);
  });
}

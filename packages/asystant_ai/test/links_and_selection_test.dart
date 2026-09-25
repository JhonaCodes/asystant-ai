import 'dart:ui' show PointerDeviceKind;

import 'package:asystant_ai/asystant_ai.dart';
import 'package:asystant_ai/src/widgets/asystant_image_placeholder.dart';
import 'package:asystant_ai/src/widgets/asystant_markdown_text.dart';
import 'package:asystant_ai/src/widgets/chat_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class LinkAssistant extends AsystantAI {
  @override
  List<AsystantTool> get tools => const [];
}

class RecordingLauncher extends UrlLauncherPlatform {
  final List<String> urls = [];
  bool succeeds = true;

  @override
  Null get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    expect(options.mode, PreferredLaunchMode.externalApplication);
    return succeeds;
  }
}

Finder paragraphContaining(String text) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText().contains(text),
);

Offset characterPosition(
  WidgetTester tester,
  String paragraphText,
  String segment, {
  bool end = false,
}) {
  final paragraph = tester.renderObject<RenderParagraph>(
    paragraphContaining(paragraphText).first,
  );
  final plain = paragraph.text.toPlainText();
  final start = plain.indexOf(segment);
  expect(start, greaterThanOrEqualTo(0));
  final offset = end ? start + segment.length - 1 : start;
  final box = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: offset, extentOffset: offset + 1),
      )
      .first;
  return paragraph.localToGlobal(
    Offset(end ? box.right + 1 : box.left + 1, (box.top + box.bottom) / 2),
  );
}

Future<void> selectText(WidgetTester tester, Offset start, Offset end) async {
  await tester.pumpAndSettle();
  final gesture = await tester.startGesture(
    start,
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump();
  await gesture.moveTo(start + const Offset(20, 0));
  await tester.pump();
  await gesture.moveTo(end);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late UrlLauncherPlatform originalLauncher;
  late RecordingLauncher launcher;
  var clipboard = '';

  setUp(() {
    originalLauncher = UrlLauncherPlatform.instance;
    launcher = RecordingLauncher();
    UrlLauncherPlatform.instance = launcher;
    clipboard = '';
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            clipboard = (call.arguments as Map)['text'] as String;
            return null;
          case 'Clipboard.getData':
            return {'text': clipboard};
          case 'Clipboard.hasStrings':
            return {'value': clipboard.isNotEmpty};
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalLauncher;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  test(
    'only explicit credential-free HTTP(S) destinations can reach handlers',
    () async {
      final opened = <Uri>[];
      final opener = AsystantLinkOpener(
        onOpenLink: (uri) {
          opened.add(uri);
          return true;
        },
      );
      for (final destination in [
        null,
        '',
        'javascript:alert(1)',
        'data:text/html,test',
        'file:///private/file',
        'mailto:owner@example.test',
        '//example.test/path',
        'https://user:password@example.test',
        'https://example.test/\nsecret',
        'https://',
      ]) {
        expect(await opener.open(destination), isFalse);
      }
      expect(opened, isEmpty);
      expect(await opener.open('https://example.test/help?q=queue'), isTrue);
      expect(opened.single.host, 'example.test');
      expect(launcher.urls, isEmpty);
      expect(
        await AsystantLinkOpener(
          onOpenLink: (_) => throw StateError('Host navigation unavailable'),
        ).open('https://example.test/help'),
        isFalse,
      );
    },
  );

  testWidgets('named Markdown and bare links open only when tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatTimeline(
            revision: 1,
            padding: EdgeInsets.all(20),
            children: [
              AsystantMarkdownText(
                text: 'Read [the guide](https://example.test/guide).\n\nhttps://example.test/status',
              ),
            ],
          ),
        ),
      ),
    );
    expect(launcher.urls, isEmpty);
    await tester.tapAt(characterPosition(tester, 'Read the guide.', 'guide'));
    await tester.pump();
    expect(launcher.urls, ['https://example.test/guide']);
    await tester.tapAt(
      characterPosition(tester, 'https://example.test/status', 'example'),
    );
    await tester.pump();
    expect(launcher.urls.last, 'https://example.test/status');
    expect(tester.takeException(), isNull);
  });

  testWidgets('AsystantChat forwards the typed host navigation callback', (
    tester,
  ) async {
    final assistant = LinkAssistant();
    final opened = <Uri>[];
    assistant.conversation.notifier.updateState(
      const ChatState(
        entries: [
          ChatEntry(
            message: AssistantMessage(
              role: .assistant,
              content: '[Open settings](https://app.example.test/settings)',
            ),
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsystantChat(
            assistant: assistant,
            onOpenLink: (uri) {
              opened.add(uri);
              return true;
            },
          ),
        ),
      ),
    );
    await tester.tapAt(characterPosition(tester, 'Open settings', 'settings'));
    await tester.pump();
    expect(opened.single.path, '/settings');
    expect(launcher.urls, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    assistant.dispose();
  });

  testWidgets(
    'unsafe destinations and launch failures show localized feedback',
    (tester) async {
      launcher.succeeds = false;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatTimeline(
              revision: 1,
              padding: EdgeInsets.all(20),
              children: [
                AsystantMarkdownText(
                  text: '[Open guide](https://example.test/guide)',
                ),
                AsystantMarkdownText(text: '[Unsafe link](javascript:alert)'),
              ],
            ),
          ),
        ),
      );
      await tester.tapAt(characterPosition(tester, 'Open guide', 'guide'));
      await tester.pump();
      expect(
        find.text('Could not open this link. You can copy it and try again.'),
        findsOneWidget,
      );
      await tester.tapAt(characterPosition(tester, 'Unsafe link', 'Unsafe'));
      await tester.pump();
      expect(launcher.urls, ['https://example.test/guide']);
      expect(
        find.text('Could not open this link. You can copy it and try again.'),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('image markup never creates a network or file image', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AsystantMarkdownText(
            text: '![A private chart](https://example.test/tracking.png)\n\n![Local image](file:///private/image.png)',
          ),
        ),
      ),
    );
    expect(find.byType(AsystantImagePlaceholder), findsNWidgets(2));
    expect(find.byType(Image), findsNothing);
    expect(find.text('A private chart'), findsOneWidget);
    expect(launcher.urls, isEmpty);
  });

  testWidgets(
    'mouse selection copies across Markdown and genUI without opening links',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatTimeline(
              revision: 1,
              padding: EdgeInsets.all(20),
              children: [
                AsystantMarkdownText(
                  text: 'Read [the guide](https://example.test/guide) and keep this text.',
                ),
                GenUiCard(
                  card: AssistantCard(
                    title: 'Summary',
                    body: 'Twenty appointments completed.',
                  ),
                  strings: AsystantStrings(spanish: false),
                ),
              ],
            ),
          ),
        ),
      );
      await selectText(
        tester,
        characterPosition(tester, 'Read the guide', 'the guide'),
        characterPosition(
          tester,
          'Twenty appointments completed.',
          'completed.',
          end: true,
        ),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(clipboard, contains('the guide'));
      expect(clipboard, contains('Summary'));
      expect(clipboard, contains('Twenty appointments completed.'));
      expect(launcher.urls, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'mobile long press copies genUI using the native selection toolbar',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatTimeline(
              revision: 1,
              padding: EdgeInsets.all(20),
              children: [
                GenUiCard(
                  card: AssistantCard(
                    title: 'Summary',
                    body: 'Appointments completed.',
                  ),
                  strings: AsystantStrings(spanish: false),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.longPressAt(
        characterPosition(tester, 'Appointments completed.', 'Appointments'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsOneWidget);
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(clipboard, contains('Appointments'));
      expect(launcher.urls, isEmpty);
    },
  );

  testWidgets('new content does not scroll away from an active selection', (
    tester,
  ) async {
    Widget timeline(int revision) => MaterialApp(
      home: Scaffold(
        body: ChatTimeline(
          revision: revision,
          forceFollow: true,
          padding: const EdgeInsets.all(20),
          children: List.generate(
            80 + revision,
            (index) => Text('Message number $index'),
          ),
        ),
      ),
    );
    await tester.pumpWidget(timeline(0));
    await selectText(
      tester,
      characterPosition(tester, 'Message number 0', 'Message'),
      characterPosition(tester, 'Message number 0', 'number 0', end: true),
    );
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(scroll.pixels, 0);
    await tester.pumpWidget(timeline(1));
    await tester.pump();
    expect(scroll.pixels, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}

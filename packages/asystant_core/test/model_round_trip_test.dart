import 'dart:typed_data';

import 'package:asystant_core/asystant_core.dart';
import 'package:test/test.dart';

void main() {
  group('AssistantMessage round-trip', () {
    test('attachments survive toJson/fromJson instead of disappearing', () {
      final file = AsystantAttachment.fromBytes(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'leaf.jpg',
      );
      final message = AssistantMessage(
        role: MessageRole.user,
        content: 'Look at it',
        attachments: [file],
      );

      final restored = AssistantMessage.fromJson(message.toJson());

      expect(restored.attachments, hasLength(1));
      expect(restored.attachments.single.id, file.id);
      expect(restored.attachments.single.filename, file.filename);
      expect(restored.attachments.single.mimeType, file.mimeType);
    });

    test('a message with no attachments still round-trips to an empty list', () {
      const message = AssistantMessage(
        role: MessageRole.assistant,
        content: 'Hola',
      );

      final restored = AssistantMessage.fromJson(message.toJson());

      expect(restored.attachments, isEmpty);
    });
  });

  group('ToolOutcome round-trip', () {
    test('images survive toJson/fromJson instead of disappearing', () {
      final frame = AsystantAttachment.fromBytes(
        bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
        filename: 'frame.png',
      );
      final outcome = ToolOutcome(modelContent: 'Rendered', images: [frame]);

      final restored = ToolOutcome.fromJson(outcome.toJson());

      expect(restored.images, hasLength(1));
      expect(restored.images.single.id, frame.id);
      expect(restored.images.single.filename, frame.filename);
      expect(restored.images.single.mimeType, frame.mimeType);
    });
  });

  // `RegExp` does not override `==` (it is `Object`'s identity by contract),
  // so comparing two policies by RegExp identity is wrong even though the
  // Dart VM happens to canonicalize same-pattern RegExp instances today —
  // these tests fix the equality contract to the documented fields instead
  // of relying on that VM-specific, undocumented optimization.
  group('AsystantAttachmentPolicy equality with RegExp fields', () {
    test(
      'two policies built with equivalent RegExp patterns compare equal',
      () {
        final a = AsystantAttachmentPolicy(
          blockedFilenamePatterns: [RegExp(r'^\.')],
        );
        final b = AsystantAttachmentPolicy(
          blockedFilenamePatterns: [RegExp(r'^\.')],
        );

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      },
    );

    test('a different pattern breaks equality', () {
      final a = AsystantAttachmentPolicy(
        blockedFilenamePatterns: [RegExp(r'^\.')],
      );
      final b = AsystantAttachmentPolicy(
        blockedFilenamePatterns: [RegExp(r'^_')],
      );

      expect(a, isNot(equals(b)));
    });

    test('a different case-sensitivity flag breaks equality', () {
      final a = AsystantAttachmentPolicy(
        blockedFilenamePatterns: [RegExp(r'secret', caseSensitive: true)],
      );
      final b = AsystantAttachmentPolicy(
        blockedFilenamePatterns: [RegExp(r'secret', caseSensitive: false)],
      );

      expect(a, isNot(equals(b)));
    });
  });
}

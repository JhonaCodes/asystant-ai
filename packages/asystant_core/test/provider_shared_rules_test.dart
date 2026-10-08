import 'package:asystant_core/asystant_core.dart';
import 'package:asystant_core/src/providers/attachment_text.dart';
import 'package:asystant_core/src/providers/provider_failure.dart';
import 'package:asystant_core/src/providers/sdk_limits.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderFailure.codeOfStatus', () {
    test('maps the statuses every provider shares', () {
      expect(ProviderFailure.codeOfStatus(401), FailureCode.authentication);
      expect(ProviderFailure.codeOfStatus(403), FailureCode.authentication);
      expect(ProviderFailure.codeOfStatus(413), FailureCode.contextFull);
      expect(ProviderFailure.codeOfStatus(429), FailureCode.rateLimited);
    });

    test('leaves every other status to the provider', () {
      for (final status in [null, 200, 400, 402, 408, 500, '401']) {
        expect(ProviderFailure.codeOfStatus(status), isNull, reason: '$status');
      }
    });
  });

  group('ProviderFailure.mentionsContextFull', () {
    test('recognizes each shared phrase, in any case', () {
      for (final detail in [
        'Exceeds the CONTEXT LENGTH of the model',
        'request is larger than the context window',
        'Too many tokens in the request',
      ]) {
        expect(ProviderFailure.mentionsContextFull(detail), isTrue);
      }
    });

    test('adds the provider phrases only where they are given', () {
      const detail = 'prompt is too long: 210000 tokens';

      expect(ProviderFailure.mentionsContextFull(detail), isFalse);
      expect(
        ProviderFailure.mentionsContextFull(
          detail,
          extraPhrases: const ['prompt is too long'],
        ),
        isTrue,
      );
    });

    test('rejects an unrelated detail', () {
      expect(ProviderFailure.mentionsContextFull('invalid model'), isFalse);
    });
  });

  group('AttachmentText.cut', () {
    test('keeps text at the limit whole', () {
      final cut = AttachmentText.cut('abcde', limit: 5);

      expect(cut, (text: 'abcde', truncated: false));
    });

    test('cuts text over the limit to its first characters', () {
      final cut = AttachmentText.cut('abcdef', limit: 5);

      expect(cut, (text: 'abcde', truncated: true));
    });

    test('applies the SDK limit as is', () {
      final over = 'x' * (AsystantSdkLimits.maxAttachmentText + 1);

      final cut = AttachmentText.cut(
        over,
        limit: AsystantSdkLimits.maxAttachmentText,
      );

      expect(cut.text.length, AsystantSdkLimits.maxAttachmentText);
      expect(cut.truncated, isTrue);
    });
  });
}

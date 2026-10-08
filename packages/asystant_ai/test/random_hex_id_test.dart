import 'package:asystant_ai/src/service/chat_secret_vault.dart';
import 'package:asystant_ai/src/service/random_hex_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every byte becomes two lowercase hex characters', () {
    for (var i = 0; i < 200; i++) {
      expect(randomHexId(16), matches(RegExp(r'^[0-9a-f]{32}$')));
    }
    expect(randomHexId(1), hasLength(2));
  });

  test('the vault reference carries a 16-byte hex id', () {
    final reference = ChatSecretVault().reserve('conversation', 'value');

    expect(reference, matches(RegExp(r'^\[secret:[0-9a-f]{32}\]$')));
  });
}

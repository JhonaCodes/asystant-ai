import 'dart:convert';

import 'package:asystant_core/asystant_core.dart';

/// [BusinessDocumentStore] over the host's string key/value store, the
/// same callbacks `AsystantJsonConversationStore` uses (shared preferences,
/// a local database, ...). Documents are public API documentation, so they
/// do not need the device vault.
class JsonBusinessDocumentStore implements BusinessDocumentStore {
  const JsonBusinessDocumentStore({
    required this.readValue,
    required this.writeValue,
    required this.removeValue,
    this.keyPrefix = 'asystant_ai.business_documents.v1',
  });

  final Future<String?> Function(String key) readValue;
  final Future<bool> Function(String key, String value) writeValue;
  final Future<bool> Function(String key) removeValue;
  final String keyPrefix;

  String _key(String accountId, String businessId) =>
      '$keyPrefix.${base64Url.encode(utf8.encode(accountId))}.$businessId';

  @override
  Future<Result<BusinessDocument?, BusinessFailure>> read(
    String accountId,
    String businessId,
  ) async {
    final raw = await readValue(_key(accountId, businessId));
    if (raw == null) return Ok(null);
    try {
      return switch (jsonDecode(raw)) {
        final Map<String, Object?> json => Ok(BusinessDocument.fromJson(json)),
        _ => Err(_unreadable),
      };
    } on FormatException {
      return Err(_unreadable);
    }
  }

  @override
  Future<Result<void, BusinessFailure>> write(
    String accountId,
    BusinessDocument document,
  ) async =>
      await writeValue(
        _key(accountId, document.businessId),
        jsonEncode(document.toJson()),
      )
      ? Ok(null)
      : Err(
          const BusinessFailure(
            .storage,
            message: 'The business document could not be saved.',
          ),
        );

  @override
  Future<Result<void, BusinessFailure>> delete(
    String accountId,
    String businessId,
  ) async => await removeValue(_key(accountId, businessId))
      ? Ok(null)
      : Err(
          const BusinessFailure(
            .storage,
            message: 'The business document could not be deleted.',
          ),
        );

  static const BusinessFailure _unreadable = BusinessFailure(
    .storage,
    message: 'The saved business document is unreadable.',
  );
}

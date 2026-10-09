import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/business/business_document.dart';
import 'package:asystant_core/src/business/business_document_store.dart';
import 'package:asystant_core/src/business/business_failure.dart';

/// [BusinessDocumentStore] kept in memory while the app runs; the default
/// when the host does not persist documents.
class InMemoryBusinessDocumentStore implements BusinessDocumentStore {
  InMemoryBusinessDocumentStore();

  final Map<String, BusinessDocument> _documents = {};

  @override
  Future<Result<BusinessDocument?, BusinessFailure>> read(
    String accountId,
    String businessId,
  ) async => Ok(_documents['$accountId/$businessId']);

  @override
  Future<Result<void, BusinessFailure>> write(
    String accountId,
    BusinessDocument document,
  ) async {
    _documents['$accountId/${document.businessId}'] = document;
    return Ok(null);
  }

  @override
  Future<Result<void, BusinessFailure>> delete(
    String accountId,
    String businessId,
  ) async {
    _documents.remove('$accountId/$businessId');
    return Ok(null);
  }
}

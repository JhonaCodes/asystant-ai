import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/business/business_document.dart';
import 'package:asystant_core/src/business/business_failure.dart';

/// Where the host keeps the source document of each business of an
/// account: one per business, replaced when a new one is saved. Documents
/// are public API documentation, never credentials.
abstract interface class BusinessDocumentStore {
  /// The document of [businessId], or null when none was saved.
  Future<Result<BusinessDocument?, BusinessFailure>> read(
    String accountId,
    String businessId,
  );

  /// Creates or replaces the document of `document.businessId`.
  Future<Result<void, BusinessFailure>> write(
    String accountId,
    BusinessDocument document,
  );

  Future<Result<void, BusinessFailure>> delete(
    String accountId,
    String businessId,
  );
}

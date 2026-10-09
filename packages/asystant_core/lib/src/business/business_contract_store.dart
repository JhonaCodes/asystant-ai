import 'package:result_controller/result_controller.dart';

import 'package:asystant_core/src/business/business_contract.dart';
import 'package:asystant_core/src/business/business_failure.dart';

/// Where the host keeps the public contracts of one account: a local file,
/// a database or a server that syncs them across devices. Contracts carry
/// no secrets, so they may leave the device.
abstract interface class BusinessContractStore {
  /// Every contract registered for [accountId].
  Future<Result<List<BusinessContract>, BusinessFailure>> list(
    String accountId,
  );

  /// Creates or replaces, by id, [contract] for [accountId], and answers the
  /// contract as stored. An `Err` leaves the stored one unchanged.
  Future<Result<BusinessContract, BusinessFailure>> save(
    String accountId,
    BusinessContract contract,
  );
}

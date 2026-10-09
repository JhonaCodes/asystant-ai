/// Why a business contract check, sign-in or operation failed.
enum BusinessFailureCode {
  /// The contract, or one of its parts, is not valid.
  invalidContract,

  /// The arguments of an operation, or the values entered to sign in, do
  /// not match what is declared.
  invalidInput,

  /// The business, environment, profile or operation is not configured.
  notConfigured,

  /// There is no saved session for that environment and profile.
  noSession,

  /// The saved session expired and could not be renewed; sign in again.
  sessionExpired,

  /// A declared private header has no value saved on the device.
  missingPrivateHeader,

  /// The API answered with an error status.
  rejected,

  /// The API answered something the contract does not expect.
  unexpectedResponse,

  /// The API could not be reached or did not answer in time.
  unreachable,

  /// The person dismissed a sign-in form.
  canceled,

  /// The device storage failed.
  storage,
}

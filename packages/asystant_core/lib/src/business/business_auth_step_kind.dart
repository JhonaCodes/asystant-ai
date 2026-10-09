/// What one step of a [BusinessAuthFlow] does.
///
/// - [request] asks the API to send a one-time code (usually by email).
/// - [verify] sends that code back.
/// - [password] signs in with an email and a password.
/// - [totp] sends the authenticator code of a second factor.
/// - [refresh] renews a saved session; it is not part of signing in and
///   runs only when an operation is rejected with 401.
enum BusinessAuthStepKind { request, verify, password, totp, refresh }

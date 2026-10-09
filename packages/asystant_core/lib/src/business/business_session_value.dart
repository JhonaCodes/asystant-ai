/// A value of a saved session besides the credential itself, kept by a
/// [BusinessCredentialStore] to renew it: the refresh token and the
/// server's session id.
enum BusinessSessionValue { refreshToken, sessionId }

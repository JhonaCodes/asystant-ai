/// How a saved credential is sent with every operation: as
/// `Authorization: Bearer <credential>`, or as the value of an API key
/// header ([BusinessAuthFlow.apiKeyHeader]).
enum BusinessAuthScheme { bearer, apiKey }

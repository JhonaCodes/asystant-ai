/// The kind of value a person types for a [BusinessAuthInput], which decides
/// how the sign-in form shows it: [email] and [text] in clear, [password],
/// [code] and [totp] hidden and never pre-filled.
enum BusinessAuthInputKind { email, password, code, totp, text }

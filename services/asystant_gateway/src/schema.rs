diesel::table! { sessions (token_hash) { token_hash -> Text, identity -> Text, sid -> Text, issuer -> Text, tenant -> Text, subject -> Text, expires_at -> Timestamptz, } }
diesel::table! { consumed_tickets (id) { id -> Text, expires_at -> Timestamptz, } }
diesel::table! { revoked_sessions (id) { id -> Text, } }
diesel::table! { registrations (id) { id -> Text, identity -> Text, manifest -> Jsonb, expires_at -> Timestamptz, } }
diesel::table! { accounts (id) { id -> Text, held_micros -> BigInt, } }
diesel::table! { requests (id) { id -> Text, identity -> Text, tenant_account -> Text, user_account -> Text, reservation -> BigInt, charged -> Nullable<BigInt>, status -> Text, created_at -> Timestamptz, } }

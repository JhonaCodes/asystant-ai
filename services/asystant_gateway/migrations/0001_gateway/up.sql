CREATE TABLE sessions (token_hash TEXT PRIMARY KEY, identity TEXT NOT NULL, sid TEXT NOT NULL, issuer TEXT NOT NULL, tenant TEXT NOT NULL, subject TEXT NOT NULL, expires_at TIMESTAMPTZ NOT NULL);
CREATE TABLE consumed_tickets (id TEXT PRIMARY KEY, expires_at TIMESTAMPTZ NOT NULL);
CREATE TABLE revoked_sessions (id TEXT PRIMARY KEY);
CREATE TABLE registrations (id TEXT PRIMARY KEY, identity TEXT NOT NULL, manifest JSONB NOT NULL, expires_at TIMESTAMPTZ NOT NULL);
CREATE INDEX registrations_identity ON registrations(identity);
CREATE TABLE accounts (id TEXT PRIMARY KEY, held_micros BIGINT NOT NULL CHECK (held_micros >= 0));
CREATE TABLE requests (id TEXT PRIMARY KEY, identity TEXT NOT NULL, tenant_account TEXT NOT NULL, user_account TEXT NOT NULL, reservation BIGINT NOT NULL CHECK (reservation >= 0), charged BIGINT, status TEXT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE INDEX requests_pending ON requests(status,created_at);

# Deploying the gateway

Deploy `services/asystant_gateway`. Flutter applications install the SDK; their business tools remain inside each app. No public hosted endpoint is bundled with this repository.

## Prerequisites

- A dedicated persistent PostgreSQL database with backups and restricted network access.
- A valid provider key and an independent random signing secret of at least 32 bytes per product.
- Model IDs, conservative price ceilings and daily customer/user budgets configured by the operator.
- A public HTTPS ingress with shared rate limits, request/header timeouts, SSE buffering disabled and an upstream timeout above 120 seconds. Restrict direct access to the origin server.
- A product backend endpoint that validates the current login and issues a signed ticket as documented in the [API guide](../services/asystant_gateway/README.md).

## Build and configure

```sh
docker build -t asystant-gateway:local services/asystant_gateway
cp services/asystant_gateway/.env.example services/asystant_gateway/.env
```

Replace the placeholders on the deployment server. Never commit this file. The Docker build context excludes credentials. Use a secret manager for production.

`DATABASE_URL` must be reachable from the container: `127.0.0.1` refers to the container itself. Configure database TLS according to your database provider. Price ceilings in the example are policy placeholders, not current tariff quotations.

## Single-server deployment

With external PostgreSQL and a host HTTPS proxy:

```sh
docker compose -f services/asystant_gateway/compose.yaml up -d --build
curl --fail http://127.0.0.1:8787/health/ready
```

Compose runs migrations before the API and publishes only to host loopback. It does not create or delete a database. Compose parses the outer quotes around JSON in `.env.example`; plain `docker run --env-file` preserves those quotes, so generate an env file without them when using that command.

## Multiple replicas

Build one image per revision. Run exactly one migration job with `--migrate-only` and `DATABASE_URL`, using a role with DDL privileges. Only after it succeeds should replicas start with `--serve`, preferably using a separate runtime role limited to the migrated tables. Do not run concurrent migration jobs. Without arguments, the binary migrates and serves for development convenience.

The image runs as UID 10001. Compose additionally uses a read-only root filesystem, drops Linux capabilities and enables no-new-privileges. Set CPU, memory and connection limits appropriate to your deployment.

The gateway enforces process-local admission and 32 simultaneous inferences. Behind a proxy, the peer guard sees the proxy address and conservatively groups its clients. Configure ingress capacity and shared client/tenant limits accordingly; do not allow clients to forge trusted forwarding headers. See the [security policy](../SECURITY.md) for exact boundaries.

## Health and public documentation

- `GET /health/live`: process liveness.
- `GET /health/ready`: database connection and migrated-schema readiness.
- `GET /openapi.yaml`: versioned API specification, with no secrets or tenant configuration.

Only route business traffic to ready replicas. Health does not validate a provider key. Public business routes still require authentication. Enable HSTS at the HTTPS ingress rather than on a local HTTP-only listener.

Before stopping an instance, remove it from the load balancer and allow active inference/accounting work to finish. A forced shutdown can leave pending reservations; the HTTP shutdown timeout alone cannot guarantee background accounting completion.

## Verify

```sh
python3 scripts/check_container.py
```

After building the image, this opt-in test starts disposable Docker resources, checks non-root/read-only execution, migration and readiness before/after database shutdown, and removes only its own resources. It makes no provider calls.

Before production, verify login, renewal, revocation, model denial, tenant isolation, approval/cancellation and budget exhaustion against the actual product integration. Run the opt-in `scripts/live_openrouter.py` with a dedicated test database and a valid provider key. The development credential returned HTTP 401; a successful external inference has not yet been established.

Monitor uncertain reservations and reconcile against provider records. No automated reconciliation or retention worker is included. Never release reservations solely because they are old or reset budgets by recreating the database.

For rollback, retain the previous image and verify its compatibility with the current schema. Do not delete volumes or apply destructive down migrations as a routine rollback.

The hosting destination, domain and production PostgreSQL are still operator-provided. These instructions prepare a deployment; they do not claim that one is already running.

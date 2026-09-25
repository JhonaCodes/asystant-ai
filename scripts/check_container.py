"""Opt-in Docker deployment check using disposable resources and no provider calls."""

import json
import pathlib
import secrets
import subprocess
import time
import uuid


def run(*args, check=True):
    return subprocess.run(args, check=check, capture_output=True, text=True)


def wait_for(probe, description):
    for _ in range(40):
        if probe():
            return
        time.sleep(0.5)
    raise RuntimeError(f"Timed out waiting for {description}")


def main():
    suffix = uuid.uuid4().hex[:12]
    network, db, api = [f"asystant-check-{name}-{suffix}" for name in ("net", "db", "api")]
    password = secrets.token_hex(24)
    database_url = f"postgres://asystant:{password}@{db}:5432/asystant"
    env = {}
    example = pathlib.Path(__file__).resolve().parents[1] / "services/asystant_gateway/.env.example"
    for line in example.read_text().splitlines():
        if line and not line.startswith("#"):
            key, value = line.split("=", 1)
            env[key] = value.strip("'")
    products = json.loads(env["ASYSTANT_PRODUCTS"])
    products[0]["secret"] = secrets.token_hex(32)
    env.update(DATABASE_URL=database_url, ASYSTANT_BIND="0.0.0.0:8787",
               ASYSTANT_PRODUCTS=json.dumps(products), OPENROUTER_API_KEY="unused-test-key")
    env_args = [arg for key, value in env.items() for arg in ("-e", f"{key}={value}")]

    def status(path):
        return run("docker", "exec", api, "curl", "--max-time", "4", "-s", "-o", "/dev/null",
                   "-w", "%{http_code}", f"http://127.0.0.1:8787/health/{path}", check=False).stdout

    try:
        run("docker", "network", "create", network)
        run("docker", "run", "-d", "--name", db, "--network", network,
            "-e", "POSTGRES_USER=asystant", "-e", f"POSTGRES_PASSWORD={password}",
            "--tmpfs", "/var/lib/postgresql", "postgres:18-bookworm")
        wait_for(lambda: run("docker", "exec", db, "pg_isready", "-U", "asystant",
                             check=False).returncode == 0, "PostgreSQL")
        run("docker", "run", "-d", "--name", api, "--network", network, "--read-only",
            "--cap-drop=ALL", "--security-opt=no-new-privileges:true",
            *env_args, "asystant-gateway:local", "--serve")
        wait_for(lambda: status("live") == "200", "liveness")
        assert status("ready") == "503", "An unmigrated database must not be ready"
        run("docker", "run", "--rm", "--network", network, "--read-only",
            "-e", f"DATABASE_URL={database_url}", "asystant-gateway:local", "--migrate-only")
        wait_for(lambda: status("ready") == "200", "readiness after migration")
        user = run("docker", "exec", api, "id", "-u").stdout.strip()
        assert user == "10001", "Gateway must run as the unprivileged image user"
        run("docker", "stop", "--time", "5", db)
        wait_for(lambda: status("ready") == "503", "readiness after database shutdown")
        assert status("live") == "200", "Database outage must not fail liveness"
        print("PASS: non-root read-only runtime, migration job, readiness and database outage")
    finally:
        # Remove only the disposable resources created by this invocation.
        for name in (api, db):
            run("docker", "rm", "-f", "-v", name, check=False)
        run("docker", "network", "rm", network, check=False)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        # Command arguments include disposable credentials; do not print them.
        raise SystemExit(f"Docker check failed with exit code {error.returncode}") from None

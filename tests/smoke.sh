#!/bin/sh
# Real Docker E2E test. Uses a unique project and destroys ONLY its own volumes.
set -eu
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEPLOY_DIR=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
. "$DEPLOY_DIR/scripts/common.sh"
COMPOSE_PROJECT_NAME="shop-smoke-$(date +%s)-$$"
FRONTEND_PORT=0
BACKEND_PORT=0
DATABASE_PORT=0
DEBUG_PORT=0
export COMPOSE_PROJECT_NAME FRONTEND_PORT BACKEND_PORT DATABASE_PORT DEBUG_PORT
command -v curl >/dev/null 2>&1 || fail 'curl is required for the smoke test.'
preflight
[ -z "$(compose ps -aq)" ] || fail 'Test project unexpectedly already exists.'
cleanup() {
    compose down --volumes --remove-orphans >/dev/null 2>&1 || :
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

sh "$DEPLOY_DIR/deploy.sh"
address=$(compose port frontend 80)
base="http://127.0.0.1:${address##*:}"
curl -fsS "$base/" >/dev/null
curl -fsS "$base/api/products/v2?role=guest" | grep -q '"items"'
compose exec -T db psql -v ON_ERROR_STOP=1 -U postgres -d shopping_db <<'SQL'
CREATE TABLE deployment_persistence_probe (id integer PRIMARY KEY);
INSERT INTO deployment_persistence_probe VALUES (1);
SQL
compose exec -T backend sh -c 'printf "persistent-upload" > /app/uploads/deployment-probe.txt'
[ "$(curl -fsS "$base/uploads/deployment-probe.txt")" = persistent-upload ]
# Remove containers, retain volumes, and repeat the complete deployment entrypoint.
compose down
sh "$DEPLOY_DIR/deploy.sh"
[ "$(compose exec -T db psql -At -U postgres -d shopping_db -c 'select count(*) from deployment_persistence_probe')" = 1 ]
[ "$(compose exec -T db psql -At -U postgres -d shopping_db -c "select count(*) from users where account = 'demo'")" = 3 ]
address=$(compose port frontend 80)
base="http://127.0.0.1:${address##*:}"
[ "$(curl -fsS "$base/uploads/deployment-probe.txt")" = persistent-upload ]
curl -fsS "$base/api/products/v2?role=guest" | grep -q '"items"'
printf '%s\n' 'PASS: empty-environment deployment, API access, repeat deployment and persistent data.'

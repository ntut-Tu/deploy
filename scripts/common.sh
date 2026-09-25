# Shared by deploy.sh and image_deploy.sh; DEPLOY_DIR is set by the entrypoint.
fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

compose() {
    docker compose --project-directory "$DEPLOY_DIR" -f "$DEPLOY_DIR/docker-compose.yml" "$@"
}

preflight() {
    command -v docker >/dev/null 2>&1 || fail 'Docker CLI is required.'
    docker info >/dev/null 2>&1 || fail 'Docker Engine is unavailable to this user.'
    docker compose version >/dev/null 2>&1 || fail 'Docker Compose v2 is required.'
    compose up --help | grep -q -- '--wait-timeout' || fail 'Update Docker Compose v2: --wait-timeout support is required.'
    compose config --quiet || fail 'Invalid Docker Compose configuration.'
}

start_services() {
    if ! compose up -d --no-build --wait --wait-timeout 300; then
        compose ps >&2 || :
        compose logs --no-color --tail 80 >&2 || :
        fail 'Services did not become healthy. See logs above; existing data is retained.'
    fi
    address=$(compose port frontend 80) || fail 'Cannot determine frontend port.'
    printf '%s\n' "Deployment ready: http://localhost:${address##*:}"
}

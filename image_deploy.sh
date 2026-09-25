#!/bin/sh
set -eu

DEPLOY_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$DEPLOY_DIR/scripts/common.sh"

preflight
for archive in frontend-image.tar postgres.tar backend-image.tar; do
    [ -f "$DEPLOY_DIR/images/$archive" ] || fail "Missing image archive: images/$archive"
done
for archive in frontend-image.tar postgres.tar backend-image.tar; do
    docker load -i "$DEPLOY_DIR/images/$archive" || fail "Could not load $archive"
done
for image in frontend-image backend-image postgres:16-alpine; do
    docker image inspect "$image" >/dev/null 2>&1 || fail "Archive did not provide required image: $image"
done
start_services

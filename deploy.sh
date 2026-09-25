#!/bin/sh
set -eu

DEPLOY_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$DEPLOY_DIR/scripts/common.sh"

preflight
SERVER_DIR="$DEPLOY_DIR/../cloth_shop_server"
[ -f "$SERVER_DIR/mvnw" ] || fail "Missing sibling repository: cloth_shop_server"
[ -f "$DEPLOY_DIR/../cloth_shop_web/package-lock.json" ] || fail "Missing sibling repository: cloth_shop_web"

printf '%s\n' 'Building and testing backend (Maven provisions its own temporary databases)...'
if ! (cd "$SERVER_DIR" && sh ./mvnw -B -ntp clean package); then
    fail 'Backend build or tests failed; deployment stopped.'
fi
printf '%s\n' 'Building backend and frontend images...'
compose build || fail 'Image build failed; deployment stopped.'
start_services

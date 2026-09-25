#!/bin/sh
# Unit tests: fake external commands, real entrypoints and failure propagation.
set -eu
TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT HUP INT TERM
mkdir -p "$WORK/workspace with spaces/deploy/scripts" "$WORK/workspace with spaces/deploy/images" \
    "$WORK/workspace with spaces/cloth_shop_server" "$WORK/workspace with spaces/cloth_shop_web" "$WORK/bin"
FIXTURE="$WORK/workspace with spaces/deploy"
cp "$TEST_DIR/../deploy.sh" "$TEST_DIR/../image_deploy.sh" "$TEST_DIR/../docker-compose.yml" "$FIXTURE/"
cp "$TEST_DIR/../scripts/common.sh" "$FIXTURE/scripts/"
touch "$FIXTURE/../cloth_shop_web/package-lock.json"
cat > "$FIXTURE/../cloth_shop_server/mvnw" <<'MOCK'
#!/bin/sh
printf 'maven %s\n' "$*" >> "$CALL_LOG"
[ "$FAIL_STAGE" != maven ]
MOCK
cat > "$WORK/bin/docker" <<'MOCK'
#!/bin/sh
printf 'docker %s\n' "$*" >> "$CALL_LOG"
case "$1" in
  info) [ "$FAIL_STAGE" != info ]; exit $? ;;
  load) [ "$FAIL_STAGE" != load ]; exit $? ;;
  image) [ "$FAIL_STAGE" != image ]; exit $? ;;
  compose) shift ;;
  *) exit 99 ;;
esac
if [ "$1" = version ]; then [ "$FAIL_STAGE" != compose ]; exit $?; fi
while [ "$1" = --project-directory ] || [ "$1" = -f ]; do shift 2; done
if [ "$1" = up ] && [ "$2" = --help ]; then
  [ "$FAIL_STAGE" = old-compose ] || printf '%s\n' '--wait-timeout'
  exit 0
fi
if [ "$1" = port ]; then printf '%s\n' '0.0.0.0:18080'; fi
[ "$FAIL_STAGE" != "$1" ]
MOCK
chmod +x "$WORK/bin/docker"
PATH="$WORK/bin:$PATH"
CALL_LOG="$WORK/calls"
export PATH CALL_LOG FAIL_STAGE

run_case() {
    expected=$1
    FAIL_STAGE=$2
    entry=$3
    : > "$CALL_LOG"
    if (cd / && sh "$FIXTURE/$entry") > "$WORK/output" 2>&1; then actual=success; else actual=failure; fi
    if [ "$expected" != "$actual" ]; then
        cat "$WORK/output" >&2
        printf 'FAIL: %s %s: expected %s, got %s\n' "$entry" "$FAIL_STAGE" "$expected" "$actual" >&2
        exit 1
    fi
    if [ "$expected" = failure ] && grep -q 'Deployment ready:' "$WORK/output"; then
        printf '%s\n' 'FAIL: failure incorrectly reported success' >&2; exit 1
    fi
    if [ "$expected" = success ]; then
        grep -q 'Deployment ready: http://localhost:18080' "$WORK/output"
    fi
    printf 'PASS: %s (%s)\n' "$entry" "$FAIL_STAGE"
}
assert_not_called() {
    if grep -q -- "$1" "$CALL_LOG"; then cat "$CALL_LOG" >&2; exit 1; fi
}
run_case success none deploy.sh
sed -n '/^maven /p; /yml build$/p; /yml up -d/p' "$CALL_LOG" > "$WORK/sequence"
[ "$(wc -l < "$WORK/sequence")" -eq 3 ]
sed -n '1p' "$WORK/sequence" | grep -q 'maven -B -ntp clean package'
sed -n '2p' "$WORK/sequence" | grep -q 'yml build$'
sed -n '3p' "$WORK/sequence" | grep -q 'up -d --no-build --wait --wait-timeout 300'
for stage in info compose old-compose config; do
    run_case failure "$stage" deploy.sh
    assert_not_called '^maven '
    assert_not_called 'yml build$'
done
run_case failure maven deploy.sh
assert_not_called 'yml build$'
assert_not_called 'up -d'
run_case failure build deploy.sh
assert_not_called 'up -d'
run_case failure up deploy.sh
grep -q 'yml logs --no-color --tail 80' "$CALL_LOG"
assert_not_called 'down'
run_case failure none image_deploy.sh
assert_not_called 'docker load'
for archive in frontend-image.tar backend-image.tar postgres.tar; do touch "$FIXTURE/images/$archive"; done
run_case failure load image_deploy.sh
[ "$(grep -c 'docker load' "$CALL_LOG")" -eq 1 ]
assert_not_called 'up -d'
run_case failure image image_deploy.sh
assert_not_called 'up -d'
run_case success none image_deploy.sh
[ "$(grep -c 'docker load' "$CALL_LOG")" -eq 3 ]
assert_not_called '^maven '
assert_not_called 'yml build$'
printf '%s\n' 'All 12 deployment unit tests passed.'

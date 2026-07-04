#!/usr/bin/env bash
set -euo pipefail

IMAGE="$1"
EXPECTED_VERSION="${2#v}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURE="$REPO_ROOT/test/fixtures/smoke-config.yaml"

PASS=0
FAIL=0

check() {
  local name="$1"
  local result="$2"
  if [ "$result" = "0" ]; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name"
    FAIL=$((FAIL + 1))
  fi
}

version_out="$(docker run --rm --entrypoint crowdsec-firewall-bouncer "$IMAGE" -version 2>&1 || true)"
if printf '%s\n' "$version_out" | grep -qF "$EXPECTED_VERSION"; then
  check "version reports $EXPECTED_VERSION" 0
else
  check "version reports $EXPECTED_VERSION" 1
fi

if docker run --rm \
  -e API_URL=http://smoke-sentinel.invalid:8080 \
  -e API_KEY=smoke-key-123 \
  -v "$FIXTURE:/config/crowdsec-firewall-bouncer.yaml:ro" \
  --entrypoint /bin/sh "$IMAGE" \
  -c 'mkdir -p /tmp/crowdsec && envsubst < /config/crowdsec-firewall-bouncer.yaml > /tmp/crowdsec/crowdsec-firewall-bouncer.yaml && grep -F smoke-key-123 /tmp/crowdsec/crowdsec-firewall-bouncer.yaml && grep -F smoke-sentinel.invalid /tmp/crowdsec/crowdsec-firewall-bouncer.yaml' >/dev/null 2>&1; then
  check "envsubst render substitutes API_URL and API_KEY" 0
else
  check "envsubst render substitutes API_URL and API_KEY" 1
fi

entrypoint_out="$(timeout 30 docker run --rm \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -e API_URL=http://smoke-sentinel.invalid:8080 \
  -e API_KEY=smoke-key-123 \
  -v "$FIXTURE:/config/crowdsec-firewall-bouncer.yaml:ro" \
  "$IMAGE" 2>&1 || true)"
if printf '%s\n' "$entrypoint_out" | grep -qF smoke-sentinel.invalid; then
  check "real entrypoint loads rendered config" 0
else
  check "real entrypoint loads rendered config" 1
fi

if missing_out="$(docker run --rm "$IMAGE" 2>&1)"; then
  missing_rc=0
else
  missing_rc=$?
fi
if [ "$missing_rc" -ne 0 ] && printf '%s\n' "$missing_out" | grep -qF "config not found"; then
  check "missing config rejected" 0
else
  check "missing config rejected" 1
fi

echo ""
echo "Results: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]

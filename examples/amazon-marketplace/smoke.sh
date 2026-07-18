#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$(dirname "$0")"
./build.sh >/dev/null
DB=$(mktemp -d /tmp/poche-amazon-XXXX)
PORT=17802
POCHE_DB="$DB" "$ROOT/poche" init > /tmp/poche-amazon-init.json
export POCHE_TOKEN
POCHE_TOKEN=$(sed -n 's/.*"admin_token":"\([^"]*\)".*/\1/p' /tmp/poche-amazon-init.json)
export POCHE_URL="http://127.0.0.1:$PORT"
POCHE_DB="$DB" "$ROOT/poche" serve "$PORT" >/tmp/poche-amazon.log 2>&1 &
PID=$!
trap 'kill "$PID" 2>/dev/null || true; rm -rf "$DB"' EXIT
sleep .4
./amazon-marketplace bootstrap >/dev/null
SELLER=$(./amazon-marketplace seller acme)
SELLER_ID=$(printf '%s' "$SELLER" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
CUSTOMER=$(./amazon-marketplace customer ada@example.test Ada)
CUSTOMER_ID=$(printf '%s' "$CUSTOMER" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
PRODUCT=$(./amazon-marketplace product "$SELLER_ID" SKU-1 Keyboard 9900 5 true)
PRODUCT_ID=$(printf '%s' "$PRODUCT" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
./amazon-marketplace order "$CUSTOMER_ID" "$PRODUCT_ID" 2 | grep -q '"total_cents":19800'
./amazon-marketplace catalog 10 | grep -q 'SKU-1'
# Remaining stock is 3; a qty 4 order must fail.
if ./amazon-marketplace order "$CUSTOMER_ID" "$PRODUCT_ID" 4 >/dev/null 2>&1; then
  echo "oversell accepted" >&2
  exit 1
fi
echo '{"ok":true,"app":"amazon-marketplace"}'

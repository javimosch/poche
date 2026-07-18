#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$(dirname "$0")"
./build.sh >/dev/null
DB=$(mktemp -d /tmp/poche-cars-XXXX)
PORT=17803
POCHE_DB="$DB" "$ROOT/poche" init > /tmp/poche-cars-init.json
export POCHE_TOKEN
POCHE_TOKEN=$(sed -n 's/.*"admin_token":"\([^"]*\)".*/\1/p' /tmp/poche-cars-init.json)
export POCHE_URL="http://127.0.0.1:$PORT"
POCHE_DB="$DB" "$ROOT/poche" serve "$PORT" >/tmp/poche-cars.log 2>&1 &
PID=$!
trap 'kill "$PID" 2>/dev/null || true; rm -rf "$DB"' EXIT
sleep .4
./car-renting bootstrap >/dev/null
CUSTOMER=$(./car-renting customer ada@example.test Ada)
CUSTOMER_ID=$(printf '%s' "$CUSTOMER" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
CAR=$(./car-renting car AA-001-ZZ Compact lyon 5 4500 true)
CAR_ID=$(printf '%s' "$CAR" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
./car-renting car AA-002-ZZ Premium lyon 5 9000 true >/dev/null
BOOKING=$(./car-renting reserve "$CUSTOMER_ID" "$CAR_ID" 10 13)
BOOKING_ID=$(printf '%s' "$BOOKING" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
printf '%s' "$BOOKING" | grep -q '"total_cents":13500'
if ./car-renting reserve "$CUSTOMER_ID" "$CAR_ID" 12 14 >/dev/null 2>&1; then
  echo "overlapping booking accepted" >&2
  exit 1
fi
./car-renting available lyon 1 1 | grep -q '"total":2'
./car-renting cancel "$BOOKING_ID" >/dev/null
./car-renting reserve "$CUSTOMER_ID" "$CAR_ID" 12 14 >/dev/null
echo '{"ok":true,"app":"car-renting"}'

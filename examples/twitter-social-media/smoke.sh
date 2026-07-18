#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$(dirname "$0")"
./build.sh >/dev/null
DB=$(mktemp -d /tmp/poche-twitter-XXXX)
PORT=17801
POCHE_DB="$DB" "$ROOT/poche" init > /tmp/poche-twitter-init.json
export POCHE_TOKEN
POCHE_TOKEN=$(sed -n 's/.*"admin_token":"\([^"]*\)".*/\1/p' /tmp/poche-twitter-init.json)
export POCHE_URL="http://127.0.0.1:$PORT"
POCHE_DB="$DB" "$ROOT/poche" serve "$PORT" >/tmp/poche-twitter.log 2>&1 &
PID=$!
trap 'kill "$PID" 2>/dev/null || true; rm -rf "$DB"' EXIT
sleep .4
./twitter-social-media bootstrap >/dev/null
./twitter-social-media profile ada "Ada Lovelace" "computing" >/dev/null
POST=$(./twitter-social-media post ada 'hello "agents"')
POST_ID=$(printf '%s' "$POST" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
./twitter-social-media profile bob "Bob" "builder" >/dev/null
./twitter-social-media follow bob ada >/dev/null
./twitter-social-media like bob "$POST_ID" >/dev/null
./twitter-social-media timeline ada 10 | grep -q 'hello'
echo '{"ok":true,"app":"twitter-social-media"}'

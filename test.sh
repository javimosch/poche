#!/usr/bin/env bash
# Smoke test: init → schema → data → rbac → expose → serve → REST → watch
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
DB=$(mktemp -d /tmp/poche-test-XXXX)
export POCHE_DB="$DB"
export FEEDBACK_RELAY=off
./poche init >/dev/null
./poche schema define articles title:string views:int published:bool >/dev/null
./poche data create articles title=Hi views=1 published=true >/dev/null
./poche role add editor >/dev/null
./poche grant editor articles read,create >/dev/null
TOK=$(./poche user add bob editor | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
./poche schema expose articles read,create >/dev/null
./poche serve 17701 >/tmp/poche-test-serve.log 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null || true; rm -rf "$DB"' EXIT
sleep 0.4
curl -sf http://127.0.0.1:17701/health >/dev/null
curl -sf -H "Authorization: Bearer $TOK" http://127.0.0.1:17701/api/articles | grep -q '"ok":true'
curl -sf -H "Authorization: Bearer $TOK" 'http://127.0.0.1:17701/watch?coll=articles&since=0&timeout=1' | grep -q '"ok":true'
./poche guide >/dev/null
./poche help-json >/dev/null
echo "OK smoke ($DB)"

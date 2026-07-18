#!/usr/bin/env bash
# Smoke: core lifecycle + dogfood constraints/mutations/query.
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
DB=$(mktemp -d /tmp/poche-test-XXXX)
export POCHE_DB="$DB"
export FEEDBACK_RELAY=off
INIT=$(./poche init)
ADMIN=$(printf '%s' "$INIT" | sed -n 's/.*"admin_token":"\([^"]*\)".*/\1/p')
./poche schema define authors name:string!required!unique >/dev/null
AUTHOR=$(./poche data create authors name=ada)
AUTHOR_ID=$(printf '%s' "$AUTHOR" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p')
if ./poche data create authors name=ada >/dev/null 2>&1; then
  echo "unique constraint failed" >&2
  exit 1
fi
./poche schema define articles author_id:string!ref=authors title:string! views:int!min=0 published:bool created_at:int!now >/dev/null
./poche data create articles author_id="$AUTHOR_ID" title=Hi views=1 published=true >/dev/null
./poche data create articles author_id="$AUTHOR_ID" title=Second views=2 published=true >/dev/null
./poche schema index articles views --range | grep -q '"kind":"range"'
./poche schema define products stock:int!min=0 >/dev/null
PRODUCT=$(./poche data create products stock=5)
PRODUCT_ID=$(printf '%s' "$PRODUCT" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p')
echo blob >/tmp/poche-test-blob
FILE=$(./poche file put blob.txt /tmp/poche-test-blob)
FILE_ID=$(printf '%s' "$FILE" | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p')
test -f "$POCHE_DB/_blobs/$FILE_ID"
./poche file delete "$FILE_ID" >/dev/null
test ! -e "$POCHE_DB/_blobs/$FILE_ID"
./poche role add editor >/dev/null
./poche grant editor articles read,create >/dev/null
TOK=$(./poche user add bob editor | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
./poche schema expose articles read,create >/dev/null
./poche schema expose products read,update >/dev/null
./poche serve 17701 >/tmp/poche-test-serve.log 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null || true; rm -rf "$DB"' EXIT
sleep 0.4
curl -sf http://127.0.0.1:17701/health >/dev/null
curl -sf -H "Authorization: Bearer $TOK" 'http://127.0.0.1:17701/api/articles?limit=1&offset=1&sort=views&order=desc' | grep -q '"total":2'
curl -sf -H "Authorization: Bearer $TOK" 'http://127.0.0.1:17701/api/articles/count?where=views%3E=1' | grep -q '"count":2'
CREATE_STATUS=$(curl -s -o /tmp/poche-test-create.json -w '%{http_code}' -X POST \
  -H "Authorization: Bearer $TOK" -H 'content-type: application/json' \
  -d "{\"author_id\":\"$AUTHOR_ID\",\"title\":\"HTTP\",\"views\":3,\"published\":true}" \
  http://127.0.0.1:17701/api/articles)
test "$CREATE_STATUS" = 201
CORS=$(curl -si -X OPTIONS -H 'Origin: https://example.test' \
  -H 'Access-Control-Request-Method: POST' http://127.0.0.1:17701/api/articles)
printf '%s' "$CORS" | grep -q '204 No Content'
printf '%s' "$CORS" | grep -q 'Access-Control-Allow-Methods'
curl -sf -H "Authorization: Bearer $TOK" 'http://127.0.0.1:17701/watch?coll=articles&since=0&timeout=1' | grep -q '"ok":true'
curl -sf -X POST -H "Authorization: Bearer $ADMIN" -H 'content-type: application/json' \
  -d '{"name":"admin_bootstrap","fields":"key:string!required!unique"}' \
  http://127.0.0.1:17701/admin/schema | grep -q '"collection":"admin_bootstrap"'
curl -sf -X POST -H "Authorization: Bearer $ADMIN" -H 'content-type: application/json' \
  -d '{"field":"stock","delta":-2}' \
  "http://127.0.0.1:17701/api/products/$PRODUCT_ID/increment" | grep -q '"stock":3'
curl -sf -X POST -H "Authorization: Bearer $ADMIN" -H 'content-type: application/json' \
  -d '{"field":"stock","expect":3,"value":2}' \
  "http://127.0.0.1:17701/api/products/$PRODUCT_ID/compare-swap" | grep -q '"stock":2'
./poche guide >/dev/null
./poche help-json >/dev/null
echo "OK smoke ($DB)"

#!/usr/bin/env bash
# Live scenario: bookstore | bank | carrent
# Usage: ./scripts/scenario.sh bookstore [n=2000]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SCENARIO="${1:?usage: scenario.sh bookstore|bank|carrent [n]}"
N="${2:-2000}"
PORT="${POCHE_PORT:-$((19000 + RANDOM % 500))}"
DB=$(mktemp -d /tmp/poche-$SCENARIO-XXXX)
export POCHE_DB="$DB" FEEDBACK_RELAY=off
[[ -x ./poche ]] || ./build.sh
BIN=./poche
log(){ printf '%s\n' "$*" >&2; }

TOK=$($BIN init | sed -n 's/.*"admin_token":"\([^"]*\)".*/\1/p')

case "$SCENARIO" in
  bookstore)
    $BIN schema define books title:string author:string price:int stock:int isbn:string >/dev/null
    $BIN schema define orders customer:string book_isbn:string qty:int total:int status:string >/dev/null
    $BIN schema index books isbn >/dev/null
    $BIN schema index books author >/dev/null
    $BIN schema index orders status >/dev/null
    $BIN schema expose books read,create,update >/dev/null
    $BIN schema expose orders read,create,update >/dev/null
    COLL=books; WHERE="author=Auth-1"; POST_COLL=books
    POST_BODY='{"title":"Live","author":"Zed","price":12,"stock":3,"isbn":"ISBN-LIVE"}'
    BAD_BODY='{"title":1,"author":"x","price":1,"stock":1,"isbn":"x"}'
    ;;
  bank)
    $BIN schema define accounts owner:string currency:string balance:int status:string >/dev/null
    $BIN schema define txns account:string kind:string amount:int memo:string >/dev/null
    $BIN schema index accounts owner >/dev/null
    $BIN schema index accounts status >/dev/null
    $BIN schema index txns account >/dev/null
    $BIN schema expose accounts read,create,update >/dev/null
    $BIN schema expose txns read,create >/dev/null
    COLL=accounts; WHERE="status=active"; POST_COLL=accounts
    POST_BODY='{"owner":"live","currency":"EUR","balance":42,"status":"active"}'
    BAD_BODY='{"owner":1,"currency":"EUR","balance":1,"status":"active"}'
    ;;
  carrent|car|car-renting)
    SCENARIO=carrent
    $BIN schema define cars plate:string model:string daily_rate:int available:bool city:string >/dev/null
    $BIN schema define rentals car_plate:string customer:string days:int total:int status:string >/dev/null
    $BIN schema index cars city >/dev/null
    $BIN schema index cars available >/dev/null
    $BIN schema index rentals status >/dev/null
    $BIN schema expose cars read,create,update >/dev/null
    $BIN schema expose rentals read,create,update >/dev/null
    COLL=cars; WHERE="city=paris"; POST_COLL=cars
    POST_BODY='{"plate":"LIVE-1","model":"Test","daily_rate":55,"available":true,"city":"paris"}'
    BAD_BODY='{"plate":1,"model":"x","daily_rate":1,"available":true,"city":"paris"}'
    ;;
  *) log "unknown scenario"; exit 80 ;;
esac

$BIN serve "$PORT" >/tmp/poche-$SCENARIO-serve.log 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null || true; rm -rf "$DB"' EXIT
for i in $(seq 1 30); do curl -sf "http://127.0.0.1:$PORT/health" >/dev/null && break; sleep 0.1; done

AUTH=(-H "Authorization: Bearer $TOK" -H "content-type: application/json")
T0=$(date +%s%3N)
i=0
while (( i < N )); do
  case "$SCENARIO" in
    bookstore)
      curl -sf "${AUTH[@]}" -d "{\"title\":\"Book-$i\",\"author\":\"Auth-$((i%50))\",\"price\":$((10+i%40)),\"stock\":$((i%20)),\"isbn\":\"ISBN-$i\"}" \
        "http://127.0.0.1:$PORT/api/books" >/dev/null
      if (( i % 10 == 0 )); then
        curl -sf "${AUTH[@]}" -d "{\"customer\":\"c$((i%100))\",\"book_isbn\":\"ISBN-$i\",\"qty\":1,\"total\":$((10+i%40)),\"status\":\"open\"}" \
          "http://127.0.0.1:$PORT/api/orders" >/dev/null
      fi
      ;;
    bank)
      curl -sf "${AUTH[@]}" -d "{\"owner\":\"u$((i%200))\",\"currency\":\"EUR\",\"balance\":$((1000+i)),\"status\":\"active\"}" \
        "http://127.0.0.1:$PORT/api/accounts" >/dev/null
      curl -sf "${AUTH[@]}" -d "{\"account\":\"u$((i%200))\",\"kind\":\"credit\",\"amount\":$((i%500)),\"memo\":\"dep-$i\"}" \
        "http://127.0.0.1:$PORT/api/txns" >/dev/null
      ;;
    carrent)
      avail=true; (( i % 4 == 0 )) && avail=false
      city=lyon; (( i % 3 == 0 )) && city=paris; (( i % 3 == 1 )) && city=marseille
      curl -sf "${AUTH[@]}" -d "{\"plate\":\"AA-$i-ZZ\",\"model\":\"M$((i%20))\",\"daily_rate\":$((30+i%70)),\"available\":$avail,\"city\":\"$city\"}" \
        "http://127.0.0.1:$PORT/api/cars" >/dev/null
      if [[ $avail == false ]]; then
        curl -sf "${AUTH[@]}" -d "{\"car_plate\":\"AA-$i-ZZ\",\"customer\":\"cust-$((i%80))\",\"days\":$((1+i%7)),\"total\":$((100+i%200)),\"status\":\"active\"}" \
          "http://127.0.0.1:$PORT/api/rentals" >/dev/null
      fi
      ;;
  esac
  i=$((i+1))
done
T1=$(date +%s%3N)
INSERT_MS=$((T1-T0))

L=$(curl -sf -H "Authorization: Bearer $TOK" "http://127.0.0.1:$PORT/api/$COLL?where=$WHERE&limit=20")
W=$(curl -sf -H "Authorization: Bearer $TOK" "http://127.0.0.1:$PORT/watch?coll=$COLL&since=0&timeout=1")
curl -sf -X POST "${AUTH[@]}" -d "$POST_BODY" "http://127.0.0.1:$PORT/api/$POST_COLL" >/dev/null
SEQ=$(printf '%s' "$W" | sed -n 's/.*"seq":\([0-9]*\).*/\1/p' | head -1)
W2=$(curl -sf -H "Authorization: Bearer $TOK" "http://127.0.0.1:$PORT/watch?coll=$COLL&since=${SEQ:-0}&timeout=2")
BAD=$(curl -s -o /tmp/poche-bad-$SCENARIO.json -w '%{http_code}' -X POST "${AUTH[@]}" -d "$BAD_BODY" "http://127.0.0.1:$PORT/api/$POST_COLL" || true)

# file round-trip
echo "cover-$SCENARIO" > /tmp/poche-blob.txt
FID=$($BIN file put "cover.txt" /tmp/poche-blob.txt | sed -n 's/.*"_id":"\([^"]*\)".*/\1/p')
FHTTP=$(curl -sf -H "Authorization: Bearer $TOK" "http://127.0.0.1:$PORT/files/$FID")

DPS=$(( N * 1000 / (INSERT_MS + 1) ))
printf '{"ok":true,"scenario":"%s","n":%s,"insert_ms":%s,"docs_per_s":%s,"list_count":%s,"watch_resync":%s,"watch2_has_changes_or_seq":%s,"bad_status":%s,"file_http":"%s","port":%s,"db":"%s"}\n' \
  "$SCENARIO" "$N" "$INSERT_MS" "$DPS" \
  "$(printf '%s' "$L" | sed -n 's/.*"count":\([0-9]*\).*/\1/p' | head -1)" \
  "$(printf '%s' "$W" | sed -n 's/.*"resync":\([0-9]*\).*/\1/p' | head -1)" \
  "$(printf '%s' "$W2" | grep -cE 'changes|seq' || true)" \
  "$BAD" \
  "$(printf '%s' "$FHTTP" | tr -d '\n')" \
  "$PORT" "$DB"

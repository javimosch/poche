#!/usr/bin/env bash
# Ordered listing and keyset paging.
#
# poche's fallback sorts with an INSERTION SORT that re-parses the sort field
# inside its inner loop — O(n^2) json parses to return a handful of rows.
# Measured over HTTP on 4000 documents, same server, same query:
#
#     sort=n with a --range index     5-6 ms      (mode range-ordered)
#     the scan+sort fallback          1190-1354 ms (mode scan+sort)
#
# grange answers the ordered shape from the sorted projection of a --range
# index and hands back a cursor. This asserts the three things that can break:
#
#   1. the fast path is actually TAKEN when the sort field is range-indexed,
#      and the fallback still works when it is not
#   2. both paths return the SAME rows in the same order — a faster answer that
#      differs is not an answer
#   3. paging by cursor visits every row exactly once
set -u
cd "$(dirname "$0")/.."
BIN=./poche
PORT="${PORT:-17811}"
N=400
fails=0
check() { if [ "$2" = "1" ]; then echo "  ok   $1"; else echo "  FAIL $1"; fails=$((fails + 1)); fi; }

DB=$(mktemp -d /tmp/poche-paging-XXXX)
export POCHE_DB="$DB"
export POCHE_NO_NUDGE=1
INIT=$($BIN init)
ADMIN=$(printf '%s' "$INIT" | sed -n 's/.*"admin_token":"\([^"]*\)".*/\1/p')

# `ranked` carries a range index; `plain` does not, so it exercises the fallback
$BIN schema define ev title:string ranked:int plain:int >/dev/null
$BIN schema index ev ranked --range >/dev/null
i=0
while [ "$i" -lt "$N" ]; do
  # values interleaved so sort order is not insertion order, with deliberate
  # TIES: a page boundary inside a run of equal values is where keyset paging
  # goes wrong if the order is not total
  $BIN data create ev title="t$i" ranked=$(( (i * 7) % 100 )) plain=$(( (i * 7) % 100 )) >/dev/null
  i=$((i + 1))
done
$BIN schema expose ev read >/dev/null

fuser -k "$PORT/tcp" 2>/dev/null; sleep 0.3
POCHE_DB="$DB" $BIN serve "$PORT" >/tmp/poche-paging.log 2>&1 &
SRV=$!
for _ in $(seq 1 80); do sleep 0.1; curl -sf "http://localhost:$PORT/health" >/dev/null 2>&1 && break; done
A="Authorization: Bearer $ADMIN"
U="http://localhost:$PORT/api/ev"

mode() { curl -s "$1" -H "$A" | python3 -c 'import json,sys; print(json.load(sys.stdin)["data"]["mode"])'; }
rows() { curl -s "$1" -H "$A" | python3 -c '
import json,sys
d = json.load(sys.stdin)["data"]
print(" ".join("%s:%s" % (i["id"], i["doc"].get(sys.argv[1])) for i in d["items"]))' "$2"; }

# 1. the right path is chosen
M=$(mode "$U?limit=5&sort=ranked&order=desc")
[ "$M" = "range-ordered" ] && check "range-indexed sort uses the index" 1 || check "range-indexed sort uses the index (mode=$M)" 0
M=$(mode "$U?limit=5&sort=plain&order=desc")
[ "$M" = "scan+sort" ] && check "un-indexed sort still falls back" 1 || check "un-indexed sort still falls back (mode=$M)" 0
M=$(mode "$U?limit=5&sort=ranked&order=desc&offset=2")
[ "$M" = "scan+sort" ] && check "offset falls back (keyset cannot skip N rows)" 1 || check "offset falls back (mode=$M)" 0

# 2. same answer both ways. `plain` holds the same values as `ranked`, so the
#    fallback sorted by `plain` must produce the same ORDER of values as the
#    indexed sort by `ranked`.
FAST=$(curl -s "$U?limit=20&sort=ranked&order=desc" -H "$A" | python3 -c 'import json,sys; print(" ".join(str(i["doc"]["ranked"]) for i in json.load(sys.stdin)["data"]["items"]))')
SLOW=$(curl -s "$U?limit=20&sort=plain&order=desc" -H "$A" | python3 -c 'import json,sys; print(" ".join(str(i["doc"]["plain"]) for i in json.load(sys.stdin)["data"]["items"]))')
[ "$FAST" = "$SLOW" ] && check "indexed and fallback orders agree" 1 || check "indexed and fallback orders agree ($FAST | $SLOW)" 0

# 3. cursor paging visits everything exactly once
WALK=$(python3 - "$PORT" "$ADMIN" <<'PY'
import json, sys, urllib.request, urllib.parse
port, tok = sys.argv[1], sys.argv[2]
cur, out, guard = "", [], 0
while True:
    guard += 1
    if guard > 400: break
    q = f"http://localhost:{port}/api/ev?limit=7&sort=ranked&order=desc"
    if cur: q += "&after=" + urllib.parse.quote(cur)
    r = urllib.request.Request(q); r.add_header("authorization", "Bearer " + tok)
    d = json.loads(urllib.request.urlopen(r, timeout=60).read())["data"]
    out += [i["id"] for i in d["items"]]
    cur = d.get("next", "")
    if not cur: break
print(len(out), len(set(out)))
PY
)
read GOT UNIQ <<< "$WALK"
[ "$GOT" = "$N" ] && [ "$UNIQ" = "$N" ] && check "cursor paging returns all $N rows exactly once" 1 \
  || check "cursor paging returns all $N rows exactly once (got $GOT, $UNIQ unique)" 0

# and it is faster than what it replaced, on the same server and data
t0=$(date +%s%N); curl -s "$U?limit=5&sort=ranked&order=desc" -H "$A" >/dev/null; t1=$(date +%s%N)
t2=$(date +%s%N); curl -s "$U?limit=5&sort=plain&order=desc" -H "$A" >/dev/null; t3=$(date +%s%N)
FASTMS=$(( (t1 - t0) / 1000000 )); SLOWMS=$(( (t3 - t2) / 1000000 ))
echo "  top-5 of $N rows: ${FASTMS}ms indexed, ${SLOWMS}ms scan+sort"
[ "$FASTMS" -le "$SLOWMS" ] && check "the indexed path is not slower" 1 || check "the indexed path is not slower (${FASTMS}ms vs ${SLOWMS}ms)" 0

curl -s -X POST "http://localhost:$PORT/shutdown" -H "$A" >/dev/null 2>&1
sleep 0.4; kill "$SRV" 2>/dev/null; wait "$SRV" 2>/dev/null
rm -rf "$DB"

if [ "$fails" -eq 0 ]; then echo '{"ok":true,"ordered_paging":"pass"}'; exit 0; fi
echo '{"ok":false,"failures":'"$fails"'}'
exit 1

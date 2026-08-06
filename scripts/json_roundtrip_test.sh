#!/usr/bin/env bash
# String fidelity across a REST round-trip.
#
# poche rebuilds a document from the request body field by field. It used to
# unquote each JSON string token and then re-serialize it, which escapes the
# value a SECOND time. Anything already carrying escapes came back changed:
#
#     sent  "séjour à La Cure"      stored  "s\u00e9jour \u00e0 La Cure"
#     sent  "confirmed ✅"           stored  "confirmed \u2705"
#
# and the damage compounds on every update. It bites hard because escaping
# non-ASCII is what many clients do by default — Python's json.dumps, and Go's
# encoding/json for < > &, which is how HTML mail bodies arrived mangled.
#
# String tokens are now spliced in raw, so what goes in comes out. This asserts
# that for the escape classes that broke, and that typed validation still
# rejects what it should — the raw path must not become a hole.
set -u
cd "$(dirname "$0")/.."
BIN=./poche
PORT="${PORT:-17812}"
fails=0
check() { if [ "$2" = "1" ]; then echo "  ok   $1"; else echo "  FAIL $1"; fails=$((fails + 1)); fi; }

DB=$(mktemp -d /tmp/poche-json-XXXX)
export POCHE_DB="$DB"
export POCHE_NO_NUDGE=1
export FEEDBACK_RELAY=off
INIT=$($BIN init)
TOK=$(printf '%s' "$INIT" | sed -n 's/.*"admin_token":"\([^"]*\)".*/\1/p')
[ -n "$TOK" ] || { echo "  FAIL could not init"; exit 1; }

$BIN serve "$PORT" >"$DB/serve.log" 2>&1 &
SRV=$!
cleanup() { kill $SRV 2>/dev/null || true; rm -rf "$DB"; }
trap cleanup EXIT
for _ in $(seq 1 40); do curl -fsS -m 2 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1 && break; sleep 0.25; done

api() { curl -s -H "Authorization: Bearer $TOK" -H "Content-Type: application/json" "$@"; }
api -X POST "http://127.0.0.1:$PORT/admin/schema" \
  -d '{"name":"rt","fields":"title:string!required,body:string,n:int,ok:bool"}' >/dev/null
api -X POST "http://127.0.0.1:$PORT/admin/expose" \
  -d '{"collection":"rt","actions":"read,create,update,delete"}' >/dev/null

python3 - "$TOK" "$PORT" <<'PY'
import json, subprocess, sys
TOK, PORT = sys.argv[1], sys.argv[2]
BASE = f"http://127.0.0.1:{PORT}"

def call(method, path, body=None):
    args = ["curl", "-s", "-X", method, "-H", "Authorization: Bearer " + TOK,
            "-H", "Content-Type: application/json", BASE + path]
    if body is not None:
        args += ["-d", body]
    return subprocess.run(args, capture_output=True, text=True).stdout

def doc_of(raw):
    d = json.loads(raw)["data"]["doc"]
    return json.loads(d) if isinstance(d, str) else d

cases = {
    "plain quotes":     'He said "bonjour"',
    "backslashes":      r"C:\path\to\devis",
    "newline + tab":    "line1\nline2\tend",
    "accented (\\u)":   "séjour à La Cure — 120 €",
    "emoji (surrogate)": "confirmed ✅",
    "json-looking":     '{"nested":"value"}',
    "html entities":    '<p class="x">a &amp; b</p>',
}

fails = 0
for name, value in cases.items():
    # json.dumps escapes non-ASCII by default — exactly the client behaviour
    # that exposed the bug.
    created = call("POST", "/api/rt", json.dumps({"title": name, "body": value, "n": 1, "ok": True}))
    try:
        rid = json.loads(created)["data"]["_id"]
    except Exception:
        print(f"  FAIL create {name}: {created[:70]}"); fails += 1; continue

    got = doc_of(call("GET", f"/api/rt/{rid}")).get("body")
    if got == value:
        print(f"  ok   round-trip: {name}")
    else:
        print(f"  FAIL round-trip: {name}\n         sent  {value!r}\n         got   {got!r}")
        fails += 1

    # An update must not compound the damage either.
    call("PUT", f"/api/rt/{rid}", json.dumps({"title": name, "body": value, "n": 2, "ok": False}))
    got2 = doc_of(call("GET", f"/api/rt/{rid}")).get("body")
    if got2 != value:
        print(f"  FAIL update kept it intact: {name}\n         got   {got2!r}")
        fails += 1

# Typed validation must survive the raw-splice path.
for body, expect in [
    ('{"body":"no title"}',            "required field missing"),
    ('{"title":123}',                  "want string"),
    ('{"title":"x","n":"nope"}',       "want int"),
    ('{"title":"x","ok":"yes"}',       "want bool"),
]:
    out = call("POST", "/api/rt", body)
    if expect in out:
        print(f"  ok   rejects {body}")
    else:
        print(f"  FAIL {body} should have failed with {expect!r}: {out[:70]}")
        fails += 1

# Malformed escapes must not take the server down.
call("POST", "/api/rt", '{"title":"x","body":"\\uZZZZ"}')
health = subprocess.run(["curl", "-s", "-m", "3", BASE + "/health"], capture_output=True, text=True).stdout
if '"ok":true' in health:
    print("  ok   survives malformed escapes")
else:
    print("  FAIL server died on malformed escapes"); fails += 1

print(json.dumps({"ok": fails == 0, "json_roundtrip": "pass" if fails == 0 else "fail"}))
sys.exit(1 if fails else 0)
PY
rc=$?
[ $rc -eq 0 ] || fails=$((fails + 1))
exit $fails

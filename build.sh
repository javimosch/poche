#!/usr/bin/env bash
# Build poche — agent-first headless CMS over grange.
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
# Prefer sibling checkouts under ~/ai (dogfood layout); override with env.
FRAMEWORK="${FRAMEWORK:-$ROOT/../machin/framework}"
GRANGE_SRC="${GRANGE_SRC:-$ROOT/../grange/src}"
if [[ ! -f "$FRAMEWORK/flags.src" ]]; then
  FRAMEWORK="$ROOT/framework"
fi
if [[ ! -f "$GRANGE_SRC/engine.src" ]]; then
  GRANGE_SRC="$ROOT/vendor/grange"
fi

SRCS=(
  "$FRAMEWORK/flags.src"
  "$FRAMEWORK/machweb.src"
  # grange's embeddable core. This list is not free-form: grange's modules call
  # each other, so a subset either resolves or does not compile at all. It broke
  # once (cold.src -> g_cifields in coldindex.src) and poche stayed broken until
  # someone rebuilt. grange now pins the same list in scripts/embed_test.sh and
  # compiles it in its gate, so drift shows up there instead of here.
  "$GRANGE_SRC/recfile.src"
  "$GRANGE_SRC/engine.src"
  "$GRANGE_SRC/registry.src"
  "$GRANGE_SRC/cold.src"
  "$GRANGE_SRC/coldbulk.src"
  "$GRANGE_SRC/coldindex.src"
  "$GRANGE_SRC/coldquery.src"
  "$GRANGE_SRC/coldrange.src"
  "$GRANGE_SRC/coldsort.src"
  "$GRANGE_SRC/index.src"
  "$GRANGE_SRC/range.src"
  "$GRANGE_SRC/qcost.src"
  "$GRANGE_SRC/project.src"
  "$GRANGE_SRC/query.src"
  "$GRANGE_SRC/order.src"
  src/out.src
  src/store.src
  src/query_page.src
  src/link_query.src
  src/realtime.src
  src/schema.src
  src/data.src
  src/auth.src
  src/admin.src
  src/cloud.src
  src/files.src
  src/mutations.src
  src/guide.src
  src/feedback.src
  src/update.src
  src/bench.src
  src/serve.src
  src/main.src
)

"$MACHIN" encode "${SRCS[@]}" > poche.mfl

# STATIC=1 builds the RELEASE artifact: no libssl/libcrypto, no glibc floor.
#
# Without it machin links against the build host's libraries, and CI runs on
# ubuntu-latest — so the published binary carried a glibc 2.38 floor and would
# not start on anything older than Ubuntu 24.04, nor on Alpine or a slim
# container. Nobody could have reported that: the failure happens before the
# tool runs. Found by an estate-wide install audit (stranger).
if [ "${STATIC:-0}" = "1" ]; then
  "$MACHIN" build poche.mfl -o poche --static
  # ldd EXITS 1 on a static binary, and this script runs under `set -o pipefail`,
  # so `ldd x | grep -q ...` fails even when grep matches — the first version of
  # this guard rejected a perfectly static binary. Capture, then match.
  LDD_OUT=$(ldd poche 2>&1 || true)
  case "$(file poche)" in *"statically linked"*) ;; *) echo "STATIC=1 but the binary is not static — refusing"; exit 1 ;; esac
  case "$LDD_OUT" in *"not a dynamic executable"*) ;; *) echo "STATIC=1 but the binary has dynamic deps — refusing: $LDD_OUT"; exit 1 ;; esac
  echo "built ./poche (static, $(wc -c < poche) bytes)"
else
  "$MACHIN" build poche.mfl -o poche
  echo "built ./poche"
fi

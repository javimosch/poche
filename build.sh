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
  "$GRANGE_SRC/engine.src"
  "$GRANGE_SRC/registry.src"
  "$GRANGE_SRC/cold.src"
  "$GRANGE_SRC/index.src"
  "$GRANGE_SRC/range.src"
  "$GRANGE_SRC/query.src"
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
"$MACHIN" build poche.mfl -o poche
echo "built ./poche"

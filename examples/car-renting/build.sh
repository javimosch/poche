#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"
"$MACHIN" encode ../../sdk/machin/poche_client.src app.src > car-renting.mfl
"$MACHIN" build car-renting.mfl -o car-renting
echo "built ./car-renting"

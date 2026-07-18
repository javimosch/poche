#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"
"$MACHIN" encode ../../sdk/machin/poche_client.src app.src > amazon-marketplace.mfl
"$MACHIN" build amazon-marketplace.mfl -o amazon-marketplace
echo "built ./amazon-marketplace"

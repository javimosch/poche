#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"
"$MACHIN" encode ../../sdk/machin/poche_client.src app.src > twitter-social-media.mfl
"$MACHIN" build twitter-social-media.mfl -o twitter-social-media
echo "built ./twitter-social-media"

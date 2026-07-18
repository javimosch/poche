#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

./build.sh >/dev/null

for app in twitter-social-media amazon-marketplace car-renting; do
  printf 'dogfood %-24s ' "$app"
  "./examples/$app/smoke.sh"
done

echo '{"ok":true,"suite":"dogfood","apps":3}'

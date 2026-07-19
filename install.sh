#!/usr/bin/env bash
# poche installer — cli-update-spec §5 (content-hash VERSION + smoke test).
set -euo pipefail

BASE="${POCHE_UPDATE_BASE:-https://github.com/javimosch/poche/releases/latest/download}"
URL="${POCHE_UPDATE_URL:-$BASE/poche-linux-amd64}"
DEST="${POCHE_HOME:-$HOME/.poche}"
BIN_DIR="$DEST/bin"
TMP="$(mktemp)"

echo "downloading $URL" >&2
curl -fsSL -m 120 "$URL" -o "$TMP"
VER="$(sha256sum "$TMP" | cut -c1-12)"
mkdir -p "$BIN_DIR"
install -m 755 "$TMP" "$BIN_DIR/poche"
rm -f "$TMP"
printf '%s\n' "$VER" > "$DEST/VERSION"

# PATH helper
LINK_DIR="${POCHE_LINK_DIR:-$HOME/.local/bin}"
mkdir -p "$LINK_DIR"
ln -sfn "$BIN_DIR/poche" "$LINK_DIR/poche"

if ! "$BIN_DIR/poche" version >/dev/null; then
  echo "smoke test failed; binary at $BIN_DIR/poche" >&2
  exit 1
fi

echo "installed poche $VER → $BIN_DIR/poche" >&2
echo "ensure $LINK_DIR is on PATH" >&2
echo "future updates: poche update" >&2

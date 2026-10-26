#!/usr/bin/env bash
# setup-dxvk.sh — install DXVK's 32-bit d3d9/dxgi into the wine prefix.
# The game is 32-bit, so we need x32 -> syswow64.
set -euo pipefail

PREFIX="${CR_PREFIX:-$HOME/Games/conquest-reborn/pfx}"
DXVK_VER="${DXVK_VER:-3.1.1}"
DEST="$PREFIX/drive_c/windows/syswow64"

if [ ! -f "$DEST/../system32/kernel32.dll" ] && [ ! -d "$PREFIX/drive_c/windows" ]; then
  echo "prefix $PREFIX doesn't look like a wine prefix" >&2
  exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Fetching DXVK $DXVK_VER..."
curl -sSL -o "$TMP/dxvk.tar.gz" \
  "https://github.com/doitsujin/dxvk/releases/download/v$DXVK_VER/dxvk-$DXVK_VER.tar.gz"
tar -xzf "$TMP/dxvk.tar.gz" -C "$TMP"

cp "$TMP/dxvk-$DXVK_VER/x32/d3d9.dll" "$TMP/dxvk-$DXVK_VER/x32/dxgi.dll" "$DEST/"
echo "Installed d3d9.dll + dxgi.dll into $DEST"
echo "Make sure WINEDLLOVERRIDES includes: d3d9=n;dxgi=n"

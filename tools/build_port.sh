#!/bin/bash
# Builds build/port/: the launcher + detoimeme/ (LÖVE aarch64 binary, libs, game files).
# The LÖVE binary and libs come from a local build of the PortMaster "Spotify Connect" port
# Set LOVE_BIN_DIR (or build/love-bin-dir) to the dir containing the LÖVE ELF and libs/.
set -euo pipefail
cd "$(dirname "$0")/.."
export COPYFILE_DISABLE=1

SRC_BIN="${LOVE_BIN_DIR:-}"
[ -z "$SRC_BIN" ] && [ -f build/love-bin-dir ] && SRC_BIN=$(head -1 build/love-bin-dir)
if [ -z "$SRC_BIN" ]; then
  echo "usage: LOVE_BIN_DIR=/dir/with/love-elf-and-libs $0   (or put that path in build/love-bin-dir)" >&2
  exit 1
fi
SRC_ELF="${LOVE_BIN_NAME:-lafleur-ui}"
[ -f "$SRC_BIN/$SRC_ELF" ] && [ -d "$SRC_BIN/libs" ] || { echo "LÖVE binary/libs not found in $SRC_BIN" >&2; exit 1; }

OUT=build/port
rm -rf "$OUT"
mkdir -p "$OUT/detoimeme/bin" "$OUT/detoimeme/game"

cp -X "port/De toi-meme tu sais.sh" "$OUT/"
chmod +x "$OUT/De toi-meme tu sais.sh"

cp -X "$SRC_BIN/$SRC_ELF" "$OUT/detoimeme/bin/detoimeme"
chmod +x "$OUT/detoimeme/bin/detoimeme"
mkdir -p "$OUT/detoimeme/bin/libs"
for f in "$SRC_BIN"/libs/*; do cp -X "$f" "$OUT/detoimeme/bin/libs/"; done

cp -X main.lua conf.lua "$OUT/detoimeme/game/"
for d in src words assets; do
  mkdir -p "$OUT/detoimeme/game/$d"
  (cd "$d" && find . -type f ! -name '._*' ! -name '.DS_Store' -print0) |
    while IFS= read -r -d '' f; do
      mkdir -p "$OUT/detoimeme/game/$d/$(dirname "$f")"
      cp -X "$d/$f" "$OUT/detoimeme/game/$d/$f"
    done
done
find "$OUT" \( -name '._*' -o -name '.DS_Store' \) -delete
echo "built $OUT"

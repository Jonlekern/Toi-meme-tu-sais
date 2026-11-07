#!/bin/bash
# Builds the web version with love.js (compatibility mode).
# usage: tools/build_web.sh [output-dir]   (default: build/web)
set -euo pipefail
cd "$(dirname "$0")/.."
export COPYFILE_DISABLE=1

LOVEJS_VERSION="11.4.1"
OUT="${1:-build/web}"
mkdir -p build
LOVE=build/detoimeme.love
rm -f "$LOVE"
zip -X -r -q "$LOVE" main.lua conf.lua src words assets -x '*.DS_Store' -x '*/._*'

rm -rf "$OUT"
npx --yes "love.js@$LOVEJS_VERSION" -c -t "De toi-même tu sais" "$LOVE" "$OUT"

# Our own page replaces the generated one.
cp web/index.html "$OUT/index.html"
rm -rf "$OUT/theme"
cat > "$OUT/README.md" <<'EOR'
# De toi-même tu sais (web)

Static site: serve this folder as-is over HTTPS (any static host, no server code).
Open `index.html`; the game loads from the files next to it.

Files:
- `index.html`: the page (canvas scaled to fit, 3:2)
- `game.js`, `game.data`: the game package
- `love.js`, `love.wasm`: the LOVE runtime
EOR
echo "Web build ready in $OUT"

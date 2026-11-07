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
npx --yes "love.js@$LOVEJS_VERSION" -c -t "Toi-même tu sais" "$LOVE" "$OUT"

# Our own page replaces the generated one.
cp web/index.html "$OUT/index.html"
cp assets/logo/logo-32.png "$OUT/favicon-32.png"
cp assets/logo/logo-192.png "$OUT/icon-192.png"
cp assets/logo/logo-180.png "$OUT/apple-touch-icon.png"
cp assets/logo/logo-512.png "$OUT/icon-512.png"
cp web/manifest.webmanifest "$OUT/manifest.webmanifest"
cp web/sw.js "$OUT/sw.js"
mkdir -p "$OUT/fonts"
cp assets/fonts/Calebard-Bold.ttf assets/fonts/Calebard-Regular.ttf "$OUT/fonts/"
rm -rf "$OUT/theme"
cat > "$OUT/README.md" <<'EOR'
# Toi-même tu sais (web)

Static site: serve this folder as-is over HTTPS (any static host, no server code).
Open `index.html`; the game loads from the files next to it.

Files:
- `index.html`: the page (canvas fills the window; 3:2 screen, or 480x800 when held upright)
- `game.js`, `game.data`: the game package
- `love.js`, `love.wasm`: the LOVE runtime
- `favicon-32.png`, `icon-192.png`, `icon-512.png`, `apple-touch-icon.png`: the logo icons
- `manifest.webmanifest`, `sw.js`: make the site installable (the service worker only passes requests to the network, no cache)
- `fonts/`: Calebard Bold and Regular, used by the install help card
EOR
echo "Web build ready in $OUT"

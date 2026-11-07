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

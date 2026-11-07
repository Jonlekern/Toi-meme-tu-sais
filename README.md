<p align="center"><img src="assets/logo/logo-512.png" width="160" alt="Toi-même tu sais"></p>

# Toi-même tu sais

A French party word game by LAFLEURSTUDIO, built with LÖVE 11.5.

Two players team up while the others listen. One of them sees an everyday word
and makes the partner guess it **only by recalling memories they share**. The
other team listens and can try to guess too. Press A for the next word, X to
skip a word that is too hard.

- 6 categories (Maison, Bouffe, Transport, Boulot/École, Santé, Soirée) mixed
  into a base list of ~500 words by a hidden die.
- Optional timer: 30, 60 or 90 seconds. No score.
- Create your own categories and words in the game (on-screen keyboard on the console).
- On the Anbernic RG SP: closing and reopening the lid shows a new word, and
  every word shown is logged to `stats.txt` for later statistics.

## Platforms

- **Anbernic RG SP (ROCKNIX)**: PortMaster-style port, in the Ports menu.
- **Web browser**: static site built with love.js (see below), playable with a
  mouse and keyboard or by touch.

## Run on a computer

Install [LÖVE](https://love2d.org/) 11.5, then from the project root:

    love .

## Web

Needs [Node.js](https://nodejs.org/) (for `npx`) and `zip`. From the project root:

    tools/build_web.sh <output-dir>

The script packages the game and runs love.js 11.4.1 in compatibility mode
(`-c`, no SharedArrayBuffer needed), then puts `web/index.html` in place of the
generated page. Without an argument the output goes to `build/web`.

The result is a static site: serve the folder as-is over HTTPS from any static
host (to try it locally: `python3 -m http.server -d <output-dir>`). Publishing
it is done by hand; no script uploads anything.

## Install on the console

1. On the console, enable Samba (START > Network Settings > Enable Samba).
2. Point the build at a folder holding an aarch64 LÖVE 11.5 binary and its
   `libs/` folder (for example the binary folder of another LÖVE port):
   - `LOVE_BIN_DIR`: that folder (or write its path on the first line of
     `build/love-bin-dir`);
   - `LOVE_BIN_NAME`: the file name of the binary in it (default `lafleur-ui`).

   `tools/build_port.sh` copies it to `build/port/detoimeme/bin/detoimeme`
   with `libs/`, the game files and the launcher.
3. `tools/install_console.sh` (dry run) shows what it would do;
   `tools/install_console.sh --yes` builds the port and copies it to
   `/storage/roms/ports` over the console's `games-roms` Samba share, backing up
   any file it replaces into `build/` first.
4. On the console: START > Game Settings > Update Gamelists, then Ports.

## Tests

The game logic lives in `src/` as pure Lua:

    luajit tests/run.lua

## Fonts

Clebard and Calebard by LAFLEURSTUDIO (https://jonlekern.github.io/Fonts/),
licence files in `assets/fonts/`.

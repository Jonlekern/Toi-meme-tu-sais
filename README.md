# De toi-même tu sais

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
- **Browser**: coming next (love.js).

## Run on a computer

Install [LÖVE](https://love2d.org/) 11.5, then from the project root:

    love .

## Install on the console

1. On the console, enable Samba (START > Network Settings > Enable Samba).
2. Put the path of an aarch64 LÖVE 11.5 binary folder (`love` binary + `libs/`)
   in `build/love-bin-dir`, or set `LOVE_BIN_DIR`.
3. `tools/install_console.sh` shows what it would copy; `tools/install_console.sh --yes`
   builds the port and copies it to `/storage/roms/ports`.
4. On the console: START > Game Settings > Update Gamelists, then Ports.

## Tests

The game logic lives in `src/` as pure Lua:

    luajit tests/run.lua

## Fonts

Clebard and Calebard by LAFLEURSTUDIO (https://jonlekern.github.io/Fonts/),
licence files in `assets/fonts/`.

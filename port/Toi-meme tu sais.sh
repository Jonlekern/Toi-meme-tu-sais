#!/bin/bash
# Toi-même tu sais — launcher shown in the "Ports" menu of ROCKNIX.
# LÖVE: aarch64 binary from the PortMaster "Spotify Connect" port, copied as "detoimeme"
# so the ROCKNIX close shortcut (set_kill) only targets this game.

. /etc/profile

GAME=/storage/roms/ports/detoimeme
if [ ! -d "$GAME" ]; then
  echo "$(date) $GAME absent" >> /tmp/detoimeme-missing.log
  exit 0
fi

mkdir -p "$GAME/conf"
: > "$GAME/log.txt"
exec >> "$GAME/log.txt" 2>&1
echo "$(date '+%H:%M:%S') [launcher] start"

# Button mapping for SDL, generated the way PortMaster does it.
PADDB=/tmp/detoimeme-gamecontrollerdb.txt
if [ -x /storage/.config/PortMaster/mapper.txt ]; then
  /storage/.config/PortMaster/mapper.txt "$PADDB" /storage/roms/ports/PortMaster && export SDL_GAMECONTROLLERCONFIG_FILE="$PADDB"
fi

# /usr/lib/compat: ROCKNIX compatibility libs (libtheoradec...).
export LD_LIBRARY_PATH="$GAME/bin/libs:/usr/lib/compat:$LD_LIBRARY_PATH"
# LÖVE save directory (settings.txt, mes-mots.txt, stats.txt) ends up under games-roms.
export XDG_DATA_HOME="$GAME/conf"

set_kill set "detoimeme"
cd "$GAME" && "$GAME/bin/detoimeme" "$GAME/game"
echo "$(date '+%H:%M:%S') [launcher] game ended (code $?)"

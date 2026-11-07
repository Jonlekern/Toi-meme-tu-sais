#!/bin/bash
# Installs build/port/ on the RG SP over Wi-Fi (guest Samba share games-roms of ROCKNIX).
# Default is a dry run (prints every action, no network access). Pass --yes to really install.
# Never touches /storage/roms/lafleur-music or /storage/.config/logind.conf.d.
# Files on the share are written with `cat src > dest` then checked with cmp
# (no cp/rsync/sed -i on the share: they misbehave over Samba).
set -euo pipefail
cd "$(dirname "$0")/.."

DRY=1
for a in "$@"; do
  case "$a" in
    --yes) DRY=0 ;;
    --dry-run) DRY=1 ;;
    *) echo "usage: $0 [--dry-run|--yes]" >&2; exit 2 ;;
  esac
done

HOST="${RGSP_HOST:-192.168.1.138}"
MNT="${TMPDIR:-/tmp}/detoimeme-rgsp"
SRC=build/port
LAUNCHER="De toi-meme tu sais.sh"
BACKUP="build/console-backup-$(date +%Y%m%d-%H%M%S)"
export COPYFILE_DISABLE=1

[ -d "$SRC/detoimeme" ] && [ -f "$SRC/$LAUNCHER" ] || { echo "run tools/build_port.sh first" >&2; exit 1; }

if [ "$DRY" = 1 ]; then
  echo "[dry-run] nc -z -G 3 $HOST 445"
  echo "[dry-run] mount_smbfs -N //guest@$HOST/games-roms $MNT/games-roms (unless already mounted)"
  echo "[dry-run] back up existing '$LAUNCHER' and detoimeme/ files that differ to $BACKUP/ (cat > backup ; cmp)"
  echo "[dry-run] mkdir -p <share>/ports/detoimeme"
  echo "[dry-run] tools/build_port.sh (rebuild first)"
  n=0
  while IFS= read -r -d '' f; do
    rel="${f#$SRC/}"
    echo "[dry-run] cat '$f' > '<share>/ports/$rel' ; cmp"
    n=$((n + 1))
  done < <(find "$SRC/detoimeme" -type f ! -name '._*' ! -name '.DS_Store' -print0 | sort -z)
  echo "[dry-run] cat '$SRC/$LAUNCHER' > '<share>/ports/$LAUNCHER' ; cmp   (launcher last)"
  n=$((n + 1))
  echo "[dry-run] $n file(s) to copy (only those that differ)"
  echo "[dry-run] warn if launcher or bin/detoimeme is not executable on the share"
  echo "[dry-run] delete ._* under <share>/ports/detoimeme and the launcher's ._ file"
  echo "[dry-run] umount $MNT/games-roms (only if mounted by this script)"
  echo "dry run only: pass --yes to install."
  exit 0
fi

echo "Quitte le jeu sur la console avant une mise à jour."
tools/build_port.sh
nc -z -G 3 "$HOST" 445 || { echo "console unreachable ($HOST:445)" >&2; exit 1; }

mounted_here=0
cleanup() { if [ "$mounted_here" = 1 ]; then umount "$MNT/games-roms" || true; fi; }
trap cleanup EXIT
existing=$(mount | sed -n "s#^//[^@]*@$HOST/games-roms on \(.*\) (smbfs.*#\1#p" | head -1)
if [ -n "$existing" ]; then
  ROMS="$existing"
else
  mkdir -p "$MNT/games-roms"
  mount_smbfs -N "//guest@$HOST/games-roms" "$MNT/games-roms"
  mounted_here=1
  ROMS="$MNT/games-roms"
fi

PORTS="$ROMS/ports"
[ -d "$PORTS" ] || { echo "$PORTS missing" >&2; exit 1; }
mkdir -p "$PORTS/detoimeme" "$BACKUP"

copied=0
copy_one() { # relative path under build/port
  local rel="$1" f="$SRC/$1" dest="$PORTS/$1"
  if [ -f "$dest" ] && cmp -s "$f" "$dest"; then return; fi
  if [ -f "$dest" ]; then
    mkdir -p "$BACKUP/$(dirname "$rel")"
    cat "$dest" > "$BACKUP/$rel"
    cmp "$dest" "$BACKUP/$rel" || { echo "backup failed: $rel" >&2; exit 1; }
  fi
  mkdir -p "$(dirname "$dest")"
  cat "$f" > "$dest"
  cmp "$f" "$dest" || { echo "verification failed: $rel" >&2; exit 1; }
  if [ -x "$f" ] && [ ! -x "$dest" ]; then echo "warning: $rel not executable on share" >&2; fi
  copied=$((copied + 1))
}
# game tree first, launcher last
while IFS= read -r -d '' f; do
  copy_one "${f#$SRC/}"
done < <(find "$SRC/detoimeme" -type f ! -name '._*' ! -name '.DS_Store' -print0 | sort -z)
copy_one "$LAUNCHER"
echo "$copied file(s) copied"

find "$PORTS/detoimeme" -name '._*' -delete
rm -f "$PORTS/._$LAUNCHER"
rmdir "$BACKUP" 2>/dev/null || true
echo "installed. Refresh the game list in EmulationStation if the entry does not show."

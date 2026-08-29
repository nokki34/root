#!/usr/bin/env bash
set -euo pipefail

FORCE=false
BASE_ONLY=false
MACHINE=""
for arg in "$@"; do
  case "$arg" in
    -f|--force) FORCE=true ;;
    --base) BASE_ONLY=true ;;   # capture straight into files/, ignoring layers
    -*) echo "Unknown flag: $arg"; exit 1 ;;
    *) MACHINE="$arg" ;;   # optional machine name, e.g. `./collect.sh arch` → files-arch/
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATHS_CONF="$SCRIPT_DIR/paths.conf"
BASE_DIR="$SCRIPT_DIR/files"
MACHINE_DIR=""

# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

if [ "$BASE_ONLY" = "true" ]; then
  MACHINE=""
  echo "[machine] none - files/ only (--base)"
else
  resolve_machine "$MACHINE"
  if [ -z "$MACHINE" ]; then
    echo "[error] no machine set. Export DOTFILES_MACHINE or pass one:"
    echo "          $(basename "$0") arch"
    exit 1
  fi
  MACHINE_DIR="$SCRIPT_DIR/files-$MACHINE"
  echo "[machine] $MACHINE"
fi

mkdir -p "$BASE_DIR"
[ -n "$MACHINE_DIR" ] && mkdir -p "$MACHINE_DIR"

# Capture live state for one machine by decomposing it against the base layer:
# unchanged files need no overlay at all, files that merely extend base are
# stored as a `.append` tail, anything else becomes a full override.
collect_machine() {
  local rel="$1" lrel base live n
  local -a seen=()

  while IFS= read -r lrel; do
    [ -z "$lrel" ] && continue
    seen+=("$lrel")
    base="$BASE_DIR/$lrel"
    live="$HOME/$lrel"

    if [ ! -f "$base" ]; then
      mkdir -p "$(dirname "$MACHINE_DIR/$lrel")"
      cp "$live" "$MACHINE_DIR/$lrel"
      echo "[collect] $lrel → files-$MACHINE/ (machine-only)"
    elif cmp -s "$live" "$base"; then
      if [ -f "$MACHINE_DIR/$lrel" ] || [ -f "$MACHINE_DIR/$lrel.append" ]; then
        rm -f "$MACHINE_DIR/$lrel" "$MACHINE_DIR/$lrel.append"
        echo "[collect] $lrel → matches base, overlay dropped"
      fi
    elif is_prefix "$base" "$live"; then
      n=$(wc -c < "$base")
      mkdir -p "$(dirname "$MACHINE_DIR/$lrel")"
      tail -c +$((n + 1)) "$live" > "$MACHINE_DIR/$lrel.append"
      rm -f "$MACHINE_DIR/$lrel"
      echo "[collect] $lrel → files-$MACHINE/$lrel.append (append)"
    else
      if [ -f "$MACHINE_DIR/$lrel.append" ]; then
        echo "[warn]    $lrel no longer extends base, storing as full override"
        rm -f "$MACHINE_DIR/$lrel.append"
      fi
      mkdir -p "$(dirname "$MACHINE_DIR/$lrel")"
      cp "$live" "$MACHINE_DIR/$lrel"
      echo "[collect] $lrel → files-$MACHINE/$lrel (replace)"
    fi
  done < <(live_rels "$rel")

  # prune overlay entries whose file no longer exists on this machine
  local ov ovrel
  while IFS= read -r ov; do
    [ -z "$ov" ] && continue
    ovrel="${ov%.append}"
    if ! printf '%s\n' "${seen[@]:-}" | grep -qxF "$ovrel"; then
      rm -f "$MACHINE_DIR/$ov"
      echo "[collect] $ovrel → gone locally, overlay pruned"
    fi
  done < <(cd "$MACHINE_DIR" 2>/dev/null && find "$rel" -type f 2>/dev/null || true)
  find "$MACHINE_DIR" -type d -empty -delete 2>/dev/null || true
}


while IFS=$'\t' read -r line rel; do
  path="$HOME/$rel"

  if [ ! -e "$path" ]; then
    echo "[warn]    $line not found, skipping"
    continue
  fi

  if [ -z "$MACHINE_DIR" ]; then
    # No machine named: mirror straight into the base layer (clean replace, no merge).
    dest="$BASE_DIR/$rel"
    mkdir -p "$(dirname "$dest")"
    if [ -d "$path" ]; then
      echo "[collect] $line → files/$rel/"
      rm -rf "$dest"
      cp -r "$path" "$dest"
    else
      echo "[collect] $line → files/$rel"
      cp "$path" "$dest"
    fi
    continue
  fi

  collect_machine "$rel"
done < <(paths_each)

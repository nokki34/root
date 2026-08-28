#!/usr/bin/env bash
set -euo pipefail

FORCE=false
MACHINE=""
for arg in "$@"; do
  case "$arg" in
    -f|--force) FORCE=true ;;
    -*) echo "Unknown flag: $arg"; exit 1 ;;
    *) MACHINE="$arg" ;;   # optional machine name, e.g. `./deploy.sh arch` → files-arch/
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATHS_CONF="$SCRIPT_DIR/paths.conf"
BASE_DIR="$SCRIPT_DIR/files"
MACHINE_DIR=""

if [ ! -d "$BASE_DIR" ]; then
  echo "[error] files/ does not exist"
  exit 1
fi

if [ -n "$MACHINE" ]; then
  MACHINE_DIR="$SCRIPT_DIR/files-$MACHINE"
  if [ ! -d "$MACHINE_DIR" ]; then
    echo "[error] files-$MACHINE/ does not exist"
    exit 1
  fi
fi

# shellcheck source=lib.sh
. "$SCRIPT_DIR/lib.sh"

# Assemble base + overlay in a staging dir, then treat that as the source of truth.
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

SOURCES="files/"
[ -n "$MACHINE" ] && SOURCES="files/ + files-$MACHINE/"

while IFS=$'\t' read -r line rel; do
  path="$HOME/$rel"

  if ! layer_stage "$rel" "$STAGE"; then
    echo "[warn]    $line not in $SOURCES, skipping"
    continue
  fi
  src="$STAGE/$rel"

  if [ -n "$MACHINE" ]; then
    # show how each diverging file was assembled, so the overlay is auditable
    while IFS= read -r f; do
      mode="$(layer_mode "$f")"
      [ "$mode" = "base" ] || echo "[layer]   $f ← $mode"
    done < <(layer_rels "$rel")
  fi

  if [ ! -e "$path" ]; then
    echo "[deploy] $line → new, copying"
    mkdir -p "$(dirname "$path")"
    cp -r "$src" "$path"
    continue
  fi

  if diff -rq "$src" "$path" > /dev/null 2>&1; then
    echo "[deploy] $line → identical, skipping"
    continue
  fi

  if [[ "$FORCE" == "true" ]]; then
    echo "[deploy] $line → overwriting"
  else
    printf "[conflict] %s → differs. Overwrite? [y/N] " "$line"
    read -r answer < /dev/tty
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
      echo "[deploy] $line → skipped"
      continue
    fi
    echo "[deploy] $line → overwritten"
  fi

  rm -rf "$path"
  cp -r "$src" "$path"
done < <(paths_each)

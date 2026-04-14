#!/usr/bin/env bash
set -euo pipefail

FORCE=false
for arg in "$@"; do
  case "$arg" in
    -f|--force) FORCE=true ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATHS_CONF="$SCRIPT_DIR/paths.conf"
FILES_DIR="$SCRIPT_DIR/files"

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%"${line##*[! 	]}"}"   # trim trailing spaces/tabs
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

  path="${line/#\~/$HOME}"
  rel="${path#"$HOME"/}"
  src="$FILES_DIR/$rel"

  if [ ! -e "$src" ]; then
    echo "[warn]    $line not in files/, skipping"
    continue
  fi

  if [ ! -e "$path" ]; then
    echo "[deploy] $line → new, copying"
    mkdir -p "$(dirname "$path")"
    if [ -d "$src" ]; then
      cp -r "$src" "$path"
    else
      cp "$src" "$path"
    fi
    continue
  fi

  # check if identical
  if [ -d "$src" ]; then
    identical=$(diff -rq "$src" "$path" > /dev/null 2>&1 && echo yes || echo no)
  else
    identical=$(diff -q "$src" "$path" > /dev/null 2>&1 && echo yes || echo no)
  fi

  if [ "$identical" = "yes" ]; then
    echo "[deploy] $line → identical, skipping"
    continue
  fi

  # differs — check force flag or prompt
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

  if [ -d "$src" ]; then
    rm -rf "$path"
    cp -r "$src" "$path"
  else
    cp "$src" "$path"
  fi

done < "$PATHS_CONF"

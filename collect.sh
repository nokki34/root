#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATHS_CONF="$SCRIPT_DIR/paths.conf"

# optional machine name, e.g. `./collect.sh arch` → files-arch/
MACHINE="${1:-}"
FILES_DIR="$SCRIPT_DIR/files${MACHINE:+-$MACHINE}"
FILES_NAME="$(basename "$FILES_DIR")"

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%"${line##*[! 	]}"}"   # trim trailing spaces/tabs
  # skip blank lines and comments
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

  # expand ~ to $HOME
  path="${line/#\~/$HOME}"

  # relative path from HOME (e.g. .config/nvim)
  rel="${path#"$HOME"/}"
  dest="$FILES_DIR/$rel"

  if [ ! -e "$path" ]; then
    echo "[warn]    $line not found, skipping"
    continue
  fi

  mkdir -p "$(dirname "$dest")"

  if [ -d "$path" ]; then
    echo "[collect] $line → $FILES_NAME/$rel/"
    rm -rf "$dest"
    cp -r "$path" "$dest"
  else
    echo "[collect] $line → $FILES_NAME/$rel"
    cp "$path" "$dest"
  fi

done < "$PATHS_CONF"

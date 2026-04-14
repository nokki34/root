#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATHS_CONF="$SCRIPT_DIR/paths.conf"
FILES_DIR="$SCRIPT_DIR/files"

while IFS= read -r line; do
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
    echo "[collect] $line → files/$rel/"
    rm -rf "$dest"
    cp -r "$path" "$dest"
  else
    echo "[collect] $line → files/$rel"
    cp "$path" "$dest"
  fi

done < "$PATHS_CONF"

#!/usr/bin/env bash
# Shared layering logic for collect.sh and deploy.sh.
#
# Layout
#   files/              base layer - machine-agnostic, used by every machine
#   files-<machine>/    overlay layer for one machine, where each entry is:
#
#       <f>.append      deployed file = base <f> + this tail      (append)
#       <f>             replaces base <f> outright                (replace)
#       <f>, no base counterpart                                  (machine-only)
#
#   A base file with no overlay entry is deployed verbatim.
#
# Callers set BASE_DIR, PATHS_CONF, and MACHINE_DIR ("" when no machine named).

# Which machine layer to use: $DOTFILES_MACHINE, else the command-line
# argument. Neither being set is an error - guessing would risk writing the
# wrong machine's configs, which is the whole thing we are avoiding.
#
# Sets MACHINE ("" when nothing is set).
resolve_machine() {
  if [ -n "${DOTFILES_MACHINE:-}" ]; then
    MACHINE="$DOTFILES_MACHINE"
  else
    MACHINE="${1:-}"
  fi
}

# Emit each managed entry from paths.conf as: <raw line><TAB><$HOME-relative path>
#
# An entry may be scoped to particular machines with a trailing
# "@machine[,machine...]", for tools that only exist on some boxes:
#
#     ~/.aerospace.toml    @mac
#
# A scoped entry is skipped entirely on every other machine - not deployed
# there, and not collected from there either, so a stray leftover copy can
# never sneak back in as a machine-only file.
paths_each() {
  local line path scope
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%"${line##*[! 	]}"}"          # trim trailing spaces/tabs
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    scope=""
    if [[ "$line" =~ ^(.*[^[:space:]])[[:space:]]+@([A-Za-z0-9_,-]+)$ ]]; then
      line="${BASH_REMATCH[1]}"
      scope="${BASH_REMATCH[2]}"
    fi
    if [ -n "$scope" ]; then
      [ -z "${MACHINE:-}" ] && continue                 # base runs skip scoped entries
      [[ ",$scope," == *",${MACHINE},"* ]] || continue
    fi

    path="${line/#\~/$HOME}"
    printf '%s\t%s\n' "$line" "${path#"$HOME"/}"
  done < "$PATHS_CONF"
}

# List every logical path under managed path $1, across both layers.
# `.append` suffixes are stripped: callers work in logical paths and let
# layer_mode decide how each one is assembled.
layer_rels() {
  local rel="$1"
  {
    if [ -d "$BASE_DIR/$rel" ]; then (cd "$BASE_DIR" && find "$rel" -type f)
    elif [ -f "$BASE_DIR/$rel" ]; then echo "$rel"; fi

    if [ -n "$MACHINE_DIR" ]; then
      if [ -d "$MACHINE_DIR/$rel" ]; then (cd "$MACHINE_DIR" && find "$rel" -type f)
      elif [ -f "$MACHINE_DIR/$rel" ]; then echo "$rel"; fi
      [ -f "$MACHINE_DIR/$rel.append" ] && echo "$rel.append"
    fi
  } 2>/dev/null | sed 's/\.append$//' | LC_ALL=C sort -u
}

# How logical path $1 is assembled: append | replace | machine-only | base
layer_mode() {
  local rel="$1" has_base=false
  [ -f "$BASE_DIR/$rel" ] && has_base=true
  if [ -n "$MACHINE_DIR" ] && [ -f "$MACHINE_DIR/$rel.append" ]; then
    $has_base && echo append || echo machine-only
  elif [ -n "$MACHINE_DIR" ] && [ -f "$MACHINE_DIR/$rel" ]; then
    $has_base && echo replace || echo machine-only
  else
    echo base
  fi
}

# Write the assembled content of logical path $1 to file $2.
layer_build() {
  local rel="$1" out="$2"
  mkdir -p "$(dirname "$out")"
  case "$(layer_mode "$rel")" in
    append)  cat "$BASE_DIR/$rel" "$MACHINE_DIR/$rel.append" > "$out" ;;
    replace) cp "$MACHINE_DIR/$rel" "$out" ;;
    base)    cp "$BASE_DIR/$rel" "$out" ;;
    machine-only)
      if [ -f "$MACHINE_DIR/$rel" ]; then cp "$MACHINE_DIR/$rel" "$out"
      else cp "$MACHINE_DIR/$rel.append" "$out"; fi ;;
  esac
}

# Build the merged tree for managed path $1 into staging root $2.
# Non-zero if the path exists in neither layer.
layer_stage() {
  local rel="$1" stage="$2" f missing=1
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    layer_build "$f" "$stage/$f"
    missing=0
  done < <(layer_rels "$rel")
  return $missing
}

# Is file $1 a byte-prefix of file $2?
is_prefix() {
  local n
  n=$(wc -c < "$1")
  [ "$(wc -c < "$2")" -ge "$n" ] && head -c "$n" "$2" | cmp -s - "$1"
}

# List live files under managed path $1 (a file or dir) as logical paths.
live_rels() {
  local rel="$1" path="$HOME/$1"
  if [ -d "$path" ]; then (cd "$path" && find . -type f | sed "s|^\./|$rel/|")
  elif [ -f "$path" ]; then echo "$rel"; fi
}

FD_CACHE="$HOME/.cache/fd-repos"
# FD_PATH is machine-specific: set it in ~/.zshrc, which is sourced after this
# file (see files-<machine>/.zshrc.append). Only read inside fd-refresh, so
# assigning it later is fine. Fallback keeps a machine with no overlay sane.
: "${FD_PATH:=$HOME}"

fd-refresh() {
  mkdir -p "$HOME/.cache"

  find $FD_PATH \
    \( -type d \( -name node_modules -o -name dist -o -name build -o -name .next \) -prune \) -o \
    \( -type d -name .git -prune -print \) 2>/dev/null |
    sed 's|/\.git$||' |
    sort -u > "$FD_CACHE"

  cat "$FD_CACHE"
}


fd() {
  local selected 

  [[ -f "$FD_CACHE" ]] || fd-refresh

  if [[ -f "$FD_CACHE" ]] && [[ $(find "$FD_CACHE" -mtime +1) ]]; then
    fd-refresh &!
  fi

  selected=$(
      fzf --query="$*" \
          --select-1 \
	  --exit-0 \
      < "$FD_CACHE"
  ) 
  cd "$selected"
}

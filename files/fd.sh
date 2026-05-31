# fd - cd to selected directory



BASE_PATH=~/fxpro/

fd() {

  echo "$0"
  echo "$1"
  echo "$2"
  local selected 

  selected=$(
    find $BASE_PATH \
      \( -type d \( -name node_modules -o -name dist -o -name build -o -name .next \) -prune \) -o \
      \( -type d -name .git -prune -print \) 2>/dev/null |
      sed 's|/\.git$||' |
      fzf --prompt="$1" \
          --select-1 \
	  --exit-0
  ) 

  echo "$selected"
  cd "$selected"
}

fd

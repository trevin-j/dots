# hyprlog: display hyprland logs
# By default opens most recent (current) logs
# --last uses previous (equivalent to --delta 1)
# --delta N is used to open logs of N sessions ago
hyprlog() {
  local hypr_dir="$XDG_RUNTIME_DIR/hypr"
  local delta=0

  case "$1" in
    --last) delta=1 ;;
    --delta) delta="${2:-0}" ;;
    "") ;;
    *)
      print -u2 "usage: hyprlog [--last | --delta N]"
      return 1
      ;;
  esac

  [[ "$delta" =~ '^[0-9]+$' ]] || {
    print -u2 "hyprlog: delta must be >= 0"
    return 1
  }

  [[ -d "$hypr_dir" ]] || {
    print -u2 "hyprlog: not found: $hypr_dir"
    return 1
  }

  local session
  session="$(
    find "$hypr_dir" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' 2>/dev/null |
      sort -nr |
      awk -v n="$((delta + 1))" 'NR==n { print $2 }'
  )"

  [[ -n "$session" && -f "$session/hyprland.log" ]] || {
    print -u2 "hyprlog: no session found for delta=$delta"
    return 1
  }

  cat "$session/hyprland.log"
}

pacsearch() {
  local helper
  if command -v paru &>/dev/null; then
    helper=paru
  elif command -v yay &>/dev/null; then
    helper=yay
  else
    helper=pacman
  fi

  local tmp
  tmp=$(mktemp) || return
  "$helper" -Ss "$@" > "$tmp"

  local raw
  raw=$(
    gawk '
      BEGIN {
        cyan_b = "\033[1;96m"
        blue_b = "\033[1;94m"
        green_b = "\033[1;92m"
        white = "\033[37m"
        white_b = "\033[1;97m"
        reset = "\033[0m"
      }
      NR % 2 == 1 {
        pkg = $1
        ver = $2
        if (match($0, /\[[^\]]+\]/))
          size = substr($0, RSTART, RLENGTH)
        else
          size = ""
        getline
        desc = $0
        sub(/^  /, "", desc)

        if (match(pkg, /\//)) {
          repo = substr(pkg, 1, RSTART - 1)
          pkgname = substr(pkg, RSTART + 1)
          if (repo == "aur")
            colored = cyan_b repo reset white "/" white_b pkgname reset
          else if (repo == "extra")
            colored = blue_b repo reset white "/" white_b pkgname reset
          else if (repo == "multilib")
            colored = green_b repo reset white "/" white_b pkgname reset
          else
            colored = blue_b repo reset white "/" white_b pkgname reset
        } else {
          colored = blue_b pkg reset
        }

        print colored "\t" pkg "\t" ver "\t" size "\t" desc
      }
    ' "$tmp" \
      | fzf --ansi --with-nth=1 --delimiter=$'\t' --multi --prompt="pacsearch> " \
          --preview='echo {3} {4}; echo {5}' --preview-window='down:4:wrap'
  )
  local rc=$?
  rm -f "$tmp"
  (( rc )) && return

  [[ -z "$raw" ]] && return

  local pkgs
  pkgs=$(echo "$raw" | awk -F'\t' '{print $2}')
  [[ -z "$pkgs" ]] && return

  "$helper" -S "${(f)pkgs}"
}

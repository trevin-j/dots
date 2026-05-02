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

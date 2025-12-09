#!/bin/sh

# Unified wallcycle script
# Modes:
#   daemon             - run the background loop (default)
#   skip [--rm]        - pick a new wallpaper immediately (optionally delete current)

# ===== CONFIG =====
INTERVAL=300   # seconds between cycling
CACHE="$HOME/.cache/wallcycle_times"
LOGFILE="$HOME/.cache/wallcycle.log"

LAT="43.8231"
LON="-111.7924"

LIGHT_DIR="$HOME/Pictures/wallpapers/light"
DARK_DIR="$HOME/Pictures/wallpapers/dark"
mkdir -p "$LIGHT_DIR"
mkdir -p "$DARK_DIR"

# Options: scheme-content, scheme-expressive, scheme-fidelity, scheme-fruit-salad, scheme-monochrome, scheme-neutral, scheme-rainbow, scheme-tonal-spot, scheme-vibrant
#
# Grounded in the base colors, sorted from low vibrance to high:
# scheme-monochrome
# scheme-neutral
# scheme-tonal-spot
# scheme-content
# scheme-fidelity
#
# More playful options, don't stick so much to the image, sorted low to high in terms of how closely it resembles the image:
# scheme-vibrant
# scheme-expressive
# scheme-fruit-salad
# scheme-rainbow
SCHEME="scheme-fidelity"

# Current wallpaper file
CURRENT_FILE="$HOME/.cache/wallcycle_current"


# ===== LOGGING =====
log() {
    printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOGFILE"
}

log "===== wallcycle started ====="

# ===== FUNCTIONS =====

fetch_times() {
    log "Fetching sunrise/sunset times for today from API..."
    resp=$(curl -s "https://api.sunrise-sunset.org/json?lat=$LAT&lng=$LON&formatted=0")
    log "API raw response: $resp"

    sunrise=$(printf '%s\n' "$resp" | jq -r '.results.sunrise')
    sunset=$(printf '%s\n' "$resp" | jq -r '.results.sunset')

    log "Parsed sunrise: $sunrise"
    log "Parsed sunset:  $sunset"

    date=$(date +%Y-%m-%d)

    printf '%s\n%s\n%s\n' "$date" "$sunrise" "$sunset" > "$CACHE"
    log "Wrote new cache: date=$date sunrise=$sunrise sunset=$sunset"
}

load_times() {
    today=$(date +%Y-%m-%d)

    if [ -f "$CACHE" ]; then
        cached_date=$(sed -n '1p' "$CACHE")
        log "Cache exists: cached_date=$cached_date today=$today"

        if [ "$today" != "$cached_date" ]; then
            log "Cache is outdated. Fetching new times..."
            fetch_times
        else
            log "Cache is current. Using cached times."
        fi
    else
        log "Cache missing. Fetching times..."
        fetch_times
    fi

    SUNRISE=$(sed -n '2p' "$CACHE")
    SUNSET=$(sed -n '3p' "$CACHE")

    log "Loaded SUNRISE=$SUNRISE"
    log "Loaded SUNSET=$SUNSET"
}

show_help() {
    cat <<'EOF'
Usage: wallcycle.sh <command>

Commands:
  daemon                Run the background loop (checks and applies wallpapers)
  skip [--rm]           Pick and apply a new wallpaper immediately (use --rm to delete current)
  sort <dir>            Sort all files in <dir> into light/dark wallpaper folders
  help                  Show this help text (default when no args are given)

When run without arguments the script now shows this help message.
EOF
}

is_sun_up() {
    now=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
    log "Checking sun position: now=$now sunrise=$SUNRISE sunset=$SUNSET"

    if [ "$now" \> "$SUNRISE" ] && [ "$now" \< "$SUNSET" ]; then
        log "Sun is UP."
        return 0
    else
        log "Sun is DOWN."
        return 1
    fi
}

pick_random() {
    dir="$1"
    log "Picking random wallpaper from $dir"

    set -- "$dir"/*
    if [ "$1" = "$dir/*" ]; then
        log "ERROR: Directory empty: $dir"
        return 1
    fi

    c=0
    for f in "$dir"/*; do
        c=$((c+1))
    done
    log "Found $c wallpapers in $dir"

    # RANDOM isn't POSIX but most shells have it; fallback:
    if [ -z "$RANDOM" ]; then
        RANDOM=$(awk 'BEGIN{srand(); print int(rand()*32767)}')
    fi

    r=$(( (RANDOM % c) + 1 ))
    log "Random index chosen: $r"

    i=1
    for f in "$dir"/*; do
        if [ "$i" -eq "$r" ]; then
            log "Selected wallpaper: $f"
            printf '%s\n' "$f"
            return 0
        fi
        i=$((i+1))
    done
}

# Detects light/dark using ImageMagick (mean luminance)
detect_brightness() {
    img="$1"
    if command -v magick >/dev/null 2>&1; then
        brightness=$(magick "$img" -format "%[fx:mean*255]" info:)
        printf '%s\n' "$brightness"
    else
        # fallback: assume dark
        printf '0\n'
    fi
}

# Classify (move to correct wallpapers folder)
sort_wallpaper() {
    img="$1"

    brightness=$(detect_brightness "$img")
    val=$(printf "%.0f" "$brightness")

    if [ "$val" -gt 128 ]; then
        # light
        mv "$img" "$LIGHT_DIR"/
        printf '%s/%s\n' "$LIGHT_DIR" "$(basename "$img")"
    else
        # dark
        mv "$img" "$DARK_DIR"/
        printf '%s/%s\n' "$DARK_DIR" "$(basename "$img")"
    fi
}

# ===== SUBCOMMANDS =====

cmd="$1"

case "$cmd" in
    "skip")
        # skip [--rm]
        DO_RM=0
        if [ "$2" = "--rm" ] || [ "$2" = "rm" ]; then
            DO_RM=1
        fi

        if [ ! -f "$CURRENT_FILE" ]; then
            log "No current wallpaper recorded."
            echo "No current wallpaper recorded." >&2
            exit 1
        fi

        CUR=$(cat "$CURRENT_FILE")
        if [ "$DO_RM" -eq 1 ]; then
            if [ -f "$CUR" ]; then
                log "Deleting current wallpaper: $CUR"
                rm "$CUR"
            else
                log "Current wallpaper doesn't exist on disk, skipping delete."
            fi
        else
            log "Skipping delete (run with 'skip --rm' to remove the current wallpaper)."
        fi

        if [ ! -f "$CACHE" ]; then
            log "Missing times file. Run main daemon first."
            echo "Missing times file. Run daemon first." >&2
            exit 1
        fi

        SUNRISE=$(sed -n '2p' "$CACHE")
        SUNSET=$(sed -n '3p' "$CACHE")
        NOW=$(date -u +"%Y-%m-%dT%H:%M:%S%z")

        if [ "$NOW" \> "$SUNRISE" ] && [ "$NOW" \< "$SUNSET" ]; then
            mode="light"
            dir="$LIGHT_DIR"
        else
            mode="dark"
            dir="$DARK_DIR"
        fi

        log "Daylight mode is $mode — picking new wallpaper..."

        NEW=$(pick_random "$dir")
        if [ -z "$NEW" ]; then
            log "No wallpapers available in $dir"
            echo "No wallpapers available in $dir" >&2
            exit 1
        fi

        log "Applying: $NEW"
        # Capture matugen stdout/stderr and log each line with timestamp
        matugen_output=$(matugen image -t "$SCHEME" -m "$mode" "$NEW" 2>&1)
        matugen_rc=$?
        if [ -n "$matugen_output" ]; then
            printf '%s\n' "$matugen_output" | while IFS= read -r _line; do
                log "matugen: $_line"
            done
        fi
        log "matugen exit code: $matugen_rc"

        echo "$NEW" > "$CURRENT_FILE"
        log "Saved new current wallpaper."
        exit 0
        ;;

    "sort")
        # sort <dir>  -- move files from <dir> into light/dark folders
        if [ -z "$2" ]; then
            echo "Usage: $0 sort <dir>" >&2
            exit 2
        fi
        SRC_DIR=$2
        if [ ! -d "$SRC_DIR" ]; then
            echo "Not a directory: $SRC_DIR" >&2
            exit 1
        fi

        log "Sorting images from directory: $SRC_DIR"
        for f in "$SRC_DIR"/*; do
            [ -f "$f" ] || continue
            log "Processing file: $f"
            sorted=$(sort_wallpaper "$f")
            log "Sorted to: $sorted"
        done
        log "Finished sorting directory: $SRC_DIR"
        exit 0
        ;;

    "daemon" )
        # run the main loop
        ;;

    "help"|"" )
        show_help
        exit 0
        ;;

    *)
        echo "Usage: $0 [daemon|skip [--rm]|sort <dir>|help]" >&2
        exit 2
        ;;
esac


# ===== MAIN LOOP =====

log "Entering main loop. Interval: $INTERVAL seconds."

while :; do
    log "--- Loop iteration start ---"

    load_times

    if is_sun_up; then
        mode="light"
        img=$(pick_random "$LIGHT_DIR")
    else
        mode="dark"
        img=$(pick_random "$DARK_DIR")
    fi

    if [ -n "$img" ]; then
        log "Running: matugen image -t $SCHEME -m $mode $img"
        # Capture matugen stdout/stderr and log each line with timestamp
        matugen_output=$(matugen image -t "$SCHEME" -m "$mode" "$img" 2>&1)
        matugen_rc=$?
        if [ -n "$matugen_output" ]; then
            printf '%s\n' "$matugen_output" | while IFS= read -r _line; do
                log "matugen: $_line"
            done
        fi
        log "matugen exit code: $matugen_rc"
        log "Wallpaper applied."
        echo "$img" > "$CURRENT_FILE"
        log "Saved current wallpaper: $img"

    else
        log "ERROR: No wallpaper found for mode '$mode'"
    fi

    log "Sleeping for $INTERVAL seconds..."
    sleep "$INTERVAL"

    log "--- Loop iteration end ---"
done

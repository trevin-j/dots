#!/usr/bin/env python3
import json
import glob
import os
import sys

# OSC codes:
# 4  = palette entries 0–255
# 10 = foreground
# 11 = background
# 12 = cursor
OSC = "\033]{};{}\007"

def send(fd, msg):
    try:
        fd.write(msg)
        fd.flush()
    except Exception:
        pass  # terminal closed, permissions mismatch, etc.


def main():
    if len(sys.argv) != 2:
        print("Usage: push_colors.py <theme.json>")
        sys.exit(1)

    with open(sys.argv[1]) as f:
        theme = json.load(f)

    fg = theme["foreground"]
    bg = theme["background"]
    cursor = theme["cursor"]

    colors = theme["colors"]

    # map names to index numbers
    index_map = {
        "black": 0, "red": 1, "green": 2, "yellow": 3,
        "blue": 4, "magenta": 5, "cyan": 6, "white": 7,
        "bright_black": 8, "bright_red": 9, "bright_green": 10,
        "bright_yellow": 11, "bright_blue": 12, "bright_magenta": 13,
        "bright_cyan": 14, "bright_white": 15,
    }

    pts_list = glob.glob("/dev/pts/[0-9]*")

    for pts in pts_list:
        try:
            with open(pts, "w") as fd:
                # Update palette colors
                for name, idx in index_map.items():
                    c = colors[name]
                    send(fd, OSC.format(f"4;{idx}", c))

                # Update FG, BG, cursor
                send(fd, OSC.format("10", fg))
                send(fd, OSC.format("11", bg))
                send(fd, OSC.format("12", cursor))

        except PermissionError:
            # Can't write to someone else's PTY (good)
            pass
        except Exception:
            pass


if __name__ == "__main__":
    main()


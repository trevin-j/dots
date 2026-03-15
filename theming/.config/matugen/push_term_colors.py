#!/usr/bin/env python3
import configparser
import glob
import sys
from pathlib import Path

# OSC codes:
# 4  = palette entries 0-255
# 10 = foreground
# 11 = background
# 12 = cursor
OSC = "\033]{};{}\007"
DEFAULT_CONFIG = Path("~/.config/foot/colors.ini").expanduser()


def send(fd, msg):
    try:
        fd.write(msg)
        fd.flush()
    except Exception:
        pass


def normalize_color(value):
    value = value.strip()
    return value if value.startswith("#") else f"#{value}"


def load_active_theme(config_path):
    parser = configparser.ConfigParser(interpolation=None)
    if not parser.read(config_path):
        raise FileNotFoundError(f"Could not read Foot colors file: {config_path}")

    mode = parser["main"]["initial-color-theme"].strip().lower()
    if mode not in {"dark", "light"}:
        raise ValueError(f"Unsupported Foot color theme: {mode}")

    section = parser[f"colors-{mode}"]
    cursor_parts = section["cursor"].split()
    if len(cursor_parts) != 2:
        raise ValueError(
            f"Expected Foot cursor to have two colors, got: {section['cursor']}"
        )

    palette = [normalize_color(section[f"regular{i}"]) for i in range(8)]
    palette.extend(normalize_color(section[f"bright{i}"]) for i in range(8))

    return {
        "foreground": normalize_color(section["foreground"]),
        "background": normalize_color(section["background"]),
        "cursor": normalize_color(cursor_parts[1]),
        "palette": palette,
    }


def push_to_ptys(theme):
    for pts in glob.glob("/dev/pts/[0-9]*"):
        try:
            with open(pts, "w", encoding="utf-8") as fd:
                for idx, color in enumerate(theme["palette"]):
                    send(fd, OSC.format(f"4;{idx}", color))

                send(fd, OSC.format("10", theme["foreground"]))
                send(fd, OSC.format("11", theme["background"]))
                send(fd, OSC.format("12", theme["cursor"]))
        except PermissionError:
            pass
        except Exception:
            pass


def main():
    if len(sys.argv) > 2:
        print("Usage: push_term_colors.py [foot-colors.ini]", file=sys.stderr)
        sys.exit(1)

    config_path = (
        Path(sys.argv[1]).expanduser() if len(sys.argv) == 2 else DEFAULT_CONFIG
    )
    theme = load_active_theme(config_path)
    push_to_ptys(theme)


if __name__ == "__main__":
    main()

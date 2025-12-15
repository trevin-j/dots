#!/usr/bin/env python3
import sys
import json
from rich.console import Console
from rich.table import Table
from coloraide import Color

console = Console()

BASE_COLORS = {
    "black":  "#1d1d1d",
    "red":    "#cc5750",
    "green":  "#65a761",
    "yellow": "#d9b76e",
    "blue":   "#6598cc",
    "magenta":"#b276cc",
    "cyan":   "#63b8c3",
    "white":  "#d0d0d0",

    "bright_black":  "#3a3a3a",
    "bright_red":    "#e98a84",
    "bright_green":  "#86c985",
    "bright_yellow": "#eccb93",
    "bright_blue":   "#8ab3e0",
    "bright_magenta":"#cf9ceb",
    "bright_cyan":   "#87d2d8",
    "bright_white":  "#f5f5f5",
}

PAIRS = [
    ("black", "bright_black"),
    ("red", "bright_red"),
    ("green", "bright_green"),
    ("yellow", "bright_yellow"),
    ("blue", "bright_blue"),
    ("magenta", "bright_magenta"),
    ("cyan", "bright_cyan"),
    ("white", "bright_white"),
]

def lerp_color(base_hex, primary_hex, amount=0.12):
    c1 = Color(base_hex).convert("oklch")
    c2 = Color(primary_hex).convert("oklch")

    new = Color(
        "oklch",
        [
            c1["l"] + (c2["l"] - c1["l"]) * amount,
            c1["c"] + (c2["c"] - c1["c"]) * amount,
            c1["h"] + (c2["h"] - c1["h"]) * amount,
        ]
    )
    return new.convert("srgb").to_string(hex=True)


def main():
    args = sys.argv[1:]

    quiet = "-q" in args
    args = [a for a in args if a != "-q"]

    if len(args) != 3:
        print("Usage: tintterm.py [-q] <primary_hex> <surface_hex> <on_surface_hex>")
        sys.exit(1)

    primary, bg, fg = args
    cursor = fg

    # Tint palette
    tinted = {name: lerp_color(hexv, primary) for name, hexv in BASE_COLORS.items()}

    # Quiet JSON mode
    if quiet:
        data = {
            "foreground": fg,
            "background": bg,
            "cursor": cursor,
            "colors": tinted
        }
        print(json.dumps(data, indent=2))
        return

    # Normal full preview
    console.print(f"\n[bold underline]Terminal Theme Preview[/bold underline]\n")

    console.print(f"[{fg} on {bg}] Foreground: {fg} [/]")
    console.print(f"[{fg} on {bg}] Background: {bg} [/]")
    console.print(f"[{fg} on {bg}] Cursor:     {cursor} [/]\n")

    table = Table(show_header=True, header_style="bold", style=f"on {bg}", row_styles=[f"on {bg}"])
    table.add_column("Regular", justify="center")
    table.add_column("Bright", justify="center")

    for base_name, bright_name in PAIRS:
        base_hex = tinted[base_name]
        bright_hex = tinted[bright_name]

        reg = (
            f"[{base_hex} on {bg}] {base_name:<12} [/]\n"
            f"[{fg} on {base_hex}] {base_hex} [/]"
        )

        br = (
            f"[{bright_hex} on {bg}] {bright_name:<12} [/]\n"
            f"[{fg} on {bright_hex}] {bright_hex} [/]"
        )

        table.add_row(reg, br)

    console.print(table)
    console.print()


if __name__ == "__main__":
    main()

